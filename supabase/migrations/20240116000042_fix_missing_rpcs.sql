-- 20240116000042_fix_missing_rpcs.sql

-- 1. Helper: Roll Crate Contents (Needed for Passive Tick)
CREATE OR REPLACE FUNCTION public.rpc_helper_roll_crate()
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    v_condition item_condition;
    v_is_prismatic BOOLEAN := FALSE;
    v_roll FLOAT;
    v_items_by_tier JSONB := '{}'::JSONB;
    v_tier item_tier;
    v_item_id TEXT;
BEGIN
    -- 1. Condition Roll
    v_roll := random();
    IF v_roll < 0.05 THEN v_condition := 'mint';
    ELSIF v_roll < 0.20 THEN v_condition := 'preserved';
    ELSIF v_roll < 0.70 THEN v_condition := 'weathered';
    ELSE v_condition := 'wrecked';
    END IF;

    -- 2. Prismatic Roll (1%)
    IF random() < 0.01 THEN
        v_is_prismatic := TRUE;
    END IF;

    -- 3. Pre-pick items for each possible tier
    FOR v_tier IN SELECT unnest(enum_range(NULL::item_tier)) LOOP
        SELECT id INTO v_item_id FROM public.item_definitions WHERE tier = v_tier ORDER BY random() LIMIT 1;
        v_items_by_tier := v_items_by_tier || jsonb_build_object(v_tier::TEXT, v_item_id);
    END LOOP;

    RETURN jsonb_build_object(
        'condition', v_condition,
        'is_prismatic', v_is_prismatic,
        'items_by_tier', v_items_by_tier
    );
END;
$$;

