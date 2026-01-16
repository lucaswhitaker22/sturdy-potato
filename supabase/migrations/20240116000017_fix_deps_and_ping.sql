-- Fix Dependency Permissions and Add debug ping

-- 1. Helper Security
-- Ensure get_auth_user is accessible.
-- It's a helper function (not SECURITY DEFINER initially in step 164 output, but STABLE).
-- If it's called by a SECURITY DEFINER function, it runs as the owner of THAT function.
-- But if it's called directly or in a chain where ownership is unclear...
-- Best to just Grant Execute on it too.
GRANT EXECUTE ON FUNCTION public.get_auth_user(UUID) TO anon, authenticated, service_role;

-- 2. Debug Ping
-- This function proves if anon can call *any* RPC.
CREATE OR REPLACE FUNCTION public.rpc_ping()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN jsonb_build_object('success', true, 'message', 'pong', 'user', auth.uid());
END;
$$;

GRANT EXECUTE ON FUNCTION public.rpc_ping() TO anon, authenticated, service_role;

-- 3. Fix rpc_extract access to get_level
-- rpc_extract calls public.get_level(xp).
-- Ensure get_level is executable.
GRANT EXECUTE ON FUNCTION public.get_level(BIGINT) TO anon, authenticated, service_role;

-- 4. Re-grant on everything to be absolutely safe
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;

-- 5. Notify
NOTIFY pgrst, 'reload schema';
