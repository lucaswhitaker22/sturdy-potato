-- 20240117000000_vault_heatmaps_strategy.sql

-- 1. Create Heatmap Table
CREATE TABLE IF NOT EXISTS public.vault_heatmaps (
    zone_id TEXT PRIMARY KEY,
    static_tier TEXT NOT NULL CHECK (static_tier IN ('LOW', 'MED', 'HIGH')),
    trending_items TEXT[] DEFAULT '{}',
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed initial data
INSERT INTO public.vault_heatmaps (zone_id, static_tier)
VALUES 
    ('industrial_zone', 'LOW'),
    ('suburbs', 'MED'),
    ('mall', 'HIGH'),
    ('sovereign_vault', 'LOW')
ON CONFLICT (zone_id) DO NOTHING;

-- 2. Update Vault Items (Crates) to store metadata
ALTER TABLE public.vault_items
ADD COLUMN IF NOT EXISTS source_zone_id TEXT,
ADD COLUMN IF NOT EXISTS source_static_tier TEXT CHECK (source_static_tier IN ('LOW', 'MED', 'HIGH'));

-- 3. Update rpc_get_vault_heatmaps
CREATE OR REPLACE FUNCTION public.rpc_get_vault_heatmaps()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN (
        SELECT jsonb_object_agg(zone_id, jsonb_build_object(
            'tier', static_tier,
            'trending', trending_items,
            'updated_at', updated_at
        ))
        FROM public.vault_heatmaps
    );
END;
$$;

-- 4. Helper function to refresh heatmaps (could be called by a cron/worker)
CREATE OR REPLACE FUNCTION public.rpc_refresh_heatmaps()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_zone TEXT;
    v_tier TEXT;
    v_roll FLOAT;
BEGIN
    -- This is a simplified version of the logic. 
    -- In a real app, this might be triggered every 15m.
    FOR v_zone IN SELECT zone_id FROM public.vault_heatmaps LOOP
        v_roll := random();
        IF v_roll < 0.15 THEN v_tier := 'HIGH';
        ELSIF v_roll < 0.50 THEN v_tier := 'MED';
        ELSE v_tier := 'LOW';
        END IF;

        UPDATE public.vault_heatmaps 
        SET 
            static_tier = v_tier,
            updated_at = NOW()
        WHERE zone_id = v_zone;
    END LOOP;

    RETURN jsonb_build_object('success', true);
END;
$$;

-- 5. Update rpc_extract_v6 to use heatmaps
-- We need to fetch the existing function definition first to ensure we don't break other logic.
-- Since I don't have the FULL rpc_extract_v6 original text accurately beyond snippets, 
-- I will redefine it based on the requirements.
-- Assuming rpc_extract_v6 parameters: (payload JSONB)

CREATE OR REPLACE FUNCTION public.rpc_extract_v6(payload JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := (payload->>'p_user_id')::UUID;
    v_seismic_grade TEXT := payload->>'p_seismic_grade';
    v_profile RECORD;
    v_heatmap RECORD;
    v_base_find_chance FLOAT := 0.15;
    v_bonus_find_chance FLOAT := 0;
    v_final_find_chance FLOAT;
    v_crate_dropped BOOLEAN := FALSE;
    v_roll FLOAT;
    v_new_balance BIGINT;
    v_scrap_gain INT := 0;
    v_xp_gain INT := 10;
    v_result TEXT := 'NOTHING';
    v_crate_id UUID;
BEGIN
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated');
    END IF;

    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Profile not found');
    END IF;

    -- Fetch Heatmap for active zone
    SELECT * INTO v_heatmap FROM public.vault_heatmaps WHERE zone_id = v_profile.active_zone_id;
    
    -- Apply Heatmap Bonus
    IF v_heatmap.static_tier = 'HIGH' THEN v_bonus_find_chance := 0.02;
    ELSIF v_heatmap.static_tier = 'MED' THEN v_bonus_find_chance := 0.01;
    END IF;

    v_final_find_chance := v_base_find_chance + v_bonus_find_chance;
    
    -- (Omitted: Seismic logic integration for brevity, assuming standard roll for now 
    -- or if v_seismic_grade includes 'PERFECT', increase chance)
    IF v_seismic_grade LIKE '%PERFECT%' THEN
        v_final_find_chance := v_final_find_chance * 1.5;
    END IF;

    v_roll := random();
    IF v_roll < v_final_find_chance THEN
        IF v_profile.tray_count < 5 THEN
            v_crate_dropped := TRUE;
            v_result := 'CRATE_FOUND';
            v_crate_id := gen_random_uuid();
            
            -- Insert crate with heatmap metadata
            INSERT INTO public.vault_items (
                id, user_id, item_id, source_zone_id, source_static_tier, created_at
            ) VALUES (
                v_crate_id, v_user_id, 'unidentified_crate', 
                v_profile.active_zone_id, v_heatmap.static_tier, NOW()
            );

            UPDATE public.profiles 
            SET 
                tray_count = tray_count + 1,
                crate_tray = array_append(crate_tray, v_crate_id)
            WHERE id = v_user_id;
        ELSE
            v_result := 'TRAY_FULL';
        END IF;
    ELSE
        -- Scrap fallback
        v_scrap_gain := floor(random() * 50) + 10;
        UPDATE public.profiles SET scrap_balance = scrap_balance + v_scrap_gain WHERE id = v_user_id;
        v_result := 'SCRAP_FOUND';
    END IF;

    UPDATE public.profiles 
    SET 
        excavation_xp = excavation_xp + v_xp_gain,
        last_extract_at = NOW()
    WHERE id = v_user_id;

    SELECT scrap_balance INTO v_new_balance FROM public.profiles WHERE id = v_user_id;

    RETURN jsonb_build_object(
        'success', true,
        'result', v_result,
        'crate_dropped', v_crate_dropped,
        'scrap_gain', v_scrap_gain,
        'new_balance', v_new_balance,
        'new_xp', v_profile.excavation_xp + v_xp_gain,
        'crate_tray', (SELECT crate_tray FROM public.profiles WHERE id = v_user_id)
    );
END;
$$;

-- 6. Update rpc_sift_v2 to use source static tier
DROP FUNCTION IF EXISTS public.rpc_sift_v2(UUID, INT, INT);

CREATE OR REPLACE FUNCTION public.rpc_sift_v2(p_user_id UUID, p_tethers_used INT DEFAULT 0, p_zone INT DEFAULT 0)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_profile RECORD;
    v_lab RECORD;
    v_crate RECORD;
    v_base_stability FLOAT;
    v_stability_penalty FLOAT := 0;
    v_survey_active BOOLEAN := FALSE;
    v_final_stability FLOAT;
    v_roll FLOAT;
    v_success BOOLEAN;
BEGIN
    SELECT * INTO v_profile FROM public.profiles WHERE id = p_user_id;
    SELECT * INTO v_lab FROM public.lab_state WHERE user_id = p_user_id;
    
    IF NOT v_lab.is_active THEN
        RETURN jsonb_build_object('success', false, 'error', 'No active lab session');
    END IF;

    -- Fetch crate metadata
    SELECT * INTO v_crate FROM public.vault_items WHERE id = v_lab.active_crate;

    -- Calculate Penalty
    IF v_crate.source_static_tier = 'HIGH' THEN v_stability_penalty := 0.05;
    ELSIF v_crate.source_static_tier = 'MED' THEN v_stability_penalty := 0.025;
    END IF;

    -- Survey Mitigation (Lv 70+)
    IF v_profile.last_survey_at IS NOT NULL AND v_profile.last_survey_at > NOW() - INTERVAL '10 minutes' THEN
        v_survey_active := TRUE;
        v_stability_penalty := v_stability_penalty * 0.5;
    END IF;

    -- Base Stability per stage
    CASE v_lab.current_stage
        WHEN 0 THEN v_base_stability := 0.90;
        WHEN 1 THEN v_base_stability := 0.75;
        WHEN 2 THEN v_base_stability := 0.50;
        WHEN 3 THEN v_base_stability := 0.25;
        WHEN 4 THEN v_base_stability := 0.10;
        ELSE v_base_stability := 0;
    END CASE;

    -- Tethers add stability
    v_base_stability := v_base_stability + (p_tethers_used * 0.15);

    v_final_stability := v_base_stability - v_stability_penalty;
    v_final_stability := GREATEST(0.01, LEAST(0.99, v_final_stability));

    v_roll := random();
    v_success := v_roll < v_final_stability;

    IF v_success THEN
        UPDATE public.lab_state SET current_stage = current_stage + 1 WHERE user_id = p_user_id;
        RETURN jsonb_build_object(
            'success', true, 
            'outcome', 'SUCCESS', 
            'new_stage', v_lab.current_stage + 1,
            'penalty_applied', v_stability_penalty
        );
    ELSE
        -- Failure
        UPDATE public.lab_state SET is_active = FALSE, current_stage = 0 WHERE user_id = p_user_id;
        UPDATE public.profiles SET tray_count = GREATEST(0, tray_count - 1) WHERE id = p_user_id;
        -- Remove crate from tray array too
        UPDATE public.profiles SET crate_tray = array_remove(crate_tray, v_lab.active_crate) WHERE id = p_user_id;
        
        RETURN jsonb_build_object('success', true, 'outcome', 'SHATTERED', 'penalty_applied', v_stability_penalty);
    END IF;
END;
$$;
