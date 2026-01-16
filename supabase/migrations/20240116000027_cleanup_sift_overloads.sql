-- Resolve rpc_sift ambiguity by dropping old overloads
DROP FUNCTION IF EXISTS public.rpc_sift();
DROP FUNCTION IF EXISTS public.rpc_sift(UUID);

-- Explicitly notify PostgREST
NOTIFY pgrst, 'reload schema';
