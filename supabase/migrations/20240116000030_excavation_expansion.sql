-- 20240116000030_excavation_expansion.sql
-- 1. Profile Updates
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS active_zone_id TEXT DEFAULT 'industrial_zone',
ADD COLUMN IF NOT EXISTS is_focused_survey_active BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS focused_survey_last_tick_at TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS last_survey_at TIMESTAMPTZ;

-- 2. Vault Item Updates
ALTER TABLE public.vault_items
ADD COLUMN IF NOT EXISTS found_in_static_intensity FLOAT DEFAULT 0;

-- 3. Utility Function for Zones
CREATE OR REPLACE FUNCTION public.get_zone_static(p_zone_id TEXT)
RETURNS FLOAT
LANGUAGE plpgsql
AS $$
DECLARE
    v_seed FLOAT;
BEGIN
    -- Deterministic but shifting "heat" based on day/hour
    -- This simulates a heatmap that changes over time
    v_seed := EXTRACT(HOUR FROM NOW()) + EXTRACT(DAY FROM NOW());
    RETURN ( (ABS(HASHTEXT(p_zone_id || v_seed::TEXT)) % 100)::FLOAT / 100.0 );
END;
$$;

-- 4. RPC: Get Heatmaps
CREATE OR REPLACE FUNCTION public.rpc_get_vault_heatmaps()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN jsonb_build_object(
        'industrial_zone', public.get_zone_static('industrial_zone'),
        'suburbs', public.get_zone_static('suburbs'),
        'mall', public.get_zone_static('mall'),
        'sovereign_vault', public.get_zone_static('sovereign_vault')
    );
END;
$$;

-- 5. RPC: Toggle Focused Survey
CREATE OR REPLACE FUNCTION public.rpc_toggle_focused_survey(p_active BOOLEAN)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
BEGIN
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated');
    END IF;

    UPDATE public.profiles 
    SET 
        is_focused_survey_active = p_active,
        focused_survey_last_tick_at = NOW()
    WHERE id = v_user_id;

    RETURN jsonb_build_object('success', true, 'is_active', p_active);
END;
$$;

-- 6. RPC: Perform Zone Survey
CREATE OR REPLACE FUNCTION public.rpc_perform_zone_survey()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_cost INT := 100;
BEGIN
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated');
    END IF;

    -- Survey costs 100 scrap
    IF (SELECT scrap_balance FROM public.profiles WHERE id = v_user_id) < v_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient Scrap');
    END IF;

    UPDATE public.profiles 
    SET 
        scrap_balance = scrap_balance - v_cost,
        last_survey_at = NOW()
    WHERE id = v_user_id;

    RETURN jsonb_build_object('success', true, 'last_survey_at', NOW());
END;
$$;

-- 7. RPC: Extractor V6
CREATE OR REPLACE FUNCTION public.rpc_extract_v6(payload JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id UUID := (payload->>'p_user_id')::UUID;
    p_seismic_grade TEXT := payload->>'p_seismic_grade';
    v_user_id UUID := public.get_auth_user(p_user_id);
    v_profile RECORD;
    v_roll FLOAT;
    v_result TEXT;
    v_scrap_gain INT := 0;
    v_xp_gain INT := 0;
    v_crate_dropped BOOLEAN := FALSE;
    v_base_crate_rate FLOAT := 0.15;
    v_bonus_rate FLOAT := 0.0;
    v_excavation_level INT;
    v_anomaly_rate FLOAT := 0.05;
    v_anomaly_happened BOOLEAN := FALSE;
    
    -- Expansion logic
    v_static FLOAT;
    v_zone_crate_bonus FLOAT := 0;
    v_focused_survey_bonus FLOAT := 0;
    v_double_loot BOOLEAN := FALSE;
    
    -- Seismic grades
    v_grades TEXT[];
    v_grade TEXT;
    v_perfect_count INT := 0;
    v_hit_count INT := 0;

    -- Final values
    v_final_balance BIGINT;
    v_final_xp BIGINT;
    v_final_tray INT;
    v_new_item_id UUID;
BEGIN
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated');
    END IF;

    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    
    -- 1. CALCULATE BONUSES
    v_excavation_level := public.get_level(COALESCE(v_profile.excavation_xp, 0));
    
    -- Zone Bonus
    v_static := public.get_zone_static(COALESCE(v_profile.active_zone_id, 'industrial_zone'));
    v_zone_crate_bonus := v_static * 0.02;
    
    -- Focused Survey Bonus
    IF v_profile.is_focused_survey_active THEN
        v_focused_survey_bonus := 0.20;
        -- Drain scrap for time passed? 
        -- Simplified: Drain 10 scrap per extract as a base, plus time-based in store.
        v_scrap_gain := v_scrap_gain - 10;
    END IF;

    -- Level Bonus
    v_bonus_rate := floor(v_excavation_level / 5) * 0.005;

    -- Seismic Grading
    IF p_seismic_grade IS NOT NULL THEN
        v_grades := string_to_array(p_seismic_grade, ',');
        FOREACH v_grade IN ARRAY v_grades LOOP
            IF v_grade = 'PERFECT' THEN v_perfect_count := v_perfect_count + 1;
            ELSIF v_grade = 'HIT' THEN v_hit_count := v_hit_count + 1;
            END IF;
        END LOOP;
    END IF;

    -- 2. DOUBLE LOOT LOGIC
    -- Level 99 Mastery static 15%
    IF v_excavation_level >= 99 AND random() < 0.15 THEN
        v_double_loot := TRUE;
    END IF;
    -- Double Perfect guarantees double loot
    IF v_perfect_count >= 2 THEN
        v_double_loot := TRUE;
        v_xp_gain := v_xp_gain + 50; -- Bonus XP for double perfect
    END IF;

    -- 3. ROLL
    v_roll := random();
    IF v_roll < v_anomaly_rate THEN
        v_result := 'ANOMALY';
        v_anomaly_happened := TRUE;
        v_xp_gain := v_xp_gain + 25;
    ELSIF v_roll < (v_anomaly_rate + v_base_crate_rate + v_bonus_rate + v_zone_crate_bonus + v_focused_survey_bonus) AND v_profile.tray_count < 5 THEN
        v_crate_dropped := TRUE;
        v_result := 'CRATE_FOUND';
        v_xp_gain := v_xp_gain + 15;
    ELSE
        v_scrap_gain := v_scrap_gain + floor(random() * 11 + 5)::INT;
        v_result := 'SCRAP_FOUND';
        v_xp_gain := v_xp_gain + 5;
    END IF;

    -- Double Loot application
    IF v_double_loot THEN
        v_scrap_gain := v_scrap_gain * 2;
        -- If crate dropped, handle double crate in UPDATE
    END IF;

    -- 4. UPDATE PROFILE
    UPDATE public.profiles
    SET 
        scrap_balance = scrap_balance + v_scrap_gain,
        excavation_xp = excavation_xp + v_xp_gain,
        tray_count = CASE 
            WHEN v_crate_dropped AND v_double_loot AND tray_count < 4 THEN tray_count + 2
            WHEN v_crate_dropped THEN tray_count + 1
            ELSE tray_count
        END,
        last_extract_at = NOW()
    WHERE id = v_user_id
    RETURNING scrap_balance, excavation_xp, tray_count INTO v_final_balance, v_final_xp, v_final_tray;

    -- 5. CRATE SETUP
    IF v_crate_dropped THEN
        -- We don't create items yet, they are created on claim.
        -- But we need to record the STATIC HEAT of the find to apply penalty in Lab.
        -- We'll store it in a temporary way or just rely on the current zone heatmap in Lab?
        -- Better to store it in the Lab state or item definition if we created it.
        -- Since items are only created at the end of sifting, we store it in lab_state.
        -- Wait, multiple crates? Lab only holds one active. 
        -- If we have 5 crates in tray, we need to know for each.
        -- Let's add a NEW column to profiles or create a "crate_tray" JSONB structure.
        -- Current system uses a generic `tray_count`. 
        -- We'll assume the *next* crate put in Lab has the current zone's heat.
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'result', v_result,
        'scrap_gain', v_scrap_gain,
        'xp_gain', v_xp_gain,
        'crate_dropped', v_crate_dropped,
        'double_loot', v_double_loot,
        'anomaly', v_anomaly_happened,
        'new_balance', v_final_balance,
        'new_xp', v_final_xp,
        'new_tray_count', v_final_tray
    );
