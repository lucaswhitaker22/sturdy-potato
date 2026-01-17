-- 20240118000003_fix_sift_logic.sql
-- Fixes rpc_sift_v3 to correctly implement Shatter Salvage logic (Critical vs Standard Fail)
-- Adds Titles and Cosmetics support to Profiles
-- Updates rpc_claim_quest_reward to grant Titles and Cosmetics

-- 1. Add Titles and Cosmetics columns
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS unlocked_titles TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS unlocked_cosmetics TEXT[] DEFAULT '{}';

-- 2. Fix rpc_sift_v3 (Shatter Salvage logic)
CREATE OR REPLACE FUNCTION public.rpc_sift_v3(
    p_user_id UUID DEFAULT NULL,
    p_tethers_used INT DEFAULT 0,
    p_zone INT DEFAULT 0 -- 0 = Safe, 1 = Danger
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := public.get_auth_user(p_user_id);
    v_lab RECORD;
    v_profile RECORD;
    v_crate RECORD;
    
    -- Mechanics
    v_base_stability FLOAT;
    v_bonus_stability FLOAT;
    v_stability_penalty FLOAT := 0;
    v_final_stability FLOAT;
    v_roll FLOAT;
    v_success BOOLEAN;
    
    -- Heatmap / Survey
    v_survey_active BOOLEAN := FALSE;
    
    -- Rewards
    v_xp_gain INT := 0;
    v_restoration_level INT;
    v_overclock_bonus FLOAT := 0;
    
    -- Shatter & Salvage Logic Vars
    v_stage INT;
    v_tether_cost INT;
    v_total_cost INT;
    v_base_crit_chance FLOAT;
    v_zone_mult FLOAT;
    v_tether_mult FLOAT;
    v_final_crit_chance FLOAT;
    v_fail_roll FLOAT;
    v_is_critical BOOLEAN;
    v_dust_payout INT := 0;
    
    v_salvage_token UUID := NULL;
    v_pending_fragment BOOLEAN := FALSE;
    v_pending_dust INT := 0;
    v_fragment_chance FLOAT := 0.25; -- Base 25% at Stage 3+
    
BEGIN
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated');
    END IF;

    -- Load State
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    SELECT * INTO v_lab FROM public.lab_state WHERE user_id = v_user_id;
    
    IF v_lab IS NULL OR NOT v_lab.is_active THEN
        RETURN jsonb_build_object('success', false, 'error', 'No active crate');
    END IF;
    
    -- Get Crate Info for Static Tier
    SELECT * INTO v_crate FROM public.vault_items WHERE id = v_lab.active_crate;

    v_stage := v_lab.current_stage;
    v_restoration_level := public.get_level(COALESCE(v_profile.restoration_xp, 0));
    
    -- QUEST TRIGGER: Crate Opened (First sift)
    IF v_stage = 0 THEN
        PERFORM public.internal_increment_quest_objective(v_user_id, 'crate_opened', 1);
    END IF;

    -- QUEST TRIGGER: Sift Attempt (At current stage)
    PERFORM public.internal_increment_quest_objective(v_user_id, 'sift_attempted', 1);
    PERFORM public.internal_increment_quest_objective(v_user_id, 'sift_stage_at_least', 1, jsonb_build_object('stage', v_stage));

    -- 1. Cost & Config Logic
    DECLARE
        v_base_cost INT;
        v_discount FLOAT;
    BEGIN
        IF v_stage = 1 THEN v_base_cost := 2;
        ELSIF v_stage = 2 THEN v_base_cost := 3;
        ELSIF v_stage = 3 THEN v_base_cost := 5;
        ELSIF v_stage = 4 THEN v_base_cost := 8;
        ELSIF v_stage = 5 THEN v_base_cost := 12;
        ELSE v_base_cost := 0;
        END IF;
        
        v_discount := LEAST(0.4, v_restoration_level * 0.004);
        v_tether_cost := ceil(v_base_cost * (1 - v_discount));
    END;

    v_total_cost := p_tethers_used * v_tether_cost;
    
    IF v_profile.fine_dust_balance < v_total_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient Fine Dust for Tethers');
    END IF;


    -- 2. Calculate Penalty (Heatmaps)
    IF v_crate.source_static_tier = 'HIGH' THEN v_stability_penalty := 0.05;
    ELSIF v_crate.source_static_tier = 'MED' THEN v_stability_penalty := 0.025;
    END IF;

    -- Survey Mitigation
    IF v_profile.last_survey_at IS NOT NULL AND v_profile.last_survey_at > NOW() - INTERVAL '10 minutes' THEN
        v_survey_active := TRUE;
        v_stability_penalty := v_stability_penalty * 0.5;
    END IF;

    -- 3. Base Stability
    IF v_stage = 0 THEN v_base_stability := 0.90;
    ELSIF v_stage = 1 THEN v_base_stability := 0.75;
    ELSIF v_stage = 2 THEN v_base_stability := 0.50;
    ELSIF v_stage = 3 THEN v_base_stability := 0.25;
    ELSIF v_stage = 4 THEN v_base_stability := 0.10;
    ELSE v_base_stability := 0.05;
    END IF;

    -- Overclock & Restoration Bonus
    v_overclock_bonus := COALESCE(v_profile.overclock_bonus, 0);
    v_bonus_stability := (v_restoration_level * 0.001) + v_overclock_bonus;
    
    -- Tether Bonus (Stability)
    v_bonus_stability := v_bonus_stability + (p_tethers_used * 0.05);

    -- 4. Final Calc
    v_final_stability := GREATEST(0.01, LEAST(0.99, v_base_stability + v_bonus_stability - v_stability_penalty));

    -- 5. Roll
    v_roll := random();
    v_success := v_roll < v_final_stability;

    IF v_success THEN
        -- SUCCESS
        UPDATE public.lab_state SET current_stage = current_stage + 1, last_action_at = NOW(), salvage_token = NULL WHERE user_id = v_user_id;
        
        -- XP Gain (Base 15 + Stage Bonus)
        v_xp_gain := 15 + (v_stage * 10);
        
        UPDATE public.profiles SET 
            restoration_xp = restoration_xp + v_xp_gain,
            fine_dust_balance = fine_dust_balance - v_total_cost 
        WHERE id = v_user_id;
        
        RETURN jsonb_build_object(
            'success', true, 
            'outcome', 'SUCCESS', 
            'new_stage', v_stage + 1,
            'xp_gain', v_xp_gain,
            'penalty_applied', v_stability_penalty
        );
    ELSE
        -- FAILURE
        
        -- 6. Critical Check (Restored Logic)
        v_base_crit_chance := 0.20; 
        v_zone_mult := 1.0;
        v_tether_mult := 1.0;
        
        IF p_zone = 1 THEN v_zone_mult := 2.5; END IF; 
        IF p_tethers_used > 0 THEN v_tether_mult := 0.5; END IF;
        
        v_final_crit_chance := LEAST(0.9, v_base_crit_chance * v_zone_mult * v_tether_mult);
        
        v_fail_roll := random();
        v_is_critical := v_fail_roll < v_final_crit_chance;

        IF v_is_critical THEN
             -- CRITICAL FAIL (SHATTERED) - No Salvage
            UPDATE public.lab_state SET 
                is_active = FALSE, 
                current_stage = 0, 
                last_action_at = NOW(),
                salvage_token = NULL 
            WHERE user_id = v_user_id;
            
            UPDATE public.profiles SET 
                tray_count = GREATEST(0, tray_count - 1),
                crate_tray = array_remove(crate_tray, v_lab.active_crate),
                fine_dust_balance = fine_dust_balance - v_total_cost
            WHERE id = v_user_id;
            
            RETURN jsonb_build_object(
                'success', true, 
                'outcome', 'SHATTERED',
                'critical', true,
                'crit_chance', v_final_crit_chance
            );
        ELSE
            -- STANDARD FAIL (STABILIZED) - Salvage Enabled
            v_dust_payout := (v_stage * 2) + 3;
            
            -- Salvage Logic
            IF v_profile.smelting_branch = 'fragment_alchemist' THEN
                v_fragment_chance := 0.40; -- +15% from base
            END IF;
    
            v_salvage_token := gen_random_uuid();
            
            IF v_stage >= 1 AND v_stage <= 2 THEN
                v_pending_dust := v_dust_payout;
            END IF;
            
            IF v_stage >= 3 AND random() < v_fragment_chance THEN
                v_pending_fragment := TRUE;
            END IF;
    
            UPDATE public.lab_state SET 
                is_active = FALSE, 
                current_stage = 0, 
                last_action_at = NOW(),
                salvage_token = v_salvage_token,
                salvage_expires_at = NOW() + INTERVAL '1.15 seconds',
                pending_salvage_dust = v_pending_dust,
                pending_salvage_fragment = v_pending_fragment
            WHERE user_id = v_user_id;
            
            UPDATE public.profiles SET 
                tray_count = GREATEST(0, tray_count - 1),
                crate_tray = array_remove(crate_tray, v_lab.active_crate),
                fine_dust_balance = fine_dust_balance + v_dust_payout - v_total_cost
            WHERE id = v_user_id;
            
            RETURN jsonb_build_object(
                'success', true, 
                'outcome', 'STABILIZED_FAIL',
                'salvage_token', v_salvage_token,
                'salvage_expires_at', (NOW() + INTERVAL '1.15 seconds'),
                'pending_dust', v_pending_dust,
                'pending_fragment', v_pending_fragment,
                'dust_payout', v_dust_payout,
                'new_dust_balance', (v_profile.fine_dust_balance + v_dust_payout - v_total_cost)
            );
        END IF;
    END IF;
END;
$$;

-- 3. Fix rpc_claim_quest_reward (Implement Title/Cosmetic)
CREATE OR REPLACE FUNCTION public.rpc_claim_quest_reward(p_quest_db_id UUID, p_user_id UUID DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := public.get_auth_user(p_user_id);
    v_quest RECORD;
    v_def RECORD;
    v_reward JSONB;
    v_next_ids TEXT[];
    v_next_id TEXT;
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;

    SELECT * INTO v_quest FROM public.player_quests WHERE id = p_quest_db_id AND user_id = v_user_id;
    IF v_quest IS NULL OR v_quest.status <> 'COMPLETED' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Quest not completed');
    END IF;

    SELECT * INTO v_def FROM public.quest_definitions WHERE id = v_quest.quest_id;

    -- Grant Rewards
    FOR v_reward IN SELECT * FROM jsonb_array_elements(v_def.rewards) LOOP
        IF v_reward->>'kind' = 'scrap' THEN
            UPDATE public.profiles SET scrap_balance = scrap_balance + (v_reward->>'amount')::INT WHERE id = v_user_id;
        ELSIF v_reward->>'kind' = 'fine_dust' OR v_reward->>'kind' = 'dust' THEN
            UPDATE public.profiles SET fine_dust_balance = fine_dust_balance + (v_reward->>'amount')::INT WHERE id = v_user_id;
        ELSIF v_reward->>'kind' = 'hi' THEN
            UPDATE public.profiles SET historical_influence = historical_influence + (v_reward->>'amount')::INT WHERE id = v_user_id;
        ELSIF v_reward->>'kind' = 'title' THEN
             UPDATE public.profiles 
             SET unlocked_titles = array_append(COALESCE(unlocked_titles, '{}'), (v_reward->>'id')) 
             WHERE id = v_user_id AND NOT (COALESCE(unlocked_titles, '{}') @> ARRAY[(v_reward->>'id')]);
        ELSIF v_reward->>'kind' = 'cosmetic' THEN
             UPDATE public.profiles 
             SET unlocked_cosmetics = array_append(COALESCE(unlocked_cosmetics, '{}'), (v_reward->>'id')) 
             WHERE id = v_user_id AND NOT (COALESCE(unlocked_cosmetics, '{}') @> ARRAY[(v_reward->>'id')]);
        END IF;
    END LOOP;

    -- Mark Claimed
    UPDATE public.player_quests SET status = 'CLAIMED', updated_at = NOW() WHERE id = p_quest_db_id;

    -- Auto-Assign Next Quest (Simulated Chain)
    FOR v_next_id IN 
        SELECT id FROM public.quest_definitions 
        WHERE (requirements->>'prereq') = v_quest.quest_id
    LOOP
        IF NOT EXISTS (SELECT 1 FROM public.player_quests WHERE user_id = v_user_id AND quest_id = v_next_id) THEN
            INSERT INTO public.player_quests (user_id, quest_id, status) VALUES (v_user_id, v_next_id, 'AVAILABLE');
        END IF;
    END LOOP;
    
    -- Special Case for Auto-Completing Field Agent if triggered
    IF v_quest.quest_id = 'archive_onboard_09' THEN
         PERFORM public.internal_increment_quest_objective(v_user_id, 'complete_onboarding', 1);
    END IF;

    RETURN jsonb_build_object('success', true);
END;
$$;
