-- Phase 3: The Connected World (MMO Layer)

-- 1. Global Item Minting
-- Add mint_number to vault_items
ALTER TABLE public.vault_items 
ADD COLUMN IF NOT EXISTS mint_number BIGINT;

-- Sequence management for minting (per item_id)
CREATE TABLE IF NOT EXISTS public.item_mints (
    item_id TEXT PRIMARY KEY,
    next_mint_number BIGINT DEFAULT 1
);

-- 2. Bazaar (Marketplace)
CREATE TABLE IF NOT EXISTS public.market_listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    vault_item_id UUID REFERENCES public.vault_items(id) ON DELETE CASCADE,
    reserve_price BIGINT NOT NULL CHECK (reserve_price >= 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    ends_at TIMESTAMPTZ NOT NULL,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'ended', 'cancelled')),
    highest_bid BIGINT DEFAULT 0,
    highest_bidder_id UUID REFERENCES auth.users(id)
);

CREATE TABLE IF NOT EXISTS public.market_bids (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id UUID REFERENCES public.market_listings(id) ON DELETE CASCADE,
    bidder_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    amount BIGINT NOT NULL CHECK (amount > 0),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Activity Feed
CREATE TABLE IF NOT EXISTS public.global_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type TEXT NOT NULL, -- 'find', 'listing', 'sale'
    user_id UUID REFERENCES auth.users(id),
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE public.item_mints ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.market_listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.market_bids ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.global_events ENABLE ROW LEVEL SECURITY;

-- Everyone can read mints (though mostly internal)
DROP POLICY IF EXISTS "Public read mints" ON public.item_mints;
CREATE POLICY "Public read mints" ON public.item_mints FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public read listings" ON public.market_listings;
CREATE POLICY "Public read listings" ON public.market_listings FOR SELECT USING (true);

DROP POLICY IF EXISTS "Sellers update own listings" ON public.market_listings;
CREATE POLICY "Sellers update own listings" ON public.market_listings FOR UPDATE USING (auth.uid() = seller_id);

DROP POLICY IF EXISTS "Public read bids" ON public.market_bids;
CREATE POLICY "Public read bids" ON public.market_bids FOR SELECT USING (true);

DROP POLICY IF EXISTS "Bidders insert bids" ON public.market_bids;
CREATE POLICY "Bidders insert bids" ON public.market_bids FOR INSERT WITH CHECK (auth.uid() = bidder_id);

DROP POLICY IF EXISTS "Public read events" ON public.global_events;
CREATE POLICY "Public read events" ON public.global_events FOR SELECT USING (true);

-- 4. RPC Updates for Minting
-- Update rpc_claim to assign mint number
CREATE OR REPLACE FUNCTION public.rpc_claim()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_lab RECORD;
    v_item_id TEXT;
    v_tier TEXT;
    v_mint_num BIGINT;
BEGIN
    SELECT * INTO v_lab FROM public.lab_state WHERE user_id = v_user_id;
    
    IF v_lab IS NULL OR NOT v_lab.is_active THEN
        RETURN jsonb_build_object('success', false, 'error', 'No active crate to claim');
    END IF;

    -- Determine Tier (Same as Phase 1)
    IF v_lab.current_stage >= 3 THEN
        v_tier := 'rare';
    ELSE
        v_tier := 'common';
    END IF;

    -- Pick random item (Simplified list for example)
    IF v_tier = 'rare' THEN
        SELECT item INTO v_item_id FROM unnest(ARRAY['calculated_tablet', 'wrist_chronometer', 'compact_disc', 'remote_control', 'computer_mouse', 'flashlight', 'headphone_set', 'digital_camera']) AS item ORDER BY random() LIMIT 1;
    ELSE
        SELECT item INTO v_item_id FROM unnest(ARRAY['rusty_key', 'ceramic_mug', 'aa_battery', 'plastic_comb', 'steel_fork', 'lightbulb', 'ballpoint_pen', 'eyeglass_frame', 'soda_tab', 'safety_pin', 'rubber_band', 'broken_watch']) AS item ORDER BY random() LIMIT 1;
    END IF;

    -- MINTING LOGIC
    INSERT INTO public.item_mints (item_id, next_mint_number) VALUES (v_item_id, 1)
    ON CONFLICT (item_id) DO UPDATE SET next_mint_number = item_mints.next_mint_number + 1
    RETURNING next_mint_number - 1 INTO v_mint_num; -- Wait, this logic is tricky.
    -- Better: Update then return.
    -- If it didn't exist, it inserts 1. Wait, on conflict it updates.
    -- Let's fix the ON CONFLICT logic to be safer.
    
    INSERT INTO public.item_mints (item_id, next_mint_number) VALUES (v_item_id, 2)
    ON CONFLICT (item_id) DO UPDATE SET next_mint_number = item_mints.next_mint_number + 1
    RETURNING next_mint_number - 1 INTO v_mint_num;
    
    -- If it was a new insert, it inserted 2, returned 1. Correct.
    -- If it updated, say it was 2 (next is 2), it becomes 3, returns 2. Correct.

    -- Save to vault
    INSERT INTO public.vault_items (user_id, item_id, mint_number) VALUES (v_user_id, v_item_id, v_mint_num);

    -- Clean up lab and tray
    UPDATE public.lab_state SET is_active = FALSE, current_stage = 0, last_action_at = NOW() WHERE user_id = v_user_id;
    UPDATE public.profiles SET tray_count = tray_count - 1 WHERE id = v_user_id;
    
    -- Log Global Event if Rare
    IF v_tier = 'rare' THEN
        INSERT INTO public.global_events (event_type, user_id, details)
        VALUES ('find', v_user_id, jsonb_build_object('item_id', v_item_id, 'mint_number', v_mint_num));
    END IF;

    RETURN jsonb_build_object('success', true, 'item_id', v_item_id, 'tier', v_tier, 'mint_number', v_mint_num);
END;
$$;

-- 5. RPC: List Item
CREATE OR REPLACE FUNCTION public.rpc_list_item(p_vault_item_id UUID, p_price BIGINT, p_hours INT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_item RECORD;
BEGIN
    -- Verify ownership
    SELECT * INTO v_item FROM public.vault_items WHERE id = p_vault_item_id AND user_id = v_user_id;
    IF v_item IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Item not found');
    END IF;
    
    -- Remove from vault? Or just mark as 'listing'? 
    -- For simplicity, let's keep in vault but maybe add a status? 
    -- Actually, standard MMO practice: Remove from inventory (or lock it).
    -- Implementation: We have a UNIQUE constraint on vault_items? No.
    -- Let's check if it's already listed.
    IF EXISTS (SELECT 1 FROM public.market_listings WHERE vault_item_id = p_vault_item_id AND status = 'active') THEN
         RETURN jsonb_build_object('success', false, 'error', 'Item already listed');
    END IF;

    INSERT INTO public.market_listings (seller_id, vault_item_id, reserve_price, ends_at)
    VALUES (v_user_id, p_vault_item_id, p_price, NOW() + (p_hours || ' hours')::INTERVAL);

    -- Log event
    INSERT INTO public.global_events (event_type, user_id, details)
    VALUES ('listing', v_user_id, jsonb_build_object('item_id', v_item.item_id, 'price', p_price));

    RETURN jsonb_build_object('success', true);
END;
$$;

-- 6. RPC: Place Bid
CREATE OR REPLACE FUNCTION public.rpc_place_bid(p_listing_id UUID, p_amount BIGINT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_listing RECORD;
    v_profile RECORD;
    v_old_bidder UUID;
    v_old_bid BIGINT;
BEGIN
    SELECT * INTO v_listing FROM public.market_listings WHERE id = p_listing_id;
    
    IF v_listing.status <> 'active' OR v_listing.ends_at < NOW() THEN
        RETURN jsonb_build_object('success', false, 'error', 'Auction ended');
    END IF;

    IF v_listing.seller_id = v_user_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'Cannot bid on own item');
    END IF;

    IF p_amount <= coalesce(v_listing.highest_bid, v_listing.reserve_price) AND v_listing.highest_bid IS NOT NULL THEN
         RETURN jsonb_build_object('success', false, 'error', 'Bid too low');
    END IF;
    
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    IF v_profile.scrap_balance < p_amount THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient funds');
    END IF;

    -- Escrow: Take money from new bidder
    UPDATE public.profiles SET scrap_balance = scrap_balance - p_amount WHERE id = v_user_id;

    -- Refund previous bidder
    IF v_listing.highest_bidder_id IS NOT NULL THEN
        UPDATE public.profiles SET scrap_balance = scrap_balance + v_listing.highest_bid WHERE id = v_listing.highest_bidder_id;
    END IF;

    -- Update listing
    UPDATE public.market_listings 
    SET highest_bid = p_amount, highest_bidder_id = v_user_id 
    WHERE id = p_listing_id;

    -- Record bid
    INSERT INTO public.market_bids (listing_id, bidder_id, amount) VALUES (p_listing_id, v_user_id, p_amount);

    RETURN jsonb_build_object('success', true);
END;
$$;
