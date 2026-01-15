-- COMBINED MIGRATIONS FOR STURDY POTATO
-- Run this in the Supabase SQL Editor to verify the backend schema.

-- ==========================================
-- PHASE 1: The Clicker Foundation
-- ==========================================

-- 1. Profiles (Player State)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    scrap_balance BIGINT DEFAULT 0 CHECK (scrap_balance >= 0),
    tray_count INT DEFAULT 0 CHECK (tray_count >= 0 AND tray_count <= 5),
    last_extract_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Vault Items (Collection)
CREATE TABLE IF NOT EXISTS public.vault_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    item_id TEXT NOT NULL,
    discovered_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Lab State (Current Crate)
CREATE TABLE IF NOT EXISTS public.lab_state (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    current_stage INT DEFAULT 0, -- 0 to 5
    is_active BOOLEAN DEFAULT FALSE,
    last_action_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vault_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lab_state ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
    CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
    
    DROP POLICY IF EXISTS "Users can view own vault" ON public.vault_items;
    CREATE POLICY "Users can view own vault" ON public.vault_items FOR SELECT USING (auth.uid() = user_id);
    
    DROP POLICY IF EXISTS "Users can view own lab state" ON public.lab_state;
    CREATE POLICY "Users can view own lab state" ON public.lab_state FOR SELECT USING (auth.uid() = user_id);
EXCEPTION
    WHEN undefined_object THEN null;
END $$;

-- RPC: handle_extraction
CREATE OR REPLACE FUNCTION public.rpc_extract()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_profile RECORD;
    v_roll FLOAT;
    v_result TEXT;
    v_scrap_gain INT := 0;
    v_crate_dropped BOOLEAN := FALSE;
    v_cooldown_sec INT := 3;
BEGIN
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    
    -- Check cooldown
    IF v_profile.last_extract_at > NOW() - (v_cooldown_sec || ' seconds')::INTERVAL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Cooldown active');
    END IF;

    v_roll := random();
    
    IF v_roll < 0.2 AND v_profile.tray_count < 5 THEN
        -- Crate Drop (20%)
        v_crate_dropped := TRUE;
        v_result := 'CRATE_FOUND';
    ELSIF v_roll < 0.9 THEN
        -- Scrap (70%)
        v_scrap_gain := floor(random() * (15 - 5 + 1) + 5)::INT;
        v_result := 'SCRAP_FOUND';
    ELSE
        -- Nothing (10%)
        v_result := 'NOTHING_FOUND';
    END IF;

    UPDATE public.profiles
    SET 
        scrap_balance = scrap_balance + v_scrap_gain,
        tray_count = CASE WHEN v_crate_dropped THEN tray_count + 1 ELSE tray_count END,
        last_extract_at = NOW(),
        updated_at = NOW()
    WHERE id = v_user_id;

    RETURN jsonb_build_object(
        'success', true, 
        'result', v_result, 
        'scrap_gain', v_scrap_gain, 
        'crate_dropped', v_crate_dropped,
        'new_balance', v_profile.scrap_balance + v_scrap_gain,
        'new_tray_count', CASE WHEN v_crate_dropped THEN v_profile.tray_count + 1 ELSE v_profile.tray_count END
    );
END;
$$;

-- RPC: rpc_sift
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
BEGIN
    SELECT * INTO v_lab FROM public.lab_state WHERE user_id = v_user_id;
    
    IF v_lab IS NULL OR NOT v_lab.is_active THEN
        RETURN jsonb_build_object('success', false, 'error', 'No active crate in lab');
    END IF;

    -- Stability based on stage
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
        UPDATE public.lab_state SET current_stage = current_stage + 1, last_action_at = NOW() WHERE user_id = v_user_id;
        RETURN jsonb_build_object('success', true, 'outcome', 'SUCCESS', 'new_stage', v_lab.current_stage + 1);
    ELSE
        UPDATE public.lab_state SET is_active = FALSE, current_stage = 0, last_action_at = NOW() WHERE user_id = v_user_id;
        UPDATE public.profiles SET tray_count = tray_count - 1 WHERE id = v_user_id;
        RETURN jsonb_build_object('success', true, 'outcome', 'SHATTERED');
    END IF;
END;
$$;

-- RPC: rpc_claim
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
BEGIN
    SELECT * INTO v_lab FROM public.lab_state WHERE user_id = v_user_id;
    
    IF v_lab IS NULL OR NOT v_lab.is_active THEN
        RETURN jsonb_build_object('success', false, 'error', 'No active crate to claim');
    END IF;

    -- Determine Tier
    IF v_lab.current_stage >= 3 THEN
        v_tier := 'rare';
    ELSE
        v_tier := 'common';
    END IF;

    -- Pick random item (MVP shortcut)
    IF v_tier = 'rare' THEN
        SELECT item INTO v_item_id FROM unnest(ARRAY['calculated_tablet', 'wrist_chronometer', 'compact_disc', 'remote_control', 'computer_mouse', 'flashlight', 'headphone_set', 'digital_camera']) AS item ORDER BY random() LIMIT 1;
    ELSE
        SELECT item INTO v_item_id FROM unnest(ARRAY['rusty_key', 'ceramic_mug', 'aa_battery', 'plastic_comb', 'steel_fork', 'lightbulb', 'ballpoint_pen', 'eyeglass_frame', 'soda_tab', 'safety_pin', 'rubber_band', 'broken_watch']) AS item ORDER BY random() LIMIT 1;
    END IF;

    -- Save to vault
    INSERT INTO public.vault_items (user_id, item_id) VALUES (v_user_id, v_item_id);

    -- Clean up lab and tray
    UPDATE public.lab_state SET is_active = FALSE, current_stage = 0, last_action_at = NOW() WHERE user_id = v_user_id;
    UPDATE public.profiles SET tray_count = tray_count - 1 WHERE id = v_user_id;

    RETURN jsonb_build_object('success', true, 'item_id', v_item_id, 'tier', v_tier);
END;
$$;

-- ==========================================
-- PHASE 2: The Amateur Archaeologist Progression
-- ==========================================

-- 1. Extend Profiles
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS excavation_xp BIGINT DEFAULT 0 CHECK (excavation_xp >= 0),
ADD COLUMN IF NOT EXISTS restoration_xp BIGINT DEFAULT 0 CHECK (restoration_xp >= 0),
ADD COLUMN IF NOT EXISTS active_tool_id TEXT DEFAULT 'rusty_shovel',
ADD COLUMN IF NOT EXISTS last_logout_at TIMESTAMPTZ DEFAULT NOW();

-- 2. Owned Tools Table
CREATE TABLE IF NOT EXISTS public.owned_tools (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    tool_id TEXT NOT NULL,
    purchased_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, tool_id)
);

