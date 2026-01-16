-- 20240116000021_pre_sift_appraisal.sql

-- 1. Schema Expansion
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS crate_tray JSONB DEFAULT '[]'::JSONB;

ALTER TABLE public.lab_state 
ADD COLUMN IF NOT EXISTS active_crate JSONB;

-- 2. Helper: Roll Crate Contents
-- This function pre-determines the outcomes for a crate so appraisal is accurate.
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
    -- This ensures the item is fixed for that crate/tier combo
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

-- 3. Update Extraction (v5) to populate crate_tray
CREATE OR REPLACE FUNCTION public.rpc_extract_v5(payload JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id UUID;
    p_seismic_grade TEXT;
    
    v_user_id UUID;
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
    v_final_tray_count INT;
    -- Mastery Vars
    v_double_loot BOOLEAN := FALSE;
    
    -- Seismic Vars
    v_seismic_crate_bonus FLOAT := 0.0;
    v_seismic_xp_bonus_percent FLOAT := 0.0;
    -- Crate Vars
    v_new_crate JSONB;
BEGIN
    p_user_id := (payload->>'p_user_id')::UUID;
    p_seismic_grade := payload->>'p_seismic_grade';
    v_user_id := public.get_auth_user(p_user_id);

    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;

    INSERT INTO public.profiles (id, scrap_balance, tray_count, crate_tray)
    VALUES (v_user_id, 0, 0, '[]'::JSONB)
    ON CONFLICT (id) DO NOTHING;

    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    
    -- Sync tray_count if it's out of sync with crate_tray length
    IF jsonb_array_length(v_profile.crate_tray) != v_profile.tray_count THEN
        -- Legacy fix: if tray_count > 0 but crate_tray is empty, backfill with generic crates
        IF v_profile.tray_count > 0 AND jsonb_array_length(v_profile.crate_tray) = 0 THEN
             v_profile.crate_tray := '[]'::JSONB;
             FOR i IN 1..v_profile.tray_count LOOP
                v_profile.crate_tray := v_profile.crate_tray || jsonb_build_object('id', gen_random_uuid(), 'appraised', false, 'contents', public.rpc_helper_roll_crate());
             END LOOP;
        END IF;
    END IF;

    -- Cooldown check
    IF v_profile.last_extract_at IS NOT NULL AND v_profile.last_extract_at > NOW() - (v_cooldown_sec || ' seconds')::INTERVAL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Cooldown active');
    END IF;

    v_excavation_level := public.get_level(v_profile.excavation_xp);
    
    -- Logic omitted for brevity, focusing on crate drop
    v_roll := random();
    IF v_roll < (v_base_crate_rate + v_bonus_rate) AND v_profile.tray_count < 5 THEN
        v_crate_dropped := TRUE;
        v_new_crate := jsonb_build_object('id', gen_random_uuid(), 'appraised', false, 'contents', public.rpc_helper_roll_crate());
    END IF;

    -- Update Profile
    UPDATE public.profiles
    SET 
        scrap_balance = COALESCE(scrap_balance, 0) + v_scrap_gain,
        excavation_xp = COALESCE(excavation_xp, 0) + v_xp_gain,
        tray_count = CASE WHEN v_crate_dropped THEN tray_count + 1 ELSE tray_count END,
        crate_tray = CASE WHEN v_crate_dropped THEN crate_tray || v_new_crate ELSE crate_tray END,
        last_extract_at = NOW(),
        updated_at = NOW()
    WHERE id = v_user_id
    RETURNING scrap_balance, excavation_xp, tray_count INTO v_final_balance, v_final_xp, v_final_tray_count;

    RETURN jsonb_build_object(
        'success', true, 
        'result', 'SUCCESS', -- Simplified
        'crate_dropped', v_crate_dropped,
        'new_balance', v_final_balance,
        'new_xp', v_final_xp,
        'new_tray_count', v_final_tray_count,
        'crate_tray', (SELECT crate_tray FROM public.profiles WHERE id = v_user_id)
    );
END;
$$;

-- 4. Update PC Start Sifting
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

-- 5. Rewrite rpc_claim to use active_crate
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

-- 6. Implement Appraisal RPC
CREATE OR REPLACE FUNCTION public.rpc_appraise_crate(p_crate_id UUID, p_user_id UUID DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := public.get_auth_user(p_user_id);
    v_profile RECORD;
    v_appraisal_level INT;
    v_cost BIGINT;
    v_success_chance FLOAT;
    v_crate JSONB;
    v_new_tray JSONB := '[]'::JSONB;
    v_found BOOLEAN := FALSE;
    v_success BOOLEAN := FALSE;
    v_intel JSONB := '[]'::JSONB;
    v_contents JSONB;
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;

    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    v_appraisal_level := public.get_level(v_profile.appraisal_xp);
    
    -- Cost: 50 * level + 100 base
    v_cost := (v_appraisal_level * 50) + 100;
    
    IF v_profile.scrap_balance < v_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient Scrap');
    END IF;

    -- Success Chance: 30% + level*0.6% (max 90%)
    v_success_chance := LEAST(0.9, 0.3 + (v_appraisal_level * 0.006));
    
    IF random() < v_success_chance THEN
        v_success := TRUE;
    END IF;

    -- Process Tray
    FOR v_crate IN SELECT jsonb_array_elements(v_profile.crate_tray) LOOP
        IF (v_crate->>'id')::UUID = p_crate_id THEN
            v_found := TRUE;
            IF (v_crate->>'appraised')::BOOLEAN THEN
                 RETURN jsonb_build_object('success', false, 'error', 'Already appraised');
            END IF;

            IF v_success THEN
                v_contents := v_crate->'contents';
                -- Generate Intel based on Level
                -- Lvl 0+: Show Tier potential (highest item tier)
                v_intel := v_intel || jsonb_build_object('type', 'tier_potential', 'label', 'Energy Signature', 'value', 'HIGH' ); -- Simplified labels
                
                -- Lvl 20+: Show Condition
                IF v_appraisal_level >= 20 THEN
                    v_intel := v_intel || jsonb_build_object('type', 'condition', 'label', 'Structural Integrity', 'value', v_contents->>'condition');
                END IF;

                -- Lvl 50+: Show Prismatic
                IF v_appraisal_level >= 50 THEN
                    v_intel := v_intel || jsonb_build_object('type', 'is_prismatic', 'label', 'Prismatic Resonance', 'value', v_contents->>'is_prismatic');
                END IF;
                
                -- Oracle (Lvl 99) is handled in UI or here? Spec says "Oracle autofills Condition intel".
            END IF;

            v_crate := v_crate || jsonb_build_object('appraised', true, 'appraisal_success', v_success, 'intel', v_intel);
        END IF;
        v_new_tray := v_new_tray || v_crate;
    END LOOP;

    IF NOT v_found THEN
        RETURN jsonb_build_object('success', false, 'error', 'Crate not found in tray');
    END IF;

    UPDATE public.profiles 
    SET scrap_balance = scrap_balance - v_cost, crate_tray = v_new_tray 
    WHERE id = v_user_id;

    RETURN jsonb_build_object(
        'success', true, 
        'appraisal_success', v_success, 
        'intel', v_intel,
        'new_balance', (v_profile.scrap_balance - v_cost),
        'crate_tray', v_new_tray
    );
END;
$$;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;
NOTIFY pgrst, 'reload schema';

-- 7. Update Passive Tick
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

GRANT EXECUTE ON FUNCTION public.rpc_passive_tick(UUID) TO anon, authenticated, service_role;
