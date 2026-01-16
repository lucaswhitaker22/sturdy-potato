-- Force PostgREST to reload the schema cache and ensure all permissions are set.
-- This helps if the cache is stale after migrations.

ALTER TABLE public.profiles REPLICA IDENTITY FULL; -- Minor change to trigger table-level refresh if needed

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;

NOTIFY pgrst, 'reload schema';
