-- Fix permissions and allow local-identity fallback

-- 1. Grant usage on schema public
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

-- 2. Grant Table Access for World Events
ALTER TABLE public.world_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read access" ON public.world_events;
CREATE POLICY "Public read access" ON public.world_events FOR SELECT TO public USING (true);

GRANT SELECT ON public.world_events TO anon, authenticated, service_role;

-- 3. Update Passive Tick to accept User ID (for local identity support)
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
BEGIN
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'No user ID provided');
    END IF;

    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;

    IF v_profile IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Profile not found');
    END IF;
    
    CASE v_profile.active_tool_id
        WHEN 'rusty_shovel' THEN v_tool_power := 0;
        WHEN 'pneumatic_pick' THEN v_tool_power := 5;
        WHEN 'ground_radar' THEN v_tool_power := 25;
        WHEN 'industrial_drill' THEN v_tool_power := 100;
        ELSE v_tool_power := 0;
    END CASE;

    IF v_tool_power = 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'No passive power');
    END IF;

    v_excavation_level := public.get_level(v_profile.excavation_xp);
    v_level_bonus := floor(v_excavation_level / 5) * 0.005;
    
    v_roll := random();
    IF v_roll < (v_base_rate + v_level_bonus) AND v_profile.tray_count < 5 THEN
        v_crate_dropped := TRUE;
    END IF;

    UPDATE public.profiles
    SET 
        scrap_balance = scrap_balance + v_tool_power,
        tray_count = CASE WHEN v_crate_dropped THEN tray_count + 1 ELSE tray_count END,
        updated_at = NOW()
    WHERE id = v_user_id;

    RETURN jsonb_build_object(
        'success', true, 
        'scrap_gain', v_tool_power, 
        'crate_dropped', v_crate_dropped,
        'new_balance', v_profile.scrap_balance + v_tool_power
    );
END;
$$;

-- 4. Update Offline Gains to accept User ID
CREATE OR REPLACE FUNCTION public.rpc_handle_offline_gains(p_user_id UUID DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := COALESCE(p_user_id, auth.uid());
    v_profile RECORD;
    v_seconds_offline INT;
    v_cap_seconds INT := 28800; 
    v_tool_power INT := 0;
    v_total_scrap BIGINT;
    v_ticks INT;
BEGIN
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'No user ID provided');
    END IF;

    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;

     IF v_profile IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Profile not found');
    END IF;
    
    IF v_profile.last_logout_at IS NULL THEN
         UPDATE public.profiles SET last_logout_at = NOW() WHERE id = v_user_id;
         RETURN jsonb_build_object('success', true, 'scrap_gain', 0, 'ticks', 0);
    END IF;

    v_seconds_offline := EXTRACT(EPOCH FROM (NOW() - v_profile.last_logout_at));
    
    IF v_seconds_offline < 10 THEN
        UPDATE public.profiles SET last_logout_at = NOW() WHERE id = v_user_id;
        RETURN jsonb_build_object('success', false, 'reason', 'Too short');
    END IF;

    IF v_seconds_offline > v_cap_seconds THEN
        v_seconds_offline := v_cap_seconds;
    END IF;

    v_ticks := floor(v_seconds_offline / 10);
    
    CASE v_profile.active_tool_id
        WHEN 'rusty_shovel' THEN v_tool_power := 0;
        WHEN 'pneumatic_pick' THEN v_tool_power := 5;
        WHEN 'ground_radar' THEN v_tool_power := 25;
        WHEN 'industrial_drill' THEN v_tool_power := 100;
        ELSE v_tool_power := 0;
    END CASE;

    IF v_tool_power = 0 OR v_ticks = 0 THEN
         UPDATE public.profiles SET last_logout_at = NOW() WHERE id = v_user_id;
         RETURN jsonb_build_object('success', true, 'scrap_gain', 0, 'ticks', 0);
    END IF;

    v_total_scrap := v_ticks * v_tool_power;
    
    UPDATE public.profiles 
    SET 
        scrap_balance = scrap_balance + v_total_scrap,
        last_logout_at = NOW()
    WHERE id = v_user_id;

    RETURN jsonb_build_object('success', true, 'scrap_gain', v_total_scrap, 'ticks', v_ticks, 'seconds_offline', v_seconds_offline);
END;
$$;

-- 5. Grant Permissions using blanket grant to cover all signatures
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;
