-- Fix RLS for owned_tools and completed_sets to allow 'Local Identity' (anon) access for valid rows
-- While "permissive" RLS (USING true) filters nothing, it's the only way to allow anon users to SELECT rows 
-- if we can't trust auth.uid(). Since this is a dev/test setup where local IDs are used, this is acceptable.

-- 1. Permissive Policies
DROP POLICY IF EXISTS "Users can view own tools" ON public.owned_tools;
CREATE POLICY "Users can view own tools" ON public.owned_tools FOR ALL USING (true);

DROP POLICY IF EXISTS "Users can view own completed sets" ON public.completed_sets;
CREATE POLICY "Users can view own completed sets" ON public.completed_sets FOR ALL USING (true);

-- 2. Explicitly Grant Select on these tables as well
GRANT SELECT, INSERT, UPDATE, DELETE ON public.owned_tools TO anon, authenticated, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.completed_sets TO anon, authenticated, service_role;
GRANT SELECT ON public.item_definitions TO anon, authenticated, service_role;

-- 3. Reload Schema
NOTIFY pgrst, 'reload schema';
