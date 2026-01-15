-- Phase 2 Extension: Tool Levels, Overclocking, and Precise Probabilities

-- 1. Add level to owned_tools
ALTER TABLE public.owned_tools 
ADD COLUMN IF NOT EXISTS level INT DEFAULT 1;

-- 2. Update rpc_extract for 80/15/5 breakdown and Anomalies
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
BEGIN
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    
    -- Check for buffs (Sets)
    IF EXISTS (
        SELECT 1 FROM public.completed_sets 
        WHERE user_id = v_user_id AND set_id = 'morning_ritual'
    ) THEN
        v_cooldown_sec := v_cooldown_sec - 0.5;
    END IF;

    -- Check cooldown
    IF v_profile.last_extract_at > NOW() - (v_cooldown_sec || ' seconds')::INTERVAL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Cooldown active');
    END IF;

    -- Calculate Excavation Level
    v_excavation_level := public.get_level(v_profile.excavation_xp);

    -- Apply Level Bonus: +0.5% per 5 levels to crate rate
    v_bonus_rate := floor(v_excavation_level / 5) * 0.005;
    
    -- Roll
    v_roll := random();
    
    -- 5% Anomaly (R2.1 output)
    IF v_roll < v_anomaly_rate THEN
        v_result := 'ANOMALY';
        v_xp_gain := 25;
        v_anomaly_happened := TRUE;
    -- 15% Crate (R2.1 output) + level bonus
    ELSIF v_roll < (v_anomaly_rate + v_base_crate_rate + v_bonus_rate) AND v_profile.tray_count < 5 THEN
        v_crate_dropped := TRUE;
        v_result := 'CRATE_FOUND';
        v_xp_gain := 15;
    -- 80% Scrap (R2.1 output) - this covers the rest
    ELSE
        -- 80% chance for scrap is roughly everything else since 5+15=20.
        v_scrap_gain := floor(random() * (15 - 5 + 1) + 5)::INT;
        v_result := 'SCRAP_FOUND';
        v_xp_gain := 5;
    END IF;

    UPDATE public.profiles
    SET 
        scrap_balance = scrap_balance + v_scrap_gain,
        excavation_xp = excavation_xp + v_xp_gain,
        tray_count = CASE WHEN v_crate_dropped THEN tray_count + 1 ELSE tray_count END,
        last_extract_at = NOW(),
        updated_at = NOW()
    WHERE id = v_user_id;

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
        'new_balance', v_profile.scrap_balance + v_scrap_gain,
        'new_xp', v_profile.excavation_xp + v_xp_gain,
        'new_tray_count', CASE WHEN v_crate_dropped THEN v_profile.tray_count + 1 ELSE v_profile.tray_count END
    );
END;
$$;

-- 3. Update rpc_upgrade_tool to handle leveling
CREATE OR REPLACE FUNCTION public.rpc_upgrade_tool(p_tool_id TEXT, p_cost INT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_profile RECORD;
    v_current_level INT;
BEGIN
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    
    IF v_profile.scrap_balance < p_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient scrap');
    END IF;

    -- Get current level
    SELECT level INTO v_current_level FROM public.owned_tools WHERE user_id = v_user_id AND tool_id = p_tool_id;
    
    IF v_current_level IS NULL THEN
        -- Purchase new tool
        INSERT INTO public.owned_tools (user_id, tool_id, level) 
        VALUES (v_user_id, p_tool_id, 1);
    ELSE
        -- Upgrade existing tool
        UPDATE public.owned_tools SET level = level + 1 WHERE user_id = v_user_id AND tool_id = p_tool_id;
    END IF;

    UPDATE public.profiles 
    SET scrap_balance = scrap_balance - p_cost, active_tool_id = p_tool_id, updated_at = NOW()
    WHERE id = v_user_id;

    RETURN jsonb_build_object('success', true, 'active_tool_id', p_tool_id, 'new_level', coalesce(v_current_level + 1, 1));
END;
$$;

-- 4. Update rpc_overclock_tool to reset level
CREATE OR REPLACE FUNCTION public.rpc_overclock_tool(p_tool_id TEXT, p_cost INT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_profile RECORD;
    v_current_level INT;
BEGIN
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    
    -- Verify tool level
    SELECT level INTO v_current_level FROM public.owned_tools WHERE user_id = v_user_id AND tool_id = p_tool_id;
    
    IF v_current_level < 10 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Tool must be Level 10 for Overclocking');
    END IF;

    IF v_profile.scrap_balance < p_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient scrap');
    END IF;

    -- Reset tool level to 1
    UPDATE public.owned_tools SET level = 1 WHERE user_id = v_user_id AND tool_id = p_tool_id;
    
    -- Apply Overclock bonus
    UPDATE public.profiles 
    SET overclock_bonus = overclock_bonus + 0.05,
        scrap_balance = scrap_balance - p_cost,
        updated_at = NOW()
    WHERE id = v_user_id;

    RETURN jsonb_build_object('success', true, 'new_bonus', (SELECT overclock_bonus FROM public.profiles WHERE id = v_user_id));
END;
$$;
