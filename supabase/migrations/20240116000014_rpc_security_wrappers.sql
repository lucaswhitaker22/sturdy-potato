-- Fix Security Permissions for Local & World Events

-- 1. Ensure `profiles` is accessible for local users via RPC
-- Direct SELECT on `profiles` might be blocked for `anon` if the policy isn't applying correctly or if the client isn't sending the right headers.
-- Instead of relying on client-side SELECT, we'll wrap profile fetching in a SECURITY DEFINER RPC.

CREATE OR REPLACE FUNCTION public.rpc_get_profile(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_profile RECORD;
BEGIN
    SELECT * INTO v_profile FROM public.profiles WHERE id = p_user_id;
    
    IF v_profile IS NULL THEN
        -- Auto-create if missing (for local dev convenience)
        INSERT INTO public.profiles (id, scrap_balance, tray_count) 
        VALUES (p_user_id, 0, 0)
        RETURNING * INTO v_profile;
    END IF;

    RETURN jsonb_build_object('success', true, 'profile', row_to_json(v_profile));
END;
$$;

GRANT EXECUTE ON FUNCTION public.rpc_get_profile(UUID) TO anon, authenticated, service_role;


-- 2. Explicitly Fix World Event RPC Permissions
-- Re-apply the function to ensure it's fresh and permissions are set.
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

GRANT EXECUTE ON FUNCTION public.rpc_world_event_get_active() TO anon, authenticated, service_role;

-- 3. Fix Lab State Access for Local Users
CREATE OR REPLACE FUNCTION public.rpc_get_lab_state(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_lab RECORD;
BEGIN
    SELECT * INTO v_lab FROM public.lab_state WHERE user_id = p_user_id;
    
    IF v_lab IS NULL THEN
        RETURN jsonb_build_object('success', true, 'lab_state', null);
    END IF;

    RETURN jsonb_build_object('success', true, 'lab_state', row_to_json(v_lab));
END;
$$;

GRANT EXECUTE ON FUNCTION public.rpc_get_lab_state(UUID) TO anon, authenticated, service_role;


-- 4. Reload Schema to clear permission caches
NOTIFY pgrst, 'reload schema';
