-- 20240116000020_rpc_extract_v5.sql
-- Create a fresh function name to bypass any sticky schema cache issues

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
    v_final_tray INT;
    -- Mastery Vars
    v_double_loot BOOLEAN := FALSE;
    
    -- Seismic Vars
    v_seismic_crate_bonus FLOAT := 0.0;
    v_seismic_xp_bonus_percent FLOAT := 0.0;
    v_grades TEXT[];
    v_grade TEXT;
    v_perfect_count INT := 0;
    v_hit_count INT := 0;
BEGIN
    -- Extract params from JSON payload
    p_user_id := (payload->>'p_user_id')::UUID;
    p_seismic_grade := payload->>'p_seismic_grade';

    v_user_id := public.get_auth_user(p_user_id);

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

    -- Calculate Seismic Bonuses
    IF p_seismic_grade IS NOT NULL THEN
        v_grades := string_to_array(p_seismic_grade, ',');
        FOREACH v_grade IN ARRAY v_grades
        LOOP
            IF v_grade = 'PERFECT' THEN
                v_perfect_count := v_perfect_count + 1;
            ELSIF v_grade = 'HIT' THEN
                v_hit_count := v_hit_count + 1;
            END IF;
        END LOOP;
        
        IF v_perfect_count >= 2 THEN
            -- Double Perfect (Level 99)
            v_seismic_crate_bonus := 0.08; -- +8%
            v_seismic_xp_bonus_percent := 0.25; -- +25%
        ELSIF v_perfect_count >= 1 THEN
            -- Single Perfect
            v_seismic_crate_bonus := 0.05; -- +5%
            v_seismic_xp_bonus_percent := 0.25; -- +25%
        ELSIF v_hit_count >= 1 THEN
            -- Single Hit
            v_seismic_crate_bonus := 0.02; -- +2%
            v_seismic_xp_bonus_percent := 0.10; -- +10%
        END IF;
    END IF;

    -- Roll for Crate
    v_roll := random();
    -- Add 0.5% bonus for every 5 levels
    v_bonus_rate := floor(v_excavation_level / 5.0) * 0.005;
    
    IF v_roll < (v_base_crate_rate + v_bonus_rate + v_seismic_crate_bonus) THEN
        v_crate_dropped := TRUE;
        v_result := 'CRATE_FOUND';
        v_xp_gain := 25;
        
        -- Check for Anomaly
        IF random() < v_anomaly_rate THEN
            v_anomaly_happened := TRUE;
            v_result := 'ANOMALY';
            v_xp_gain := 50;
        END IF;
    ELSE
        v_scrap_gain := (floor(random() * 5) + 1 + 5)::INT;
        v_result := 'SCRAP_FOUND';
        v_xp_gain := 5;
    END IF;

    -- Apply Seismic XP Bonus
    IF v_seismic_xp_bonus_percent > 0 THEN
        IF v_seismic_xp_bonus_percent > 0 AND floor(v_xp_gain * v_seismic_xp_bonus_percent) < 1 THEN
            v_xp_gain := v_xp_gain + 1;
        ELSE
             v_xp_gain := floor(v_xp_gain * (1 + v_seismic_xp_bonus_percent))::INT;
        END IF;
    END IF;

    -- Apply Double Loot
    IF v_double_loot THEN
        v_scrap_gain := v_scrap_gain * 2;
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
        'seismic_bonus', v_seismic_crate_bonus,
        'new_balance', v_final_balance,
        'new_xp', v_final_xp,
        'new_tray_count', v_final_tray
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.rpc_extract_v5(JSONB) TO service_role, authenticated, anon;
NOTIFY pgrst, 'reload schema';
