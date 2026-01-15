-- Phase 3 Completion: Realtime, Notifications, and Settlement

-- 1. Notifications Table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    type TEXT NOT NULL, -- 'info', 'success', 'warning', 'error'
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);

-- 2. Realtime Enabling
ALTER PUBLICATION supabase_realtime ADD TABLE public.global_events;
ALTER PUBLICATION supabase_realtime ADD TABLE public.market_listings;
ALTER PUBLICATION supabase_realtime ADD TABLE public.market_bids;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;

-- 3. Deposit for Listings
ALTER TABLE public.market_listings ADD COLUMN IF NOT EXISTS deposit_amount BIGINT DEFAULT 0;

-- 4. Updated rpc_list_item (With Deposit)
CREATE OR REPLACE FUNCTION public.rpc_list_item(p_vault_item_id UUID, p_price BIGINT, p_hours INT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_item RECORD;
    v_profile RECORD;
    v_deposit BIGINT := 50; -- Fixed deposit amount
BEGIN
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    IF v_profile.scrap_balance < v_deposit THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient scrap for deposit');
    END IF;

    SELECT * INTO v_item FROM public.vault_items WHERE id = p_vault_item_id AND user_id = v_user_id;
    IF v_item IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Item not found');
    END IF;
    
    IF EXISTS (SELECT 1 FROM public.market_listings WHERE vault_item_id = p_vault_item_id AND status = 'active') THEN
         RETURN jsonb_build_object('success', false, 'error', 'Item already listed');
    END IF;

    -- Deduct deposit
    UPDATE public.profiles SET scrap_balance = scrap_balance - v_deposit WHERE id = v_user_id;

    INSERT INTO public.market_listings (seller_id, vault_item_id, reserve_price, ends_at, deposit_amount)
    VALUES (v_user_id, p_vault_item_id, p_price, NOW() + (p_hours || ' hours')::INTERVAL, v_deposit);

    INSERT INTO public.global_events (event_type, user_id, details)
    VALUES ('listing', v_user_id, jsonb_build_object('item_id', v_item.item_id, 'price', p_price));

    RETURN jsonb_build_object('success', true);
END;
$$;

-- 5. Updated rpc_place_bid (With Notification)
CREATE OR REPLACE FUNCTION public.rpc_place_bid(p_listing_id UUID, p_amount BIGINT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_listing RECORD;
    v_profile RECORD;
    v_item_name TEXT;
BEGIN
    SELECT m.*, v.item_id as item_name INTO v_listing 
    FROM public.market_listings m
    JOIN public.vault_items v ON m.vault_item_id = v.id
    WHERE m.id = p_listing_id;
    
    IF v_listing.status <> 'active' OR v_listing.ends_at < NOW() THEN
        RETURN jsonb_build_object('success', false, 'error', 'Auction ended');
    END IF;

    IF v_listing.seller_id = v_user_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'Cannot bid on own item');
    END IF;

    IF p_amount <= coalesce(v_listing.highest_bid, v_listing.reserve_price) THEN
         RETURN jsonb_build_object('success', false, 'error', 'Bid too low');
    END IF;
    
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    IF v_profile.scrap_balance < p_amount THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient funds');
    END IF;

    -- Take money
    UPDATE public.profiles SET scrap_balance = scrap_balance - p_amount WHERE id = v_user_id;

    -- Refund previous bidder & Notify
    IF v_listing.highest_bidder_id IS NOT NULL THEN
        UPDATE public.profiles SET scrap_balance = scrap_balance + v_listing.highest_bid WHERE id = v_listing.highest_bidder_id;
        
        INSERT INTO public.notifications (user_id, message, type)
        VALUES (v_listing.highest_bidder_id, 'You have been outbid on ' || v_listing.item_name || '!', 'warning');
    END IF;

    UPDATE public.market_listings 
    SET highest_bid = p_amount, highest_bidder_id = v_user_id 
    WHERE id = p_listing_id;

    INSERT INTO public.market_bids (listing_id, bidder_id, amount) VALUES (p_listing_id, v_user_id, p_amount);

    RETURN jsonb_build_object('success', true);
END;
$$;

-- 6. RPC: Settle Listing
CREATE OR REPLACE FUNCTION public.rpc_settle_listing(p_listing_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_listing RECORD;
    v_seller_payout BIGINT;
    v_tax BIGINT;
    v_item_name TEXT;
BEGIN
    SELECT m.*, v.item_id as item_name INTO v_listing 
    FROM public.market_listings m
    JOIN public.vault_items v ON m.vault_item_id = v.id
    WHERE m.id = p_listing_id;

    IF v_listing.status <> 'active' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Listing not active');
    END IF;

    IF v_listing.ends_at > NOW() THEN
         RETURN jsonb_build_object('success', false, 'error', 'Auction not yet ended');
    END IF;

    -- Mark as ended immediately to prevent re-entrancy
    UPDATE public.market_listings SET status = 'ended' WHERE id = p_listing_id;

    IF v_listing.highest_bidder_id IS NOT NULL THEN
        -- Sold!
        -- Transfer Item
        UPDATE public.vault_items SET user_id = v_listing.highest_bidder_id WHERE id = v_listing.vault_item_id;
        
        -- Calculate Payout (Bid - 5% + Deposit)
        v_tax := floor(v_listing.highest_bid * 0.05);
        v_seller_payout := (v_listing.highest_bid - v_tax) + v_listing.deposit_amount;
        
        -- Pay Seller
        UPDATE public.profiles SET scrap_balance = scrap_balance + v_seller_payout WHERE id = v_listing.seller_id;
        
        -- Notifications
        INSERT INTO public.notifications (user_id, message, type)
        VALUES (v_listing.seller_id, 'Your ' || v_listing.item_name || ' sold for ' || v_listing.highest_bid || ' scrap!', 'success');
        
        INSERT INTO public.notifications (user_id, message, type)
        VALUES (v_listing.highest_bidder_id, 'You won the auction for ' || v_listing.item_name || '!', 'success');
        
        -- Global Event
        INSERT INTO public.global_events (event_type, user_id, details)
        VALUES ('sale', v_listing.seller_id, jsonb_build_object('item_id', v_listing.item_name, 'price', v_listing.highest_bid));
        
        RETURN jsonb_build_object('success', true, 'outcome', 'sold');
    ELSE
        -- No bids, refund deposit
        UPDATE public.profiles SET scrap_balance = scrap_balance + v_listing.deposit_amount WHERE id = v_listing.seller_id;
        
        INSERT INTO public.notifications (user_id, message, type)
        VALUES (v_listing.seller_id, 'Your auction for ' || v_listing.item_name || ' expired with no bids.', 'info');
        
        RETURN jsonb_build_object('success', true, 'outcome', 'expired');
    END IF;
END;
$;

-- 8. Enable public access to listed items (so buyers can see details)
CREATE POLICY "Public read listed items" ON public.vault_items FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.market_listings WHERE vault_item_id = vault_items.id AND status = 'active')
);


