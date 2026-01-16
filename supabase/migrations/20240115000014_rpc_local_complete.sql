-- Completing the Local Identity RPC Overrides
-- This migration updates the remaining game RPCs to accept an optional p_user_id.

-- 1. Update rpc_sift
CREATE OR REPLACE FUNCTION public.rpc_sift(p_user_id UUID DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := public.get_auth_user(p_user_id);
    v_lab RECORD;
    v_profile RECORD;
    v_base_stability FLOAT;
    v_bonus_stability FLOAT;
    v_final_stability FLOAT;
    v_roll FLOAT;
    v_success BOOLEAN;
    v_xp_gain INT := 0;
    v_restoration_level INT;
    v_overclock_bonus FLOAT := 0;
BEGIN
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated');
    END IF;

    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    SELECT * INTO v_lab FROM public.lab_state WHERE user_id = v_user_id;
    
    IF v_lab IS NULL OR NOT v_lab.is_active THEN
        RETURN jsonb_build_object('success', false, 'error', 'No active crate in lab');
    END IF;

    -- Base Stability per stage
    CASE v_lab.current_stage
        WHEN 0 THEN v_base_stability := 0.90;
        WHEN 1 THEN v_base_stability := 0.75;
        WHEN 2 THEN v_base_stability := 0.50;
        WHEN 3 THEN v_base_stability := 0.25;
        WHEN 4 THEN v_base_stability := 0.10;
        ELSE v_base_stability := 0;
    END CASE;

    -- Level Bonus: +0.1% per level
    v_restoration_level := public.get_level(COALESCE(v_profile.restoration_xp, 0));
    v_bonus_stability := v_restoration_level * 0.001;
    v_overclock_bonus := COALESCE(v_profile.overclock_bonus, 0);
    
    v_final_stability := v_base_stability + v_bonus_stability + v_overclock_bonus;

    -- Roll
    v_roll := random();
    v_success := v_roll < v_final_stability;

    IF v_success THEN
        v_xp_gain := (v_lab.current_stage + 1) * 10;
        UPDATE public.lab_state SET current_stage = current_stage + 1, last_action_at = NOW() WHERE user_id = v_user_id;
        UPDATE public.profiles SET restoration_xp = COALESCE(restoration_xp, 0) + v_xp_gain WHERE id = v_user_id;
        
        RETURN jsonb_build_object(
            'success', true, 
            'outcome', 'SUCCESS', 
            'new_stage', v_lab.current_stage + 1,
            'xp_gain', v_xp_gain
        );
    ELSE
        -- SHATTERED
        UPDATE public.lab_state SET is_active = FALSE, current_stage = 0, last_action_at = NOW() WHERE user_id = v_user_id;
        UPDATE public.profiles SET tray_count = GREATEST(0, COALESCE(tray_count, 0) - 1) WHERE id = v_user_id;
        
        RETURN jsonb_build_object(
            'success', true, 
            'outcome', 'SHATTERED',
            'xp_gain', 2 -- Pity XP
        );
    END IF;
END;
$$;

-- 2. Update rpc_claim
CREATE OR REPLACE FUNCTION public.rpc_claim(p_user_id UUID DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := public.get_auth_user(p_user_id);
    v_lab RECORD;
    v_item_id TEXT;
    v_tier TEXT;
    v_mint_num BIGINT;
BEGIN
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated');
    END IF;

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

    -- Pick random item
    IF v_tier = 'rare' THEN
        SELECT item INTO v_item_id FROM unnest(ARRAY['calculated_tablet', 'wrist_chronometer', 'compact_disc', 'remote_control', 'computer_mouse', 'flashlight', 'headphone_set', 'digital_camera']) AS item ORDER BY random() LIMIT 1;
    ELSE
        SELECT item INTO v_item_id FROM unnest(ARRAY['rusty_key', 'ceramic_mug', 'aa_battery', 'plastic_comb', 'steel_fork', 'lightbulb', 'ballpoint_pen', 'eyeglass_frame', 'soda_tab', 'safety_pin', 'rubber_band', 'broken_watch']) AS item ORDER BY random() LIMIT 1;
    END IF;

    -- Assign mint number
    INSERT INTO public.item_mints (item_id, next_mint_number)
    VALUES (v_item_id, 1)
    ON CONFLICT (item_id) DO UPDATE SET next_mint_number = public.item_mints.next_mint_number + 1
    RETURNING next_mint_number - 1 INTO v_mint_num;

    -- Save to vault
    INSERT INTO public.vault_items (user_id, item_id, mint_number) 
    VALUES (v_user_id, v_item_id, v_mint_num);

    -- Clean up lab and tray
    UPDATE public.lab_state SET is_active = FALSE, current_stage = 0, last_action_at = NOW() WHERE user_id = v_user_id;
    UPDATE public.profiles SET tray_count = GREATEST(0, COALESCE(tray_count, 0) - 1) WHERE id = v_user_id;

    RETURN jsonb_build_object(
        'success', true, 
        'item_id', v_item_id, 
        'tier', v_tier,
        'mint_number', v_mint_num
    );
END;
$$;

-- 3. Update rpc_list_item
CREATE OR REPLACE FUNCTION public.rpc_list_item(p_vault_item_id UUID, p_price BIGINT, p_hours INT, p_user_id UUID DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := public.get_auth_user(p_user_id);
    v_item RECORD;
    v_profile RECORD;
    v_deposit BIGINT := 50;
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    IF COALESCE(v_profile.scrap_balance, 0) < v_deposit THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient scrap for deposit');
    END IF;

    SELECT * INTO v_item FROM public.vault_items WHERE id = p_vault_item_id AND user_id = v_user_id;
    IF v_item IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Item not found');
    END IF;
    
    -- Deduct deposit
    UPDATE public.profiles SET scrap_balance = scrap_balance - v_deposit WHERE id = v_user_id;

    INSERT INTO public.market_listings (seller_id, vault_item_id, reserve_price, ends_at, deposit_amount)
    VALUES (v_user_id, p_vault_item_id, p_price, NOW() + (p_hours || ' hours')::INTERVAL, v_deposit);

    RETURN jsonb_build_object('success', true);
END;
$$;

-- 4. Update rpc_place_bid
CREATE OR REPLACE FUNCTION public.rpc_place_bid(p_listing_id UUID, p_amount BIGINT, p_user_id UUID DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := public.get_auth_user(p_user_id);
    v_listing RECORD;
    v_profile RECORD;
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;
    SELECT * INTO v_listing FROM public.market_listings WHERE id = p_listing_id;
    
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
    IF COALESCE(v_profile.scrap_balance, 0) < p_amount THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient funds');
    END IF;

    -- Take money
    UPDATE public.profiles SET scrap_balance = scrap_balance - p_amount WHERE id = v_user_id;

    -- Refund previous bidder
    IF v_listing.highest_bidder_id IS NOT NULL THEN
        UPDATE public.profiles SET scrap_balance = scrap_balance + v_listing.highest_bid WHERE id = v_listing.highest_bidder_id;
    END IF;

    UPDATE public.market_listings 
    SET highest_bid = p_amount, highest_bidder_id = v_user_id 
    WHERE id = p_listing_id;

    INSERT INTO public.market_bids (listing_id, bidder_id, amount) VALUES (p_listing_id, v_user_id, p_amount);

    RETURN jsonb_build_object('success', true);
END;
$$;

-- 5. Update rpc_purchase_influence_item
CREATE OR REPLACE FUNCTION public.rpc_purchase_influence_item(p_item_key TEXT, p_user_id UUID DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := public.get_auth_user(p_user_id);
    v_profile RECORD;
    v_cost INT;
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    
    IF p_item_key = 'zone_permit_suburbs' THEN v_cost := 500;
    ELSIF p_item_key = 'title_curator' THEN v_cost := 200;
    ELSE RETURN jsonb_build_object('success', false, 'error', 'Invalid item');
    END IF;

    IF COALESCE(v_profile.historical_influence, 0) < v_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient influence');
    END IF;

    UPDATE public.profiles SET historical_influence = historical_influence - v_cost WHERE id = v_user_id;
    RETURN jsonb_build_object('success', true);
END;
$$;

-- 6. Update rpc_overclock_tool
CREATE OR REPLACE FUNCTION public.rpc_overclock_tool(p_tool_id TEXT, p_cost INT, p_user_id UUID DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := public.get_auth_user(p_user_id);
    v_profile RECORD;
    v_current_level INT;
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    
    SELECT level INTO v_current_level FROM public.owned_tools WHERE user_id = v_user_id AND tool_id = p_tool_id;
    
    IF v_current_level < 10 THEN RETURN jsonb_build_object('success', false, 'error', 'Tool level too low'); END IF;
    IF COALESCE(v_profile.scrap_balance, 0) < p_cost THEN RETURN jsonb_build_object('success', false, 'error', 'Insufficient scrap'); END IF;

    UPDATE public.owned_tools SET level = 1 WHERE user_id = v_user_id AND tool_id = p_tool_id;
    UPDATE public.profiles SET overclock_bonus = COALESCE(overclock_bonus, 0) + 0.05, scrap_balance = scrap_balance - p_cost WHERE id = v_user_id;

    RETURN jsonb_build_object('success', true, 'new_bonus', (SELECT overclock_bonus FROM public.profiles WHERE id = v_user_id));
END;
$$;
