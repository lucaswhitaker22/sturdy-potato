-- Robusifying RPC and ensuring row exists
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
    v_cooldown_sec FLOAT := 3.0;
    v_base_crate_rate FLOAT := 0.15;
    v_anomaly_rate FLOAT := 0.05;
    v_bonus_rate FLOAT := 0.0;
    v_excavation_level INT;
    v_anomaly_happened BOOLEAN := FALSE;
    v_final_balance BIGINT;
    v_final_xp BIGINT;
    v_final_tray INT;
BEGIN
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated');
    END IF;

    -- Ensure profile exists or create it
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
    v_excavation_level := coalesce(public.get_level(v_profile.excavation_xp), 1);

    -- Apply Level Bonus
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

    UPDATE public.profiles
    SET 
        scrap_balance = COALESCE(scrap_balance, 0) + v_scrap_gain,
        excavation_xp = COALESCE(excavation_xp, 0) + v_xp_gain,
        tray_count = CASE WHEN v_crate_dropped THEN COALESCE(tray_count, 0) + 1 ELSE COALESCE(tray_count, 0) END,
        last_extract_at = NOW(),
        updated_at = NOW()
    WHERE id = v_user_id
    RETURNING scrap_balance, excavation_xp, tray_count INTO v_final_balance, v_final_xp, v_final_tray;

    IF v_anomaly_happened THEN
        INSERT INTO public.global_events (event_type, user_id, details)
        VALUES ('anomaly', v_user_id, jsonb_build_object('item_id', 'temporal_rift', 'xp_gain', v_xp_gain));
    END IF;

    -- Fallback if RETURNING still fails for some bizarre reason
    IF v_final_balance IS NULL THEN
        v_final_balance := COALESCE(v_profile.scrap_balance, 0) + v_scrap_gain;
        v_final_xp := COALESCE(v_profile.excavation_xp, 0) + v_xp_gain;
        v_final_tray := CASE WHEN v_crate_dropped THEN COALESCE(v_profile.tray_count, 0) + 1 ELSE COALESCE(v_profile.tray_count, 0) END;
    END IF;

    RETURN jsonb_build_object(
        'success', true, 
        'result', v_result, 
        'scrap_gain', v_scrap_gain, 
        'xp_gain', v_xp_gain,
        'crate_dropped', v_crate_dropped,
        'anomaly', v_anomaly_happened,
        'level', v_excavation_level,
        'new_balance', v_final_balance,
        'new_xp', v_final_xp,
        'new_tray_count', v_final_tray
    );
END;
$$;