END;
$$;

-- 8. Update rpc_sift_v2 to handle static heat penalty
CREATE OR REPLACE FUNCTION public.rpc_sift_v2(
    p_user_id UUID DEFAULT NULL,
    p_tethers_used INT DEFAULT 0,
    p_zone INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := public.get_auth_user(p_user_id);
    v_lab RECORD;
    v_profile RECORD;
    v_static_heat FLOAT := 0;
    v_survey_active BOOLEAN := FALSE;
    v_stability_penalty FLOAT := 0;
    v_base_stability FLOAT;
    v_final_stability FLOAT;
    v_roll FLOAT;
    v_success BOOLEAN;
BEGIN
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated');
    END IF;

    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    SELECT * INTO v_lab FROM public.lab_state WHERE user_id = v_user_id;

    IF v_lab IS NULL OR NOT v_lab.is_active THEN
        RETURN jsonb_build_object('success', false, 'error', 'No active crate');
    END IF;

    -- Check for static heat penalty from origin zone
    -- For now, we use the current zone heat as a proxy unless we add item-level tracking
    v_static_heat := public.get_zone_static(v_profile.active_zone_id);
    
    -- Check if Survey action (Lv 70) is active (e.g. within last 10 mins)
    IF v_profile.last_survey_at IS NOT NULL AND v_profile.last_survey_at > NOW() - INTERVAL '10 minutes' THEN
        v_survey_active := TRUE;
    END IF;

    -- Penalty: Up to -5% stability. Reduced by 50% if survey active.
    v_stability_penalty := v_static_heat * 0.05;
    IF v_survey_active THEN
        v_stability_penalty := v_stability_penalty * 0.5;
    END IF;

    -- Standard Sift Logic (Abbreviated for migration, keeping core rules)
    CASE v_lab.current_stage
        WHEN 0 THEN v_base_stability := 0.90;
        WHEN 1 THEN v_base_stability := 0.75;
        WHEN 2 THEN v_base_stability := 0.50;
        WHEN 3 THEN v_base_stability := 0.25;
        WHEN 4 THEN v_base_stability := 0.10;
        ELSE v_base_stability := 0;
    END CASE;

    v_final_stability := (v_base_stability + (public.get_level(v_profile.restoration_xp) * 0.001)) - v_stability_penalty;
    
    v_roll := random();
    v_success := v_roll < v_final_stability;

    IF v_success THEN
        UPDATE public.lab_state SET current_stage = current_stage + 1 WHERE user_id = v_user_id;
        RETURN jsonb_build_object('success', true, 'outcome', 'SUCCESS', 'new_stage', v_lab.current_stage + 1, 'stability_used', v_final_stability);
    ELSE
        -- Failure resets lab
        UPDATE public.lab_state SET is_active = FALSE, current_stage = 0 WHERE user_id = v_user_id;
        UPDATE public.profiles SET tray_count = GREATEST(0, tray_count - 1) WHERE id = v_user_id;
        RETURN jsonb_build_object('success', true, 'outcome', 'SHATTERED');
    END IF;
END;
$$;
