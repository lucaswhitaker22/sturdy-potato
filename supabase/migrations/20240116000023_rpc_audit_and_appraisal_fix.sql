-- 20240116000023_rpc_audit_and_appraisal_fix.sql

-- 1. Update Helper: Roll Crate Contents to include current mint info for intel
CREATE OR REPLACE FUNCTION public.rpc_helper_roll_crate()
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    v_condition item_condition;
    v_is_prismatic BOOLEAN := FALSE;
    v_roll FLOAT;
    v_items_by_tier JSONB := '{}'::JSONB;
    v_mint_numbers JSONB := '{}'::JSONB;
    v_tier item_tier;
    v_item_id UUID;
    v_mint_num BIGINT;
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

    -- 3. Pre-pick items for each possible tier and their current mint status
    FOR v_tier IN SELECT unnest(enum_range(NULL::item_tier)) LOOP
        SELECT id INTO v_item_id FROM public.item_definitions WHERE tier = v_tier ORDER BY random() LIMIT 1;
        
        -- Peek at next mint number
        SELECT COALESCE(next_mint_number, 1) INTO v_mint_num FROM public.item_mints WHERE item_id = v_item_id;
        
        v_items_by_tier := v_items_by_tier || jsonb_build_object(v_tier::TEXT, v_item_id);
        v_mint_numbers := v_mint_numbers || jsonb_build_object(v_tier::TEXT, v_mint_num);
    END LOOP;

    RETURN jsonb_build_object(
        'condition', v_condition,
        'is_prismatic', v_is_prismatic,
        'items_by_tier', v_items_by_tier,
        'mint_numbers', v_mint_numbers
    );
END;
$$;

-- 2. Restore full logic to Extraction (v5)
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
    v_grades TEXT[];
    v_grade TEXT;
    v_perfect_count INT := 0;
    v_hit_count INT := 0;

    -- Crate Vars
    v_new_crate JSONB;
BEGIN
    p_user_id := (payload->>'p_user_id')::UUID;
    p_seismic_grade := payload->>'p_seismic_grade';
    v_user_id := public.get_auth_user(p_user_id);

    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;

    -- Ensure profile exists and has crate_tray
    INSERT INTO public.profiles (id, scrap_balance, tray_count, crate_tray)
    VALUES (v_user_id, 0, 0, '[]'::JSONB)
    ON CONFLICT (id) DO NOTHING;

    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    
    -- Sync tray_count if it's out of sync with crate_tray length
    IF jsonb_array_length(COALESCE(v_profile.crate_tray, '[]'::JSONB)) != COALESCE(v_profile.tray_count, 0) THEN
        v_profile.tray_count := jsonb_array_length(COALESCE(v_profile.crate_tray, '[]'::JSONB));
    END IF;

    -- Buffs (Sets)
    IF EXISTS (SELECT 1 FROM public.completed_sets WHERE user_id = v_user_id AND set_id = 'morning_ritual') THEN
        v_cooldown_sec := v_cooldown_sec - 0.5;
    END IF;

    -- Cooldown check
    IF v_profile.last_extract_at IS NOT NULL AND v_profile.last_extract_at > NOW() - (v_cooldown_sec || ' seconds')::INTERVAL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Cooldown active');
    END IF;

    v_excavation_level := public.get_level(COALESCE(v_profile.excavation_xp, 0));
    
    -- Mastery Perk: "The Endless Vein" (15% Double Loot)
    IF v_excavation_level >= 99 AND random() < 0.15 THEN
        v_double_loot := TRUE;
    END IF;

    -- Seismic Bonuses
    IF p_seismic_grade IS NOT NULL THEN
        v_grades := string_to_array(p_seismic_grade, ',');
        FOREACH v_grade IN ARRAY v_grades LOOP
            IF v_grade = 'PERFECT' THEN v_perfect_count := v_perfect_count + 1;
            ELSIF v_grade = 'HIT' THEN v_hit_count := v_hit_count + 1;
            END IF;
        END LOOP;
        
        IF v_perfect_count >= 2 THEN v_seismic_crate_bonus := 0.08; v_seismic_xp_bonus_percent := 0.25;
        ELSIF v_perfect_count >= 1 THEN v_seismic_crate_bonus := 0.05; v_seismic_xp_bonus_percent := 0.25;
        ELSIF v_hit_count >= 1 THEN v_seismic_crate_bonus := 0.02; v_seismic_xp_bonus_percent := 0.10;
        END IF;
    END IF;

    -- Roll
    v_bonus_rate := floor(v_excavation_level / 5.0) * 0.005;
    v_roll := random();
    
    IF v_roll < (v_base_crate_rate + v_bonus_rate + v_seismic_crate_bonus) AND COALESCE(v_profile.tray_count, 0) < 5 THEN
        v_crate_dropped := TRUE;
        v_result := 'CRATE_FOUND';
        v_xp_gain := 25;
        v_new_crate := jsonb_build_object('id', gen_random_uuid(), 'appraised', false, 'contents', public.rpc_helper_roll_crate());
        
        -- Anomaly Check
        IF random() < v_anomaly_rate THEN
            v_anomaly_happened := TRUE;
            v_result := 'ANOMALY';
            v_xp_gain := 50;
        END IF;
    ELSE
        -- Fixed range for Scrap Found
        v_scrap_gain := (floor(random() * 11) + 5)::INT; -- 5-15 scrap
        v_result := 'SCRAP_FOUND';
        v_xp_gain := 5;
    END IF;

    -- Apply Double Loot
    IF v_double_loot THEN
        v_scrap_gain := v_scrap_gain * 2;
        -- Double crate if space
        -- (Complex if tray fills up, we'll just stick to double scrap for now to keep it safe)
    END IF;

    -- Apply Seismic XP Bonus
    IF v_seismic_xp_bonus_percent > 0 THEN
        v_xp_gain := floor(v_xp_gain * (1 + v_seismic_xp_bonus_percent))::INT;
    END IF;

    -- Update Profile
    UPDATE public.profiles
    SET 
        scrap_balance = COALESCE(scrap_balance, 0) + v_scrap_gain,
        excavation_xp = COALESCE(excavation_xp, 0) + v_xp_gain,
        tray_count = CASE WHEN v_crate_dropped THEN tray_count + 1 ELSE tray_count END,
        crate_tray = CASE WHEN v_crate_dropped THEN COALESCE(crate_tray, '[]'::JSONB) || v_new_crate ELSE crate_tray END,
        last_extract_at = NOW(),
        updated_at = NOW()
    WHERE id = v_user_id
    RETURNING scrap_balance, excavation_xp, tray_count INTO v_final_balance, v_final_xp, v_final_tray_count;

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
        'new_tray_count', v_final_tray_count,
        'crate_tray', (SELECT crate_tray FROM public.profiles WHERE id = v_user_id)
    );
