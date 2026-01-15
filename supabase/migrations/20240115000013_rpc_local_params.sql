-- Supporting Local Identities in RPC Functions
-- This migration updates all game RPCs to accept an optional p_user_id.
-- If p_user_id is provided, it is used instead of auth.uid().
-- This allows guest/local players to have persistent state without Supabase Auth.

-- 1. Helper to determine the user ID
CREATE OR REPLACE FUNCTION public.get_auth_user(p_user_id UUID DEFAULT NULL)
RETURNS UUID AS $$
BEGIN
    RETURN COALESCE(auth.uid(), p_user_id);
END;
$$ LANGUAGE plpgsql STABLE;

-- 2. Update rpc_extract
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

-- 3. Update rpc_upgrade_tool
CREATE OR REPLACE FUNCTION public.rpc_upgrade_tool(p_tool_id TEXT, p_cost INT, p_user_id UUID DEFAULT NULL)
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
    
    IF COALESCE(v_profile.scrap_balance, 0) < p_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient scrap');
    END IF;

    SELECT level INTO v_current_level FROM public.owned_tools WHERE user_id = v_user_id AND tool_id = p_tool_id;
    
    IF v_current_level IS NULL THEN
        INSERT INTO public.owned_tools (user_id, tool_id, level) VALUES (v_user_id, p_tool_id, 1);
    ELSE
        UPDATE public.owned_tools SET level = level + 1 WHERE user_id = v_user_id AND tool_id = p_tool_id;
    END IF;

    UPDATE public.profiles 
    SET scrap_balance = COALESCE(scrap_balance, 0) - p_cost, active_tool_id = p_tool_id, updated_at = NOW()
    WHERE id = v_user_id;

    RETURN jsonb_build_object('success', true, 'active_tool_id', p_tool_id, 'new_level', coalesce(v_current_level + 1, 1));
END;
$$;

-- 4. Update rpc_start_sifting
CREATE OR REPLACE FUNCTION public.rpc_start_sifting(p_user_id UUID DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := public.get_auth_user(p_user_id);
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;
    
    UPDATE public.lab_state SET is_active = TRUE, current_stage = 0, last_action_at = NOW() WHERE user_id = v_user_id;
    
    IF NOT FOUND THEN
        INSERT INTO public.lab_state (user_id, is_active, current_stage) VALUES (v_user_id, TRUE, 0);
    END IF;

    RETURN jsonb_build_object('success', true);
END;
$$;
