-- Phase 2 Completion: Logic Updates

-- 1. Helper function for XP to Level
CREATE OR REPLACE FUNCTION public.get_level(xp BIGINT)
RETURNS INT LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
    level INT := 1;
    threshold BIGINT := 0;
BEGIN
    FOR i IN 1..98 LOOP
        threshold := threshold + floor(i + 300 * power(2, i::float/7));
        IF xp < threshold THEN
            RETURN i;
        END IF;
    END LOOP;
    RETURN 99;
END;
$$;

-- 2. Update rpc_extract for Excavation Bonus (R4) and Levels
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
    
    IF v_roll < v_final_rate AND v_profile.tray_count < 5 THEN
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

    RETURN jsonb_build_object(
        'success', true, 
        'result', v_result, 
        'scrap_gain', v_scrap_gain, 
        'xp_gain', v_xp_gain,
        'crate_dropped', v_crate_dropped,
        'level', v_excavation_level,
        'cooldown_used', v_cooldown_sec,
        'new_balance', v_profile.scrap_balance + v_scrap_gain,
        'new_xp', v_profile.excavation_xp + v_xp_gain,
        'new_tray_count', CASE WHEN v_crate_dropped THEN v_profile.tray_count + 1 ELSE v_profile.tray_count END
    );
END;
$$;

-- 3. Update rpc_sift for Restoration Bonus (R6) and Pity XP (R5)
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

    -- Level Bonus (R6): +0.1% per level
    v_restoration_level := public.get_level(v_profile.restoration_xp);
    v_bonus_stability := v_restoration_level * 0.001;
    v_final_stability := v_base_stability + v_bonus_stability;

    -- Roll
    v_roll := random();
    v_success := v_roll < v_final_stability;

    IF v_success THEN
        v_xp_gain := (v_lab.current_stage + 1) * 10;
        UPDATE public.lab_state SET current_stage = current_stage + 1, last_action_at = NOW() WHERE user_id = v_user_id;
        UPDATE public.profiles SET restoration_xp = restoration_xp + v_xp_gain WHERE id = v_user_id;
        RETURN jsonb_build_object('success', true, 'outcome', 'SUCCESS', 'new_stage', v_lab.current_stage + 1, 'xp_gain', v_xp_gain);
    ELSE
        -- Pity XP (R5): 25% of potential gain
        v_xp_gain := floor(((v_lab.current_stage + 1) * 10) * 0.25)::INT;
        
        UPDATE public.lab_state SET is_active = FALSE, current_stage = 0, last_action_at = NOW() WHERE user_id = v_user_id;
        UPDATE public.profiles SET tray_count = tray_count - 1, restoration_xp = restoration_xp + v_xp_gain WHERE id = v_user_id;
        RETURN jsonb_build_object('success', true, 'outcome', 'SHATTERED', 'xp_gain', v_xp_gain);
    END IF;
END;
$$;