-- 3. Completed Sets Table
CREATE TABLE IF NOT EXISTS public.completed_sets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    set_id TEXT NOT NULL,
    claimed_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, set_id)
);

-- RLS for new tables
ALTER TABLE public.owned_tools ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.completed_sets ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Users can view own tools" ON public.owned_tools;
    CREATE POLICY "Users can view own tools" ON public.owned_tools FOR SELECT USING (auth.uid() = user_id);
    
    DROP POLICY IF EXISTS "Users can view own completed sets" ON public.completed_sets;
    CREATE POLICY "Users can view own completed sets" ON public.completed_sets FOR SELECT USING (auth.uid() = user_id);
EXCEPTION
    WHEN undefined_object THEN null;
END $$;


-- 4. Updated RPC: rpc_extract
-- Awards XP and applies tool bonuses
CREATE OR REPLACE FUNCTION public.rpc_extract()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_profile RECORD;
    v_roll FLOAT;
    v_result TEXT;
    v_scrap_gain INT := 0;
    v_xp_gain INT := 0;
    v_crate_dropped BOOLEAN := FALSE;
    v_cooldown_sec INT := 3;
    v_crate_rate FLOAT := 0.20; -- Base 20%
BEGIN
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    
    -- Check cooldown
    IF v_profile.last_extract_at > NOW() - (v_cooldown_sec || ' seconds')::INTERVAL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Cooldown active');
    END IF;

    -- Apply Tool Bonuses (Simplistic for now, should ideally be lookup in a tools table/config)
    IF v_profile.active_tool_id = 'pneumatic_pick' THEN v_crate_rate := 0.25; END IF;
    IF v_profile.active_tool_id = 'ground_radar' THEN v_crate_rate := 0.30; END IF;

    v_roll := random();
    
    IF v_roll < v_crate_rate AND v_profile.tray_count < 5 THEN
        v_crate_dropped := TRUE;
        v_result := 'CRATE_FOUND';
        v_xp_gain := 15;
    ELSIF v_roll < 0.9 THEN
        v_scrap_gain := floor(random() * (15 - 5 + 1) + 5)::INT;
        v_result := 'SCRAP_FOUND';
        v_xp_gain := 5;
    ELSE
        v_result := 'NOTHING_FOUND';
        v_xp_gain := 1;
    END IF;

    UPDATE public.profiles
    SET 
        scrap_balance = scrap_balance + v_scrap_gain,
        excavation_xp = excavation_xp + v_xp_gain,
        tray_count = CASE WHEN v_crate_dropped THEN tray_count + 1 ELSE tray_count END,
        last_extract_at = NOW(),
        updated_at = NOW()
    WHERE id = v_user_id;

    RETURN jsonb_build_object(
        'success', true, 
        'result', v_result, 
        'scrap_gain', v_scrap_gain, 
        'xp_gain', v_xp_gain,
        'crate_dropped', v_crate_dropped,
        'new_balance', v_profile.scrap_balance + v_scrap_gain,
        'new_xp', v_profile.excavation_xp + v_xp_gain,
        'new_tray_count', CASE WHEN v_crate_dropped THEN v_profile.tray_count + 1 ELSE v_profile.tray_count END
    );
