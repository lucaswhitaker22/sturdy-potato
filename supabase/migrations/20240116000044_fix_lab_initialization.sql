-- 20240116000044_fix_lab_initialization.sql

-- 1. Fix rpc_extract_v6 to include crate contents (ported from reverted migration 43)
CREATE OR REPLACE FUNCTION public.rpc_extract_v6(payload JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id UUID := (payload->>'p_user_id')::UUID;
    p_seismic_grade TEXT := payload->>'p_seismic_grade';
    v_user_id UUID := public.get_auth_user(p_user_id);
    v_profile RECORD;
    v_roll FLOAT;
    v_result TEXT;
    v_scrap_gain INT := 0;
    v_xp_gain INT := 0;
    v_crate_dropped BOOLEAN := FALSE;
    v_base_crate_rate FLOAT := 0.15;
    v_bonus_rate FLOAT := 0.0;
    v_excavation_level INT;
    v_anomaly_rate FLOAT := 0.05;
    v_anomaly_happened BOOLEAN := FALSE;
    
    -- Expansion logic
    v_static FLOAT;
    v_zone_crate_bonus FLOAT := 0;
    v_focused_survey_bonus FLOAT := 0;
    v_double_loot BOOLEAN := FALSE;
    
    -- Seismic grades
    v_grades TEXT[];
    v_grade TEXT;
    v_perfect_count INT := 0;
    v_hit_count INT := 0;

    -- Final values
    v_final_balance BIGINT;
    v_final_xp BIGINT;
    v_final_tray_count INT;
    v_final_crate_tray JSONB;
    
    -- New Crate logic
    v_new_crate JSONB;
BEGIN
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated');
    END IF;

    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    
    -- 1. CALCULATE BONUSES
    v_excavation_level := public.get_level(COALESCE(v_profile.excavation_xp, 0));
    
    -- Zone Bonus
    v_static := public.get_zone_static(COALESCE(v_profile.active_zone_id, 'industrial_zone'));
    v_zone_crate_bonus := v_static * 0.02;
    
    -- Focused Survey Bonus
    IF v_profile.is_focused_survey_active THEN
        v_focused_survey_bonus := 0.20;
        v_scrap_gain := v_scrap_gain - 10;
    END IF;

    -- Level Bonus
    v_bonus_rate := floor(v_excavation_level / 5) * 0.005;

    -- Seismic Grading
    IF p_seismic_grade IS NOT NULL THEN
        v_grades := string_to_array(p_seismic_grade, ',');
        FOREACH v_grade IN ARRAY v_grades LOOP
            IF v_grade = 'PERFECT' THEN v_perfect_count := v_perfect_count + 1;
            ELSIF v_grade = 'HIT' THEN v_hit_count := v_hit_count + 1;
            END IF;
        END LOOP;
    END IF;

    -- 2. DOUBLE LOOT LOGIC
    IF v_excavation_level >= 99 AND random() < 0.15 THEN
        v_double_loot := TRUE;
    END IF;
    IF v_perfect_count >= 2 THEN
        v_double_loot := TRUE;
        v_xp_gain := v_xp_gain + 50; 
    END IF;

    -- 3. ROLL
    v_roll := random();
    IF v_roll < v_anomaly_rate THEN
        v_result := 'ANOMALY';
        v_anomaly_happened := TRUE;
        v_xp_gain := v_xp_gain + 25;
    ELSIF v_roll < (v_anomaly_rate + v_base_crate_rate + v_bonus_rate + v_zone_crate_bonus + v_focused_survey_bonus) AND v_profile.tray_count < 5 THEN
        v_crate_dropped := TRUE;
        v_result := 'CRATE_FOUND';
        v_xp_gain := v_xp_gain + 15;
    ELSE
        v_scrap_gain := v_scrap_gain + floor(random() * 11 + 5)::INT;
        v_result := 'SCRAP_FOUND';
        v_xp_gain := v_xp_gain + 5;
    END IF;

    -- Double Loot application
    IF v_double_loot THEN
        v_scrap_gain := v_scrap_gain * 2;
    END IF;

    -- 4. UPDATE PROFILE
    -- Create crate object if dropped
    IF v_crate_dropped THEN
        v_new_crate := jsonb_build_object(
            'id', gen_random_uuid(),
            'rarity', 'COMMON',
            'origin_zone', COALESCE(v_profile.active_zone_id, 'industrial_zone'),
            'static_heat', v_static,
            'found_at', NOW(),
            -- IMPORTANT: Add contents for appraisal system!
            'appraised', false,
            'contents', public.rpc_helper_roll_crate() 
        );
    END IF;

    UPDATE public.profiles
    SET 
        scrap_balance = scrap_balance + v_scrap_gain,
        excavation_xp = excavation_xp + v_xp_gain,
        tray_count = CASE 
            WHEN v_crate_dropped AND v_double_loot AND tray_count < 4 THEN tray_count + 2
            WHEN v_crate_dropped THEN tray_count + 1
            ELSE tray_count
        END,
        crate_tray = CASE 
            WHEN v_crate_dropped AND v_double_loot AND tray_count < 4 THEN COALESCE(crate_tray, '[]'::JSONB) || v_new_crate || v_new_crate
            WHEN v_crate_dropped THEN COALESCE(crate_tray, '[]'::JSONB) || v_new_crate
            ELSE crate_tray
        END,
        last_extract_at = NOW()
    WHERE id = v_user_id
    RETURNING scrap_balance, excavation_xp, tray_count, crate_tray 
    INTO v_final_balance, v_final_xp, v_final_tray_count, v_final_crate_tray;

    RETURN jsonb_build_object(
        'success', true,
        'result', v_result,
        'scrap_gain', v_scrap_gain,
        'xp_gain', v_xp_gain,
        'crate_dropped', v_crate_dropped,
        'double_loot', v_double_loot,
        'anomaly', v_anomaly_happened,
        'new_balance', v_final_balance,
        'new_xp', v_final_xp,
        'new_tray_count', v_final_tray_count,
        'crate_tray', v_final_crate_tray
    );
END;
$$;


-- 2. Fix rpc_start_sifting to handle missing lab_state rows via UPSERT
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
            
            -- UPSERT into lab_state to ensure row exists
            INSERT INTO public.lab_state (user_id, is_active, current_stage, last_action_at, active_crate)
            VALUES (v_user_id, TRUE, 0, NOW(), v_crate)
            ON CONFLICT (user_id) DO UPDATE 
            SET is_active = TRUE, current_stage = 0, last_action_at = NOW(), active_crate = EXCLUDED.active_crate;

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

GRANT EXECUTE ON FUNCTION public.rpc_start_sifting(JSONB) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.rpc_extract_v6(JSONB) TO anon, authenticated, service_role;

NOTIFY pgrst, 'reload schema';
