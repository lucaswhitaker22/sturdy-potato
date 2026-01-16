-- Force Refresh Permissions and Fix Functions
-- Explicitly drop and recreate to ensure clean slate for signatures

-- 1. DROP Existing RPCs (to avoid overload confusion)
DROP FUNCTION IF EXISTS public.rpc_world_event_get_active();
DROP FUNCTION IF EXISTS public.rpc_get_profile(UUID);
DROP FUNCTION IF EXISTS public.rpc_get_lab_state(UUID);

-- 2. Grant Schema Usage (Critical for Anon)
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

-- 3. Recreate rpc_world_event_get_active
CREATE OR REPLACE FUNCTION public.rpc_world_event_get_active()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_event RECORD;
BEGIN
    SELECT * INTO v_event FROM public.world_events WHERE status = 'active' AND ends_at > NOW() LIMIT 1;
    
    IF v_event IS NULL THEN
        RETURN jsonb_build_object('success', true, 'active_event', null);
    END IF;

    RETURN jsonb_build_object('success', true, 'active_event', row_to_json(v_event));
END;
$$;

-- 4. Recreate rpc_get_profile
CREATE OR REPLACE FUNCTION public.rpc_get_profile(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_profile RECORD;
BEGIN
    -- Ensure p_user_id is not null
    IF p_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'User ID is required');
    END IF;

    SELECT * INTO v_profile FROM public.profiles WHERE id = p_user_id;
    
    IF v_profile IS NULL THEN
        -- Auto-create if missing (Safe default for local dev)
        INSERT INTO public.profiles (id, scrap_balance, tray_count) 
        VALUES (p_user_id, 0, 0)
        RETURNING * INTO v_profile;
    END IF;

    RETURN jsonb_build_object('success', true, 'profile', row_to_json(v_profile));
END;
$$;

-- 5. Recreate rpc_get_lab_state
CREATE OR REPLACE FUNCTION public.rpc_get_lab_state(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_lab RECORD;
BEGIN
    IF p_user_id IS NULL THEN
         RETURN jsonb_build_object('success', true, 'lab_state', null);
    END IF;

    SELECT * INTO v_lab FROM public.lab_state WHERE user_id = p_user_id;
    
    IF v_lab IS NULL THEN
        RETURN jsonb_build_object('success', true, 'lab_state', null);
    END IF;

    RETURN jsonb_build_object('success', true, 'lab_state', row_to_json(v_lab));
END;
$$;

-- 6. Grant Execution Explicitly
GRANT EXECUTE ON FUNCTION public.rpc_world_event_get_active() TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.rpc_get_profile(UUID) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.rpc_get_lab_state(UUID) TO anon, authenticated, service_role;

-- 7. Grant Table Access (Just in case RLS on profiles/world_events is still sticky)
GRANT SELECT ON public.world_events TO anon, authenticated, service_role;
GRANT SELECT, INSERT, UPDATE ON public.profiles TO anon, authenticated, service_role;
GRANT SELECT, INSERT, UPDATE ON public.lab_state TO anon, authenticated, service_role;

-- 8. Final Notify
NOTIFY pgrst, 'reload schema';
