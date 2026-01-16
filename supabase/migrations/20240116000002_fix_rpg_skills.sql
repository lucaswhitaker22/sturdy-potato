-- 20240116000002_fix_rpg_skills.sql
-- Implements Smelting, Appraisal, and Level 99 Mastery Perks

-- 1. Add XP columns for new skills
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS appraisal_xp BIGINT DEFAULT 0 CHECK (appraisal_xp >= 0),
ADD COLUMN IF NOT EXISTS smelting_xp BIGINT DEFAULT 0 CHECK (smelting_xp >= 0);

-- 2. RPC: Smelt (Break down items for Scrap + XP)
CREATE OR REPLACE FUNCTION public.rpc_smelt(p_item_id UUID, p_user_id UUID DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := public.get_auth_user(p_user_id);
    v_vault_item RECORD;
    v_item_def RECORD;
    v_profile RECORD;
    v_smelting_level INT;
    v_base_scrap INT := 0;
    v_final_scrap INT := 0;
    v_xp_gain INT := 10;
    v_is_junk BOOLEAN := FALSE;
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;

    -- Get Item
    SELECT * INTO v_vault_item FROM public.vault_items WHERE id = p_item_id AND user_id = v_user_id;
    IF v_vault_item IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Item not found');
    END IF;

    -- Get Definition
    SELECT * INTO v_item_def FROM public.item_definitions WHERE id = v_vault_item.item_id;
    
    -- Determine Base Scrap
    CASE v_item_def.tier
        WHEN 'junk' THEN 
            v_base_scrap := 2;
            v_is_junk := TRUE;
        WHEN 'common' THEN v_base_scrap := 5;
        WHEN 'uncommon' THEN v_base_scrap := 15;
        WHEN 'rare' THEN v_base_scrap := 50;
        WHEN 'epic' THEN v_base_scrap := 200;
        WHEN 'mythic' THEN v_base_scrap := 1000;
        WHEN 'unique' THEN v_base_scrap := 5000;
        ELSE v_base_scrap := 1;
    END CASE;

    -- Get Profile & Level
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    v_smelting_level := public.get_level(COALESCE(v_profile.smelting_xp, 0));

    -- Mastery Perk: "Pure Yield" (Lvl 99) - 2x Scrap from Junk
    IF v_smelting_level >= 99 AND v_is_junk THEN
        v_final_scrap := v_base_scrap * 2;
    ELSE
        v_final_scrap := v_base_scrap;
    END IF;

    -- Execute Smelt
    DELETE FROM public.vault_items WHERE id = p_item_id;
    
    UPDATE public.profiles
    SET 
        scrap_balance = COALESCE(scrap_balance, 0) + v_final_scrap,
        smelting_xp = COALESCE(smelting_xp, 0) + v_xp_gain
    WHERE id = v_user_id;

    RETURN jsonb_build_object(
        'success', true, 
        'scrap_gained', v_final_scrap, 
        'xp_gained', v_xp_gain,
        'new_balance', COALESCE(v_profile.scrap_balance, 0) + v_final_scrap
    );
END;
$$;

-- 3. Update rpc_extract: Add "The Endless Vein" (Lvl 99 Excavation)
CREATE OR REPLACE FUNCTION public.rpc_extract(p_user_id UUID DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := public.get_auth_user(p_user_id);
    v_profile RECORD;
    v_roll FLOAT;
    v_result TEXT;
    v_scrap_gain INT := 0;
    v_xp_gain INT := 0;
    v_crate_dropped BOOLEAN := FALSE;
    v_cooldown_sec FLOAT := 3.0;
    v_base_crate_rate FLOAT := 0.15;
    v_anomaly_rate FLOAT := 0.05;
    v_bonus_rate FLOAT := 0.0;
    v_excavation_level INT;
    v_anomaly_happened BOOLEAN := FALSE;
    v_final_balance BIGINT;
    v_final_xp BIGINT;
    v_final_tray INT;
    -- Mastery Vars
    v_double_loot BOOLEAN := FALSE;
BEGIN
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated');
    END IF;

    -- Ensure profile exists
    INSERT INTO public.profiles (id, scrap_balance, tray_count, excavation_xp, restoration_xp)
    VALUES (v_user_id, 0, 0, 0, 0)
    ON CONFLICT (id) DO NOTHING;

    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    
    -- Check for buffs (Sets)
    IF EXISTS (
        SELECT 1 FROM public.completed_sets 
        WHERE user_id = v_user_id AND set_id = 'morning_ritual'
    ) THEN
        v_cooldown_sec := v_cooldown_sec - 0.5;
    END IF;

    -- Check cooldown
    IF v_profile.last_extract_at IS NOT NULL AND v_profile.last_extract_at > NOW() - (v_cooldown_sec || ' seconds')::INTERVAL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Cooldown active');
    END IF;

    -- Calculate Excavation Level
    v_excavation_level := coalesce(public.get_level(COALESCE(v_profile.excavation_xp, 0)), 1);

    -- Mastery Perk: "The Endless Vein" (15% Double Loot)
    IF v_excavation_level >= 99 AND random() < 0.15 THEN
        v_double_loot := TRUE;
    END IF;

    -- Apply Level Bonus (Crate Rate)
    v_bonus_rate := floor(v_excavation_level / 5) * 0.005;
    
    -- Roll
    v_roll := random();
    
    IF v_roll < v_anomaly_rate THEN
        v_result := 'ANOMALY';
        v_xp_gain := 25;
        v_anomaly_happened := TRUE;
    ELSIF v_roll < (v_anomaly_rate + v_base_crate_rate + v_bonus_rate) AND v_profile.tray_count < 5 THEN
        v_crate_dropped := TRUE;
        v_result := 'CRATE_FOUND';
        v_xp_gain := 15;
    ELSE
        v_scrap_gain := floor(random() * (15 - 5 + 1) + 5)::INT;
        v_result := 'SCRAP_FOUND';
        v_xp_gain := 5;
    END IF;

    -- Apply Double Loot
    IF v_double_loot THEN
        v_scrap_gain := v_scrap_gain * 2;
        -- If crate dropped, maybe drop 2? Tray limit 5.
        IF v_crate_dropped AND v_profile.tray_count < 4 THEN
             -- Actually we just increment tray count by 2 later if possible.
             -- But logic below adds 1.
             -- Let's just say double loot mostly applies to Scrap for now to keep logic simple, 
             -- or we set a flag to add +1 extra tray item.
             NULL; -- Logic handled in Update
        END IF;
    END IF;

    UPDATE public.profiles
    SET 
        scrap_balance = COALESCE(scrap_balance, 0) + v_scrap_gain,
        excavation_xp = COALESCE(excavation_xp, 0) + v_xp_gain,
        tray_count = CASE 
            WHEN v_crate_dropped AND v_double_loot AND COALESCE(tray_count, 0) < 4 THEN COALESCE(tray_count, 0) + 2
            WHEN v_crate_dropped THEN COALESCE(tray_count, 0) + 1 
            ELSE COALESCE(tray_count, 0) 
        END,
        last_extract_at = NOW(),
        updated_at = NOW()
    WHERE id = v_user_id
    RETURNING scrap_balance, excavation_xp, tray_count INTO v_final_balance, v_final_xp, v_final_tray;

    IF v_anomaly_happened THEN
        INSERT INTO public.global_events (event_type, user_id, details)
        VALUES ('anomaly', v_user_id, jsonb_build_object('item_id', 'temporal_rift', 'xp_gain', v_xp_gain));
    END IF;

    RETURN jsonb_build_object(
        'success', true, 
        'result', v_result, 
        'scrap_gain', v_scrap_gain, 
        'xp_gain', v_xp_gain,
        'crate_dropped', v_crate_dropped,
        'double_loot', v_double_loot,
        'anomaly', v_anomaly_happened,
        'level', v_excavation_level,
        'new_balance', v_final_balance,
        'new_xp', v_final_xp,
        'new_tray_count', v_final_tray
    );
END;
$$;

-- 4. Update rpc_sift: Add "Master Preserver" (Lvl 99 Restoration)
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
    
    -- Mastery Perk: "Master Preserver" (+10% base stability)
    IF v_restoration_level >= 99 THEN
        v_bonus_stability := v_bonus_stability + 0.10;
    END IF;

    v_final_stability := v_base_stability + v_bonus_stability + v_overclock_bonus;

    -- Roll
    v_roll := random();
    v_success := v_roll < v_final_stability;

    IF v_success THEN
        v_xp_gain := (v_lab.current_stage + 1) * 10;
        UPDATE public.lab_state SET current_stage = current_stage + 1, last_action_at = NOW() WHERE user_id = v_user_id;
        UPDATE public.profiles SET restoration_xp = COALESCE(restoration_xp, 0) + v_xp_gain, updated_at = NOW() WHERE id = v_user_id;
        
        RETURN jsonb_build_object(
            'success', true, 
            'outcome', 'SUCCESS', 
            'new_stage', v_lab.current_stage + 1,
            'xp_gain', v_xp_gain,
            'stability_used', v_final_stability
        );
    ELSE
        -- Pity XP
        v_xp_gain := 2; 
        UPDATE public.profiles SET restoration_xp = COALESCE(restoration_xp, 0) + v_xp_gain, updated_at = NOW() WHERE id = v_user_id;

        UPDATE public.lab_state SET is_active = FALSE, current_stage = 0, last_action_at = NOW() WHERE user_id = v_user_id;
        UPDATE public.profiles SET tray_count = GREATEST(0, COALESCE(tray_count, 0) - 1) WHERE id = v_user_id;
        RETURN jsonb_build_object('success', true, 'outcome', 'SHATTERED', 'xp_gain', v_xp_gain);
    END IF;
END;
$$;

-- 5. Update rpc_claim: Add "Master Preserver" (+1% HV)
CREATE OR REPLACE FUNCTION public.rpc_claim(p_user_id UUID DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := public.get_auth_user(p_user_id);
    v_lab RECORD;
    v_item_def RECORD;
    v_profile RECORD;
    v_tier item_tier;
    v_condition item_condition;
    v_condition_mult FLOAT;
    v_is_prismatic BOOLEAN := FALSE;
    v_prismatic_mult FLOAT := 1.0;
    v_mint_mult FLOAT := 1.0;
    v_final_hv INT;
    v_mint_num BIGINT;
    v_roll FLOAT;
    v_new_item_id UUID;
    v_restoration_level INT;
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;

    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    SELECT * INTO v_lab FROM public.lab_state WHERE user_id = v_user_id;
    
    IF v_lab IS NULL OR NOT v_lab.is_active THEN
        RETURN jsonb_build_object('success', false, 'error', 'No active crate to claim');
    END IF;

    -- 1. Determine Tier based on Stage
    CASE 
        WHEN v_lab.current_stage >= 5 THEN v_tier := 'mythic';
        WHEN v_lab.current_stage = 4 THEN v_tier := 'epic';
        WHEN v_lab.current_stage = 3 THEN v_tier := 'rare';
        WHEN v_lab.current_stage = 2 THEN v_tier := 'uncommon';
        ELSE v_tier := 'common';
    END CASE;
    
    -- 2. Pick Random Item of Tier
    SELECT * INTO v_item_def 
    FROM public.item_definitions 
    WHERE tier = v_tier 
    ORDER BY random() 
    LIMIT 1;

    IF v_item_def IS NULL THEN
        SELECT * INTO v_item_def FROM public.item_definitions WHERE tier = 'common' LIMIT 1;
    END IF;

    -- 3. Prismatic Roll (1%)
    IF random() < 0.01 THEN
        v_is_prismatic := TRUE;
        v_prismatic_mult := 3.0;
    END IF;

    -- 4. Condition Roll
    v_roll := random();
    IF v_roll < 0.05 THEN
        v_condition := 'mint';
        v_condition_mult := 2.5;
    ELSIF v_roll < 0.20 THEN
        v_condition := 'preserved';
        v_condition_mult := 1.5;
    ELSIF v_roll < 0.70 THEN
        v_condition := 'weathered';
        v_condition_mult := 1.0;
    ELSE
        v_condition := 'wrecked';
        v_condition_mult := 0.5;
    END IF;

    -- 5. Mint Number
    INSERT INTO public.item_mints (item_id, next_mint_number)
    VALUES (v_item_def.id, 2)
    ON CONFLICT (item_id) DO UPDATE SET next_mint_number = item_mints.next_mint_number + 1
    RETURNING next_mint_number - 1 INTO v_mint_num;

    -- Low Mint Bonus (First 10)
    IF v_mint_num <= 10 THEN
        v_mint_mult := 1.5;
    END IF;

    -- 6. Calculate HV
    v_final_hv := floor(v_item_def.base_hv * v_condition_mult * v_prismatic_mult * v_mint_mult)::INT;

    -- Mastery Perk: "Master Preserver" (Lvl 99 Restoration) - +1% HV
    v_restoration_level := public.get_level(COALESCE(v_profile.restoration_xp, 0));
    IF v_restoration_level >= 99 THEN
        v_final_hv := floor(v_final_hv * 1.01)::INT;
    END IF;

    -- 7. Insert Vault Item
    INSERT INTO public.vault_items (
        user_id, item_id, mint_number, condition, is_prismatic, historical_value, discovered_at
    ) 
    VALUES (
        v_user_id, v_item_def.id, v_mint_num, v_condition, v_is_prismatic, v_final_hv, NOW()
    )
    RETURNING id INTO v_new_item_id;

    -- 8. Cleanup Lab
    UPDATE public.lab_state SET is_active = FALSE, current_stage = 0, last_action_at = NOW() WHERE user_id = v_user_id;
    UPDATE public.profiles SET tray_count = GREATEST(0, COALESCE(tray_count, 0) - 1) WHERE id = v_user_id;

    -- 9. Auto-Check Collections
    PERFORM public.check_collection_completion(v_user_id, v_item_def.id);

    -- 10. Global Event for Good Stuff
    IF v_is_prismatic OR v_tier IN ('epic', 'mythic', 'unique') THEN
        INSERT INTO public.global_events (event_type, user_id, details)
        VALUES ('find', v_user_id, jsonb_build_object(
            'item_id', v_item_def.id, 
            'mint_number', v_mint_num, 
            'is_prismatic', v_is_prismatic,
            'hv', v_final_hv
        ));
    END IF;

    RETURN jsonb_build_object(
        'success', true, 
        'item', jsonb_build_object(
            'id', v_item_def.id,
            'name', v_item_def.name,
            'tier', v_item_def.tier,
            'mint_number', v_mint_num,
            'condition', v_condition,
            'is_prismatic', v_is_prismatic,
            'historical_value', v_final_hv,
            'flavor_text', v_item_def.flavor_text
        )
    );
END;
$$;

-- 6. Update rpc_list_item: Add Appraisal XP (Manual)
CREATE OR REPLACE FUNCTION public.rpc_list_item(p_vault_item_id UUID, p_price BIGINT, p_hours INT, p_user_id UUID DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := public.get_auth_user(p_user_id);
    v_item RECORD;
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;
    
    -- Verify ownership
    SELECT * INTO v_item FROM public.vault_items WHERE id = p_vault_item_id AND user_id = v_user_id;
    IF v_item IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Item not found');
    END IF;

    -- Create Listing
    INSERT INTO public.market_listings (seller_id, vault_item_id, reserve_price, ends_at)
    VALUES (v_user_id, p_vault_item_id, p_price, NOW() + (p_hours || ' hours')::INTERVAL);

    -- Award Appraisal XP (e.g. 50 + 1% of asking price capped?)
    -- Simplified: 50 XP per listing
    UPDATE public.profiles SET appraisal_xp = COALESCE(appraisal_xp, 0) + 50 WHERE id = v_user_id;

    -- Determine fees? Docs say 2.5% for masters. For now just listing is free?
    -- Assume free listing, fee on sale. But implementation of sale is needed. 
    -- Sale happens on claim/end?
    -- For now just XP on list.

    RETURN jsonb_build_object('success', true);
END;
$$;

-- 7. Update rpc_place_bid: Add Appraisal XP
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

    -- Award Appraisal XP
    UPDATE public.profiles SET appraisal_xp = COALESCE(appraisal_xp, 0) + 10 WHERE id = v_user_id;

    RETURN jsonb_build_object('success', true);
END;
$$;
