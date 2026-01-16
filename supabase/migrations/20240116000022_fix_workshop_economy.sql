-- 20240116000022_fix_workshop_economy.sql

-- 1. Update Passive Tick with level-based scaling and scrap generation
CREATE OR REPLACE FUNCTION public.rpc_passive_tick(p_user_id UUID DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := COALESCE(p_user_id, auth.uid());
    v_profile RECORD;
    v_tool_level INT;
    v_base_power FLOAT := 0;
    v_tool_power INT := 0;
    v_crate_dropped BOOLEAN := FALSE;
    v_excavation_level INT;
    v_roll FLOAT;
    v_base_rate FLOAT := 0.15;
    v_level_bonus FLOAT := 0.0;
    v_new_crate JSONB;
    v_final_balance BIGINT;
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'No user ID'); END IF;

    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    IF v_profile IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Profile not found'); END IF;
    
    -- Get Current Tool Level
    SELECT level INTO v_tool_level FROM public.owned_tools WHERE user_id = v_user_id AND tool_id = v_profile.active_tool_id;
    v_tool_level := COALESCE(v_tool_level, 1);

    -- Base Power per 10s (matching TOOL_CATALOG automationRate * 10)
    CASE v_profile.active_tool_id
        WHEN 'rusty_shovel' THEN v_base_power := 0;
        WHEN 'pneumatic_pick' THEN v_base_power := 5;
        WHEN 'ground_radar' THEN v_base_power := 40;
        WHEN 'industrial_drill' THEN v_base_power := 300;
        WHEN 'seismic_array' THEN v_base_power := 2000;
        WHEN 'satellite_uplink' THEN v_base_power := 12000;
        ELSE v_base_power := 0;
    END CASE;

    IF v_base_power > 0 THEN
        -- Scale by level: base * (1.2 ^ (level-1))
        v_tool_power := floor(v_base_power * POWER(1.2, v_tool_level - 1))::INT;
        
        -- Always update scrap balance in passive tick if power > 0
        UPDATE public.profiles SET scrap_balance = scrap_balance + v_tool_power WHERE id = v_user_id
        RETURNING scrap_balance INTO v_final_balance;
    ELSE
        v_final_balance := v_profile.scrap_balance;
    END IF;

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
        'new_balance', v_final_balance,
        'new_tray_count', (SELECT tray_count FROM public.profiles WHERE id = v_user_id)
    );
END;
$$;

-- 2. Update Offline Gains with Level Scaling
CREATE OR REPLACE FUNCTION public.rpc_handle_offline_gains(p_user_id UUID DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := COALESCE(p_user_id, auth.uid());
    v_profile RECORD;
    v_seconds_offline FLOAT;
    v_ticks INT;
    v_tool_level INT;
    v_base_power FLOAT := 0;
    v_tool_power INT := 0;
    v_total_scrap BIGINT := 0;
    v_cap_seconds INT := 43200; -- 12 hour cap
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'No user ID'); END IF;

    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    IF v_profile IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Profile not found'); END IF;
    
    IF v_profile.last_logout_at IS NULL THEN
         UPDATE public.profiles SET last_logout_at = NOW() WHERE id = v_user_id;
         RETURN jsonb_build_object('success', true, 'scrap_gain', 0, 'ticks', 0);
    END IF;

    v_seconds_offline := EXTRACT(EPOCH FROM (NOW() - v_profile.last_logout_at));
    
    IF v_seconds_offline < 10 THEN
        UPDATE public.profiles SET last_logout_at = NOW() WHERE id = v_user_id;
        RETURN jsonb_build_object('success', false, 'reason', 'Too short');
    END IF;

    IF v_seconds_offline > v_cap_seconds THEN v_seconds_offline := v_cap_seconds; END IF;
    v_ticks := floor(v_seconds_offline / 10);
    
    -- Get Current Tool Level
    SELECT level INTO v_tool_level FROM public.owned_tools WHERE user_id = v_user_id AND tool_id = v_profile.active_tool_id;
    v_tool_level := COALESCE(v_tool_level, 1);

    CASE v_profile.active_tool_id
        WHEN 'rusty_shovel' THEN v_base_power := 0;
        WHEN 'pneumatic_pick' THEN v_base_power := 5;
        WHEN 'ground_radar' THEN v_base_power := 40;
        WHEN 'industrial_drill' THEN v_base_power := 300;
        WHEN 'seismic_array' THEN v_base_power := 2000;
        WHEN 'satellite_uplink' THEN v_base_power := 12000;
        ELSE v_base_power := 0;
    END CASE;

    IF v_base_power > 0 AND v_ticks > 0 THEN
        v_tool_power := floor(v_base_power * POWER(1.2, v_tool_level - 1))::INT;
        -- Offline efficiency penalty: 50%
        v_total_scrap := floor(v_ticks * v_tool_power * 0.5)::BIGINT;
        
        UPDATE public.profiles 
        SET scrap_balance = scrap_balance + v_total_scrap, last_logout_at = NOW()
        WHERE id = v_user_id;

        RETURN jsonb_build_object('success', true, 'scrap_gain', v_total_scrap, 'ticks', v_ticks, 'seconds_offline', v_seconds_offline);
    ELSE
        UPDATE public.profiles SET last_logout_at = NOW() WHERE id = v_user_id;
        RETURN jsonb_build_object('success', true, 'scrap_gain', 0, 'ticks', 0);
    END IF;
END;
$$;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;
NOTIFY pgrst, 'reload schema';