-- 7. Update rpc_sift to log event
CREATE OR REPLACE FUNCTION public.rpc_sift()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_lab RECORD;
    v_stability FLOAT;
    v_roll FLOAT;
    v_success BOOLEAN;
    v_xp_gain INT := 0;
BEGIN
    SELECT * INTO v_lab FROM public.lab_state WHERE user_id = v_user_id;
    
    IF v_lab IS NULL OR NOT v_lab.is_active THEN
        RETURN jsonb_build_object('success', false, 'error', 'No active crate in lab');
    END IF;

    CASE v_lab.current_stage
        WHEN 0 THEN v_stability := 0.90;
        WHEN 1 THEN v_stability := 0.75;
        WHEN 2 THEN v_stability := 0.50;
        WHEN 3 THEN v_stability := 0.25;
        WHEN 4 THEN v_stability := 0.10;
        ELSE v_stability := 0;
    END CASE;

    v_roll := random();
    v_success := v_roll < v_stability;

    IF v_success THEN
        v_xp_gain := (v_lab.current_stage + 1) * 10;
        UPDATE public.lab_state SET current_stage = current_stage + 1, last_action_at = NOW() WHERE user_id = v_user_id;
        UPDATE public.profiles SET restoration_xp = restoration_xp + v_xp_gain WHERE id = v_user_id;
        
        -- Log Global Event for High Stakes (Stage 3+)
        IF v_lab.current_stage >= 3 THEN
             INSERT INTO public.global_events (event_type, user_id, details)
             VALUES ('gamble', v_user_id, jsonb_build_object('stage', v_lab.current_stage + 1));
        END IF;

        RETURN jsonb_build_object('success', true, 'outcome', 'SUCCESS', 'new_stage', v_lab.current_stage + 1, 'xp_gain', v_xp_gain);
    ELSE
        UPDATE public.lab_state SET is_active = FALSE, current_stage = 0, last_action_at = NOW() WHERE user_id = v_user_id;
        UPDATE public.profiles SET tray_count = tray_count - 1 WHERE id = v_user_id;
        RETURN jsonb_build_object('success', true, 'outcome', 'SHATTERED');
    END IF;
END;
$$;