END;
$$;

-- 5. Updated RPC: rpc_sift
-- Awards Restoration XP
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
        RETURN jsonb_build_object('success', true, 'outcome', 'SUCCESS', 'new_stage', v_lab.current_stage + 1, 'xp_gain', v_xp_gain);
    ELSE
        UPDATE public.lab_state SET is_active = FALSE, current_stage = 0, last_action_at = NOW() WHERE user_id = v_user_id;
        UPDATE public.profiles SET tray_count = tray_count - 1 WHERE id = v_user_id;
        RETURN jsonb_build_object('success', true, 'outcome', 'SHATTERED');
    END IF;
END;
$$;

-- 6. RPC: rpc_upgrade_tool
CREATE OR REPLACE FUNCTION public.rpc_upgrade_tool(p_tool_id TEXT, p_cost INT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_profile RECORD;
BEGIN
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    
    IF v_profile.scrap_balance < p_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient scrap');
    END IF;

    INSERT INTO public.owned_tools (user_id, tool_id) 
    VALUES (v_user_id, p_tool_id)
    ON CONFLICT (user_id, tool_id) DO NOTHING;

    UPDATE public.profiles 
    SET scrap_balance = scrap_balance - p_cost, active_tool_id = p_tool_id, updated_at = NOW()
    WHERE id = v_user_id;

    RETURN jsonb_build_object('success', true, 'active_tool_id', p_tool_id);
END;
$$;

-- ==========================================
-- PHASE 3: The Connected World (MMO Layer)
-- ==========================================

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

DO $$ 
BEGIN
    CREATE POLICY "Public read mints" ON public.item_mints FOR SELECT USING (true);
    CREATE POLICY "Public read listings" ON public.market_listings FOR SELECT USING (true);
    CREATE POLICY "Sellers update own listings" ON public.market_listings FOR UPDATE USING (auth.uid() = seller_id);
    CREATE POLICY "Public read bids" ON public.market_bids FOR SELECT USING (true);
    CREATE POLICY "Bidders insert bids" ON public.market_bids FOR INSERT WITH CHECK (auth.uid() = bidder_id);
    CREATE POLICY "Public read events" ON public.global_events FOR SELECT USING (true);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

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
    INSERT INTO public.item_mints (item_id, next_mint_number) VALUES (v_item_id, 2)
    ON CONFLICT (item_id) DO UPDATE SET next_mint_number = item_mints.next_mint_number + 1
    RETURNING next_mint_number - 1 INTO v_mint_num;
    
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
    SELECT * INTO v_item FROM public.vault_items WHERE id = p_vault_item_id AND user_id = v_user_id;
    IF v_item IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Item not found');
    END IF;
    
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

-- ==========================================
-- PHASE 4: The High Curator Meta-Game
-- ==========================================

-- 1. Modify Profiles
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS historical_influence INTEGER DEFAULT 0 NOT NULL CHECK (historical_influence >= 0);

-- 2. Modify Vault Items
ALTER TABLE public.vault_items
ADD COLUMN IF NOT EXISTS certified_by_player_id UUID REFERENCES public.profiles(id),
ADD COLUMN IF NOT EXISTS certification_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS attributes JSONB DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS locked_until TIMESTAMPTZ;

-- 3. Museum Tables
DO $$ BEGIN
    CREATE TYPE museum_week_status AS ENUM ('active', 'calculating', 'finalized');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS public.museum_weeks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    theme_name TEXT NOT NULL,
    description TEXT,
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    status museum_week_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.museum_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    week_id UUID REFERENCES public.museum_weeks(id) NOT NULL,
    player_id UUID REFERENCES public.profiles(id) NOT NULL,
    vault_item_id UUID REFERENCES public.vault_items(id) NOT NULL,
    score NUMERIC NOT NULL,
    locked_until TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(week_id, vault_item_id)
);

