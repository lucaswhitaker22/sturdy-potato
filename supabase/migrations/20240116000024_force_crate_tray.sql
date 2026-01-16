-- 20240116000024_force_crate_tray.sql
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS crate_tray JSONB DEFAULT '[]'::JSONB;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS tray_count INT DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS appraisal_xp BIGINT DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS fine_dust_balance BIGINT DEFAULT 0;
ALTER TABLE public.lab_state ADD COLUMN IF NOT EXISTS active_crate JSONB;

-- Reload schema cache
NOTIFY pgrst, 'reload schema';