END;
$$;

-- 3. Enhance Appraisal RPC
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
    v_tier item_tier;
    v_item_def RECORD;
    v_condition_mult FLOAT;
    v_prismatic_mult FLOAT := 1.0;
    v_mint_mult FLOAT := 1.0;
    v_approx_hv INT;
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;

    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    v_appraisal_level := public.get_level(COALESCE(v_profile.appraisal_xp, 0));
    
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
                
                -- Lvl 0+: Show Tier potential (Energy Signature)
                -- Determine currently possible highest tier (Stage 0 = Common)
                v_intel := v_intel || jsonb_build_object('type', 'tier_potential', 'label', 'Energy Signature', 'value', 'COMMON [BASE]');
                
                -- Lvl 20+: Show Condition
                IF v_appraisal_level >= 20 THEN
                    v_intel := v_intel || jsonb_build_object('type', 'condition', 'label', 'Structural Integrity', 'value', v_contents->>'condition');
                END IF;

                -- Lvl 50+: Show Prismatic
                IF v_appraisal_level >= 50 THEN
                    v_intel := v_intel || jsonb_build_object('type', 'is_prismatic', 'label', 'Prismatic Resonance', 'value', (v_contents->>'is_prismatic')::BOOLEAN);
                END IF;

                -- Lvl 80+: Mint Band (Low Mint status)
                IF v_appraisal_level >= 80 THEN
                    -- Check common tier item mint number (as a representative)
                    IF (v_contents->'mint_numbers'->>'common')::INT <= 10 THEN
                        v_intel := v_intel || jsonb_build_object('type', 'mint_band', 'label', 'Historical Depth', 'value', 'ARCHIVAL (TOP 10)');
                    ELSE
                        v_intel := v_intel || jsonb_build_object('type', 'mint_band', 'label', 'Historical Depth', 'value', 'RECOVERY (STANDARD)');
                    END IF;
                END IF;

                -- Lvl 99: Exact HV (The Oracle)
                -- We'll reveal the HV for the item at Stage 0 (Common)
                IF v_appraisal_level >= 99 THEN
                    SELECT * INTO v_item_def FROM public.item_definitions WHERE id = (v_contents->'items_by_tier'->>'common')::UUID;
                    
                    IF v_item_def IS NOT NULL THEN
                        -- Calculate exact HV using rolls
                        IF (v_contents->>'is_prismatic')::BOOLEAN THEN v_prismatic_mult := 3.0; END IF;
                        CASE v_contents->>'condition'
                            WHEN 'mint' THEN v_condition_mult := 2.5;
                            WHEN 'preserved' THEN v_condition_mult := 1.5;
                            WHEN 'weathered' THEN v_condition_mult := 1.0;
                            ELSE v_condition_mult := 0.5;
                        END CASE;
                        
                        IF (v_contents->'mint_numbers'->>'common')::INT <= 10 THEN v_mint_mult := 1.5; END IF;
                        
                        v_approx_hv := floor(v_item_def.base_hv * v_condition_mult * v_prismatic_mult * v_mint_mult)::INT;
                        v_intel := v_intel || jsonb_build_object('type', 'exact_hv', 'label', 'Economic Valuation', 'value', v_approx_hv || ' HV');
                    END IF;
                END IF;
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