-- 4. Historical Influence Transactions
CREATE TABLE IF NOT EXISTS public.historical_influence_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID REFERENCES public.profiles(id) NOT NULL,
    amount INTEGER NOT NULL,
    source TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. World Events
DO $$ BEGIN
    CREATE TYPE world_event_status AS ENUM ('upcoming', 'active', 'ended');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS public.world_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    status world_event_status NOT NULL DEFAULT 'upcoming',
    modifiers JSONB DEFAULT '{}'::jsonb,
    global_goal_target BIGINT NOT NULL,
    global_goal_progress BIGINT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.world_event_contributions (
    event_id UUID REFERENCES public.world_events(id) NOT NULL,
    player_id UUID REFERENCES public.profiles(id) NOT NULL,
    contribution_value BIGINT NOT NULL DEFAULT 0,
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (event_id, player_id)
);

-- 6. RLS Policies
ALTER TABLE public.museum_weeks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.museum_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.historical_influence_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.world_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.world_event_contributions ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Everyone can view museum weeks" ON public.museum_weeks;
    CREATE POLICY "Everyone can view museum weeks" ON public.museum_weeks FOR SELECT USING (true);
    
    DROP POLICY IF EXISTS "Everyone can view museum submissions" ON public.museum_submissions;
    CREATE POLICY "Everyone can view museum submissions" ON public.museum_submissions FOR SELECT USING (true);
    
    DROP POLICY IF EXISTS "Users can view own influence transactions" ON public.historical_influence_transactions;
    CREATE POLICY "Users can view own influence transactions" ON public.historical_influence_transactions FOR SELECT USING (auth.uid() = player_id);
    
    DROP POLICY IF EXISTS "Everyone can view world events" ON public.world_events;
    CREATE POLICY "Everyone can view world events" ON public.world_events FOR SELECT USING (true);
    
    DROP POLICY IF EXISTS "Everyone can view event contributions" ON public.world_event_contributions;
    CREATE POLICY "Everyone can view event contributions" ON public.world_event_contributions FOR SELECT USING (true);
EXCEPTION
    WHEN undefined_object THEN null;
END $$;

-- 7. RPC: Get Current Museum Week
CREATE OR REPLACE FUNCTION public.rpc_museum_get_current_week()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_week RECORD;
    v_submissions JSONB;