-- 4. rpc_claim_set (R11)
CREATE OR REPLACE FUNCTION public.rpc_claim_set(p_set_id TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_required_items TEXT[];
    v_has_items BOOLEAN;
    v_reward_scrap INT := 0; 
BEGIN
    IF p_set_id = 'morning_ritual' THEN
        v_required_items := ARRAY['ceramic_mug', 'rusty_toaster', 'spoon'];
        v_reward_scrap := 0; -- Buff reward only
    ELSIF p_set_id = 'basic_electronics' THEN
        v_required_items := ARRAY['aa_battery', 'lightbulb', 'calculated_tablet'];
        v_reward_scrap := 100;
    ELSIF p_set_id = 'ancient_dining' THEN
         v_required_items := ARRAY['ceramic_mug', 'steel_fork', 'soda_tab'];
         v_reward_scrap := 150;
    ELSIF p_set_id = 'analog_tech' THEN
         v_required_items := ARRAY['broken_watch', 'wrist_chronometer', 'compact_disc'];
         v_reward_scrap := 500;
    ELSE
        RETURN jsonb_build_object('success', false, 'error', 'Unknown set');
    END IF;

    SELECT NOT EXISTS (
        SELECT unnest(v_required_items) EXCEPT SELECT item_id FROM public.vault_items WHERE user_id = v_user_id
    ) INTO v_has_items;

    IF NOT v_has_items THEN
         RETURN jsonb_build_object('success', false, 'error', 'Missing items');
    END IF;

    INSERT INTO public.completed_sets (user_id, set_id) VALUES (v_user_id, p_set_id)
    ON CONFLICT DO NOTHING;

    IF v_reward_scrap > 0 THEN
        UPDATE public.profiles SET scrap_balance = scrap_balance + v_reward_scrap WHERE id = v_user_id;
    END IF;

    RETURN jsonb_build_object('success', true, 'set_id', p_set_id, 'reward_scrap', v_reward_scrap);
END;
$$;

-- 5. rpc_passive_tick (Online Passive)
CREATE OR REPLACE FUNCTION public.rpc_passive_tick()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_profile RECORD;
    v_tool_power INT := 0;
    v_crate_dropped BOOLEAN := FALSE;
    v_excavation_level INT;
    v_roll FLOAT;
    v_base_rate FLOAT := 0.15;
    v_level_bonus FLOAT := 0.0;
BEGIN
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    
    CASE v_profile.active_tool_id
        WHEN 'rusty_shovel' THEN v_tool_power := 0;
        WHEN 'pneumatic_pick' THEN v_tool_power := 5;
        WHEN 'ground_radar' THEN v_tool_power := 25;
        WHEN 'industrial_drill' THEN v_tool_power := 100;
        ELSE v_tool_power := 0;
    END CASE;

    IF v_tool_power = 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'No passive power');
    END IF;

    v_excavation_level := public.get_level(v_profile.excavation_xp);
    v_level_bonus := floor(v_excavation_level / 5) * 0.005;
    
    v_roll := random();
    IF v_roll < (v_base_rate + v_level_bonus) AND v_profile.tray_count < 5 THEN
        v_crate_dropped := TRUE;
    END IF;

    UPDATE public.profiles
    SET 
        scrap_balance = scrap_balance + v_tool_power,
        tray_count = CASE WHEN v_crate_dropped THEN tray_count + 1 ELSE tray_count END,
        updated_at = NOW()
    WHERE id = v_user_id;

    RETURN jsonb_build_object(
        'success', true, 
        'scrap_gain', v_tool_power, 
        'crate_dropped', v_crate_dropped,
        'new_balance', v_profile.scrap_balance + v_tool_power
    );
END;
$$;

-- 6. rpc_handle_offline_gains (R15)
CREATE OR REPLACE FUNCTION public.rpc_handle_offline_gains()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_profile RECORD;
    v_seconds_offline INT;
    v_cap_seconds INT := 28800; 
    v_tool_power INT := 0;
    v_total_scrap BIGINT;
    v_ticks INT;
BEGIN
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    
    v_seconds_offline := EXTRACT(EPOCH FROM (NOW() - v_profile.last_logout_at));
    
    IF v_seconds_offline < 10 THEN
        UPDATE public.profiles SET last_logout_at = NOW() WHERE id = v_user_id;
        RETURN jsonb_build_object('success', false, 'reason', 'Too short');
    END IF;

    IF v_seconds_offline > v_cap_seconds THEN
        v_seconds_offline := v_cap_seconds;
    END IF;

    v_ticks := floor(v_seconds_offline / 10);
    
    CASE v_profile.active_tool_id
        WHEN 'rusty_shovel' THEN v_tool_power := 0;
        WHEN 'pneumatic_pick' THEN v_tool_power := 5;
        WHEN 'ground_radar' THEN v_tool_power := 25;
        WHEN 'industrial_drill' THEN v_tool_power := 100;
        ELSE v_tool_power := 0;
    END CASE;

    IF v_tool_power = 0 OR v_ticks = 0 THEN
         UPDATE public.profiles SET last_logout_at = NOW() WHERE id = v_user_id;
         RETURN jsonb_build_object('success', true, 'scrap_gain', 0, 'ticks', 0);
    END IF;

    v_total_scrap := v_ticks * v_tool_power;
    
    UPDATE public.profiles 
    SET 
        scrap_balance = scrap_balance + v_total_scrap,
        last_logout_at = NOW()
    WHERE id = v_user_id;

    RETURN jsonb_build_object('success', true, 'scrap_gain', v_total_scrap, 'ticks', v_ticks, 'seconds_offline', v_seconds_offline);
END;
$$;
