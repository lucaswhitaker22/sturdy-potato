-- 20240116000012_cleanup_final.sql
-- Removes experimental functions and ensures rpc_extract is consistent.

DROP FUNCTION IF EXISTS public.rpc_extract_json(JSONB);
DROP FUNCTION IF EXISTS public.rpc_extract_seismic(UUID, TEXT);
DROP FUNCTION IF EXISTS public.rpc_extract_v2(UUID, TEXT);
DROP FUNCTION IF EXISTS public.rpc_extract_v3(UUID, TEXT);

-- Ensure rpc_extract exists and has correct permissions
GRANT EXECUTE ON FUNCTION public.rpc_extract(UUID, TEXT) TO service_role, authenticated, anon;
NOTIFY pgrst, 'reload schema';