BEGIN
    SELECT * INTO v_week FROM public.museum_weeks WHERE status = 'active' ORDER BY ends_at ASC LIMIT 1;
    
    IF v_week IS NULL THEN
        RETURN jsonb_build_object('success', true, 'active_week', null);
    END IF;

    SELECT jsonb_agg(jsonb_build_object(
        'vault_item_id', s.vault_item_id,
        'score', s.score,
        'item_details', (SELECT jsonb_build_object('item_id', i.item_id, 'mint_number', i.mint_number) FROM public.vault_items i WHERE i.id = s.vault_item_id)
    )) INTO v_submissions 
    FROM public.museum_submissions s
    WHERE s.week_id = v_week.id AND s.player_id = v_user_id;

    RETURN jsonb_build_object(
        'success', true,
        'active_week', jsonb_build_object(
            'id', v_week.id,
            'theme_name', v_week.theme_name,
            'description', v_week.description,
            'ends_at', v_week.ends_at
        ),
        'user_submissions', COALESCE(v_submissions, '[]'::jsonb)
    );
END;
$$;

-- 8. RPC: Submit Item to Museum
CREATE OR REPLACE FUNCTION public.rpc_museum_submit_item(p_vault_item_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_week RECORD;
    v_item RECORD;
    v_score NUMERIC := 100; -- Placeholder
    v_submission_count INT;
BEGIN
    -- Get active week
    SELECT * INTO v_week FROM public.museum_weeks WHERE status = 'active' ORDER BY ends_at ASC LIMIT 1;
    IF v_week IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'No active museum week');
    END IF;

    -- Check submission limit
    SELECT COUNT(*) INTO v_submission_count FROM public.museum_submissions WHERE week_id = v_week.id AND player_id = v_user_id;
    IF v_submission_count >= 10 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Weekly submission limit reached');
    END IF;

    -- Verify ownership and not locked
    SELECT * INTO v_item FROM public.vault_items WHERE id = p_vault_item_id AND user_id = v_user_id;
    IF v_item IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Item not found');
    END IF;

    IF v_item.locked_until IS NOT NULL AND v_item.locked_until > NOW() THEN
        RETURN jsonb_build_object('success', false, 'error', 'Item is locked');
    END IF;

    -- Update lock on item
    UPDATE public.vault_items SET locked_until = v_week.ends_at WHERE id = p_vault_item_id;

    -- Insert submission
    INSERT INTO public.museum_submissions (week_id, player_id, vault_item_id, score, locked_until)
    VALUES (v_week.id, v_user_id, p_vault_item_id, v_score, v_week.ends_at);

    RETURN jsonb_build_object('success', true, 'score', v_score);
END;
$$;

-- 9. RPC: Purchase Influence Item
CREATE OR REPLACE FUNCTION public.rpc_purchase_influence_item(p_item_key TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_profile RECORD;
    v_cost INT;
BEGIN
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    
    -- Hardcoded shop logic for now
    IF p_item_key = 'zone_permit_suburbs' THEN
        v_cost := 500;
    ELSIF p_item_key = 'title_curator' THEN
        v_cost := 200;
    ELSE
        RETURN jsonb_build_object('success', false, 'error', 'Invalid item');
    END IF;

    IF v_profile.historical_influence < v_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient influence');
    END IF;

    UPDATE public.profiles SET historical_influence = historical_influence - v_cost WHERE id = v_user_id;

    INSERT INTO public.historical_influence_transactions (player_id, amount, source)
    VALUES (v_user_id, -v_cost, 'shop_purchase_' || p_item_key);

    RETURN jsonb_build_object('success', true);
END;
$$;

-- 10. RPC: Get Active World Event
CREATE OR REPLACE FUNCTION public.rpc_world_event_get_active()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_event RECORD;
BEGIN
    SELECT * INTO v_event FROM public.world_events WHERE status = 'active' AND ends_at > NOW() LIMIT 1;
    
    IF v_event IS NULL THEN
        RETURN jsonb_build_object('success', true, 'active_event', null);
    END IF;

    RETURN jsonb_build_object('success', true, 'active_event', row_to_json(v_event));
END;
$$;