-- 2. Restore rpc_start_sifting
CREATE OR REPLACE FUNCTION public.rpc_start_sifting(payload JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    p_crate_id UUID;
    v_profile RECORD;
    v_crate JSONB;
    v_new_tray JSONB := '[]'::JSONB;
    v_found BOOLEAN := FALSE;
BEGIN
    v_user_id := public.get_auth_user((payload->>'p_user_id')::UUID);
    p_crate_id := (payload->>'p_crate_id')::UUID;

    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;

    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;

    -- Find the crate in the tray
    FOR v_crate IN SELECT jsonb_array_elements(v_profile.crate_tray) LOOP
        IF (v_crate->>'id')::UUID = p_crate_id AND NOT v_found THEN
            v_found := TRUE;
            -- Move to lab_state
            UPDATE public.lab_state 
            SET is_active = TRUE, current_stage = 0, last_action_at = NOW(), active_crate = v_crate 
            WHERE user_id = v_user_id;
        ELSE
            v_new_tray := v_new_tray || v_crate;
        END IF;
    END LOOP;

    IF NOT v_found THEN
        RETURN jsonb_build_object('success', false, 'error', 'Crate not found in tray');
    END IF;

    UPDATE public.profiles SET crate_tray = v_new_tray, tray_count = jsonb_array_length(v_new_tray) WHERE id = v_user_id;

    RETURN jsonb_build_object('success', true);
END;
$$;

-- 3. Restore/Update rpc_claim
CREATE OR REPLACE FUNCTION public.rpc_claim(p_user_id UUID DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := public.get_auth_user(p_user_id);
    v_lab RECORD;
    v_item_def RECORD;
    v_tier item_tier;
    v_condition item_condition;
    v_condition_mult FLOAT;
    v_is_prismatic BOOLEAN := FALSE;
    v_prismatic_mult FLOAT := 1.0;
    v_mint_mult FLOAT := 1.0;
    v_final_hv INT;
    v_mint_num BIGINT;
    v_new_item_id UUID;
    v_crate_contents JSONB;
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;

    SELECT * INTO v_lab FROM public.lab_state WHERE user_id = v_user_id;
    
    IF v_lab IS NULL OR NOT v_lab.is_active THEN
        RETURN jsonb_build_object('success', false, 'error', 'No active crate to claim');
    END IF;

    v_crate_contents := v_lab.active_crate->'contents';

    -- 1. Determine Tier based on Stage
    CASE 
        WHEN v_lab.current_stage >= 5 THEN v_tier := 'mythic';
        WHEN v_lab.current_stage = 4 THEN v_tier := 'epic';
        WHEN v_lab.current_stage = 3 THEN v_tier := 'rare';
        WHEN v_lab.current_stage = 2 THEN v_tier := 'uncommon';
        ELSE v_tier := 'common';
    END CASE;
    
    -- 2. Use Pre-rolled Item for this Tier
    SELECT * INTO v_item_def 
    FROM public.item_definitions 
    WHERE id = (v_crate_contents->'items_by_tier'->>v_tier::TEXT);

    IF v_item_def IS NULL THEN
        -- Fallback
        SELECT * INTO v_item_def FROM public.item_definitions WHERE tier = 'common' LIMIT 1;
    END IF;

    -- 3. Use Pre-rolled Modifiers
    v_is_prismatic := (v_crate_contents->>'is_prismatic')::BOOLEAN;
    v_condition := (v_crate_contents->>'condition')::item_condition;

    IF v_is_prismatic THEN v_prismatic_mult := 3.0; END IF;
    CASE v_condition
        WHEN 'mint' THEN v_condition_mult := 2.5;
        WHEN 'preserved' THEN v_condition_mult := 1.5;
        WHEN 'weathered' THEN v_condition_mult := 1.0;
        ELSE v_condition_mult := 0.5;
    END CASE;

    -- 4. Mint Number
    INSERT INTO public.item_mints (item_id, next_mint_number)
    VALUES (v_item_def.id, 2)
    ON CONFLICT (item_id) DO UPDATE SET next_mint_number = item_mints.next_mint_number + 1
    RETURNING next_mint_number - 1 INTO v_mint_num;

    IF v_mint_num <= 10 THEN v_mint_mult := 1.5; END IF;

    -- 5. Calculate HV
    v_final_hv := floor(v_item_def.base_hv * v_condition_mult * v_prismatic_mult * v_mint_mult)::INT;

    -- 6. Insert Vault Item
    INSERT INTO public.vault_items (user_id, item_id, mint_number, condition, is_prismatic, historical_value, discovered_at) 
    VALUES (v_user_id, v_item_def.id, v_mint_num, v_condition, v_is_prismatic, v_final_hv, NOW())
    RETURNING id INTO v_new_item_id;

    -- 7. Cleanup
    UPDATE public.lab_state SET is_active = FALSE, current_stage = 0, last_action_at = NOW(), active_crate = NULL WHERE user_id = v_user_id;

    PERFORM public.check_collection_completion(v_user_id, v_item_def.id);

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

-- 4. Restore rpc_passive_tick
CREATE OR REPLACE FUNCTION public.rpc_passive_tick(p_user_id UUID DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := COALESCE(p_user_id, auth.uid());
    v_profile RECORD;
    v_tool_power INT := 0;
    v_crate_dropped BOOLEAN := FALSE;
    v_excavation_level INT;
    v_roll FLOAT;
    v_base_rate FLOAT := 0.15;
    v_level_bonus FLOAT := 0.0;
    v_new_crate JSONB;
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'No user ID'); END IF;

    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    IF v_profile IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Profile not found'); END IF;
    
    CASE v_profile.active_tool_id
        WHEN 'rusty_shovel' THEN v_tool_power := 0;
        WHEN 'pneumatic_pick' THEN v_tool_power := 5;
        WHEN 'ground_radar' THEN v_tool_power := 25;
        WHEN 'industrial_drill' THEN v_tool_power := 100;
        ELSE v_tool_power := 0;
    END CASE;

    IF v_tool_power = 0 THEN RETURN jsonb_build_object('success', false, 'error', 'No passive power'); END IF;

    v_excavation_level := public.get_level(v_profile.excavation_xp);
    v_level_bonus := floor(v_excavation_level / 5) * 0.005;
    
    v_roll := random();
    IF v_roll < (v_base_rate + v_level_bonus) AND v_profile.tray_count < 5 THEN
        v_crate_dropped := TRUE;
        v_new_crate := jsonb_build_object('id', gen_random_uuid(), 'appraised', false, 'contents', public.rpc_helper_roll_crate());
        
        UPDATE public.profiles 
        SET 
            tray_count = tray_count + 1,
            crate_tray = crate_tray || v_new_crate
        WHERE id = v_user_id;
    END IF;

    RETURN jsonb_build_object(
        'success', true, 
        'crate_dropped', v_crate_dropped, 
        'new_balance', v_profile.scrap_balance,
        'new_tray_count', (SELECT tray_count FROM public.profiles WHERE id = v_user_id)
    );
END;
$$;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;
NOTIFY pgrst, 'reload schema';
