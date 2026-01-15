-- Phase 2 Extension: Overclocking and Anomalies

-- 1. Add overclock_bonus to profiles
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS overclock_bonus FLOAT DEFAULT 0.0;

-- 2. Update rpc_extract for Anomalies
CREATE OR REPLACE FUNCTION public.rpc_extract()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_profile RECORD;
    v_roll FLOAT;
    v_result TEXT;
    v_scrap_gain INT := 0;
    v_xp_gain INT := 0;
    v_crate_dropped BOOLEAN := FALSE;
    v_cooldown_sec FLOAT := 3.0;
    v_base_rate FLOAT := 0.15;
    v_bonus_rate FLOAT := 0.0;
    v_final_rate FLOAT;
    v_excavation_level INT;
    v_anomaly_happened BOOLEAN := FALSE;
BEGIN
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    
    -- Check for buffs (Sets)
    IF EXISTS (
        SELECT 1 FROM public.completed_sets 
        WHERE user_id = v_user_id AND set_id = 'morning_ritual'
    ) THEN
        v_cooldown_sec := v_cooldown_sec - 0.5;
    END IF;

    -- Check cooldown
    IF v_profile.last_extract_at > NOW() - (v_cooldown_sec || ' seconds')::INTERVAL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Cooldown active');
    END IF;

    -- Calculate Excavation Level
    v_excavation_level := public.get_level(v_profile.excavation_xp);

    -- Apply Level Bonus: +0.5% per 5 levels
    v_bonus_rate := floor(v_excavation_level / 5) * 0.005;

    v_final_rate := v_base_rate + v_bonus_rate;
    
    -- Roll
    v_roll := random();
    
    -- Anomaly 5% (R2)
    IF v_roll < 0.05 THEN
        v_result := 'ANOMALY';
        v_xp_gain := 25;
        v_anomaly_happened := TRUE;
    ELSIF v_roll < v_final_rate + 0.05 AND v_profile.tray_count < 5 THEN
        v_crate_dropped := TRUE;
        v_result := 'CRATE_FOUND';
        v_xp_gain := 15;
    ELSIF v_roll < 0.9 THEN
        v_scrap_gain := floor(random() * (15 - 5 + 1) + 5)::INT;
        v_result := 'SCRAP_FOUND';
        v_xp_gain := 5;
    ELSE
        v_result := 'NOTHING_FOUND';
        v_xp_gain := 1;
    END IF;

    UPDATE public.profiles
    SET 
        scrap_balance = scrap_balance + v_scrap_gain,
        excavation_xp = excavation_xp + v_xp_gain,
        tray_count = CASE WHEN v_crate_dropped THEN tray_count + 1 ELSE tray_count END,
        last_extract_at = NOW(),
        updated_at = NOW()
    WHERE id = v_user_id;

    -- If anomaly, maybe insert into global_events
    -- We'll use the record if it was a real one, but here we just log it.
    IF v_anomaly_happened THEN
        INSERT INTO public.global_events (event_type, user_id, details)
        VALUES ('anomaly', v_user_id, jsonb_build_object('item_id', 'temporal_rift', 'xp_gain', v_xp_gain));
    END IF;

    RETURN jsonb_build_object(
        'success', true, 
        'result', v_result, 
        'scrap_gain', v_scrap_gain, 
        'xp_gain', v_xp_gain,
        'crate_dropped', v_crate_dropped,
        'anomaly', v_anomaly_happened,
        'level', v_excavation_level,
        'new_balance', v_profile.scrap_balance + v_scrap_gain,
        'new_xp', v_profile.excavation_xp + v_xp_gain,
        'new_tray_count', CASE WHEN v_crate_dropped THEN v_profile.tray_count + 1 ELSE v_profile.tray_count END
    );
END;
$$;

-- 3. Update rpc_sift to include Overclock Bonus
CREATE OR REPLACE FUNCTION public.rpc_sift()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_lab RECORD;
    v_profile RECORD;
    v_base_stability FLOAT;
    v_bonus_stability FLOAT;
    v_final_stability FLOAT;
    v_roll FLOAT;
    v_success BOOLEAN;
    v_xp_gain INT := 0;
    v_restoration_level INT;
BEGIN
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    SELECT * INTO v_lab FROM public.lab_state WHERE user_id = v_user_id;
    
    IF v_lab IS NULL OR NOT v_lab.is_active THEN
        RETURN jsonb_build_object('success', false, 'error', 'No active crate in lab');
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

    -- Level Bonus: +0.1% per level
    v_restoration_level := public.get_level(v_profile.restoration_xp);
    v_bonus_stability := v_restoration_level * 0.001;
    
    -- Overclock Bonus (R9)
    v_final_stability := v_base_stability + v_bonus_stability + v_profile.overclock_bonus;

    -- Roll
    v_roll := random();
    v_success := v_roll < v_final_stability;

    IF v_success THEN
        v_xp_gain := (v_lab.current_stage + 1) * 10;
        UPDATE public.lab_state SET current_stage = current_stage + 1, last_action_at = NOW() WHERE user_id = v_user_id;
        UPDATE public.profiles SET restoration_xp = restoration_xp + v_xp_gain WHERE id = v_user_id;
        RETURN jsonb_build_object('success', true, 'outcome', 'SUCCESS', 'new_stage', v_lab.current_stage + 1, 'xp_gain', v_xp_gain);
    ELSE
        -- Pity XP: 25% of potential gain
        v_xp_gain := floor(((v_lab.current_stage + 1) * 10) * 0.25)::INT;
        
        UPDATE public.lab_state SET is_active = FALSE, current_stage = 0, last_action_at = NOW() WHERE user_id = v_user_id;
        UPDATE public.profiles SET tray_count = tray_count - 1, restoration_xp = restoration_xp + v_xp_gain WHERE id = v_user_id;
        RETURN jsonb_build_object('success', true, 'outcome', 'SHATTERED', 'xp_gain', v_xp_gain);
    END IF;
END;
$$;

-- 4. RPC for Overclocking
CREATE OR REPLACE FUNCTION public.rpc_overclock_tool(p_tool_id TEXT, p_cost INT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_profile RECORD;
BEGIN
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    
    IF v_profile.scrap_balance < p_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient scrap');
    END IF;

    -- Doc says overclocking resets the tool to Level 1. 
    -- Since we don't have per-tool levels yet, we'll just apply the bonus and subtract scrap.
    -- If we want to be strict, we could check if they own the tool.
    
    UPDATE public.profiles 
    SET overclock_bonus = overclock_bonus + 0.05,
        scrap_balance = scrap_balance - p_cost,
        updated_at = NOW()
    WHERE id = v_user_id;

    RETURN jsonb_build_object('success', true, 'new_bonus', (SELECT overclock_bonus FROM public.profiles WHERE id = v_user_id));
END;
$$;
