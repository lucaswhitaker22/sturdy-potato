-- 20240116000025_force_remaining_columns.sql
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS appraisal_xp BIGINT DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS fine_dust_balance BIGINT DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS smelting_xp BIGINT DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS historical_influence BIGINT DEFAULT 0;

-- Ensure RLS is permissive for local testing as previously discussed
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public access" ON public.profiles;
CREATE POLICY "Public access" ON public.profiles FOR ALL USING (true) WITH CHECK (true);

-- Reload schema cache
NOTIFY pgrst, 'reload schema';
