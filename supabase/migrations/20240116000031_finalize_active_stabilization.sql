-- 20240116000031_finalize_active_stabilization.sql

-- Consolidate rpc_sift_v2 with all mechanics: Tethers, Zones, Static Heat, and Shatter Salvage
CREATE OR REPLACE FUNCTION public.rpc_sift_v2(
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
    
    -- Mechanics
    v_base_stability FLOAT;
    v_bonus_stability FLOAT;
    v_final_stability FLOAT;
    v_roll FLOAT;
    v_success BOOLEAN;
    
    -- Static Heat (Excavation Expansion)
    v_static_heat FLOAT := 0;
    v_survey_active BOOLEAN := FALSE;
    v_stability_penalty FLOAT := 0;
    
    -- Rewards
    v_xp_gain INT := 0;
    v_restoration_level INT;
    v_overclock_bonus FLOAT := 0;
    
    -- Active Stabilization / Shatter Salvage
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
    
    -- Salvage Vars
    v_salvage_token UUID := NULL;
    v_pending_fragment BOOLEAN := FALSE;
    v_pending_dust INT := 0;
    
BEGIN
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated');
    END IF;

    -- Ensure profile exists
    INSERT INTO public.profiles (id) VALUES (v_user_id) ON CONFLICT (id) DO NOTHING;

    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    SELECT * INTO v_lab FROM public.lab_state WHERE user_id = v_user_id;
    
    IF v_lab IS NULL OR NOT v_lab.is_active THEN
        RETURN jsonb_build_object('success', false, 'error', 'No active crate in lab');
    END IF;

    v_stage := v_lab.current_stage;
    v_restoration_level := public.get_level(COALESCE(v_profile.restoration_xp, 0));
    v_overclock_bonus := COALESCE(v_profile.overclock_bonus, 0);

    -- 1. CALCULATE COST & DEDUCT DUST
    CASE v_stage
        WHEN 0 THEN v_tether_cost := 0;
        WHEN 1 THEN v_tether_cost := 2;
        WHEN 2 THEN v_tether_cost := 3;
        WHEN 3 THEN v_tether_cost := 5;
        WHEN 4 THEN v_tether_cost := 8;
        WHEN 5 THEN v_tether_cost := 12;
        ELSE v_tether_cost := 20;
    END CASE;

    -- Application of Restoration discount (1% per level, max 40%)
    v_tether_cost := CEIL(v_tether_cost * (1 - LEAST(0.4, v_restoration_level * 0.004)));
    v_total_cost := v_tether_cost * p_tethers_used;

    IF v_profile.fine_dust_balance < v_total_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient Fine Dust');
    END IF;

    -- 2. CALCULATE STABILITY (SUCCESS CHANCE)
    CASE v_stage
        WHEN 0 THEN v_base_stability := 0.90;
        WHEN 1 THEN v_base_stability := 0.75;
        WHEN 2 THEN v_base_stability := 0.50;
        WHEN 3 THEN v_base_stability := 0.25;
        WHEN 4 THEN v_base_stability := 0.10;
        ELSE v_base_stability := 0;
    END CASE;

    -- Add restoration bonus (Restoration Level * 0.1%)
    v_bonus_stability := v_restoration_level * 0.001;
    
    -- STATIC HEAT PENALTY (Excavation Expansion integration)
    v_static_heat := COALESCE(public.get_zone_static(v_profile.active_zone_id), 0);
    IF v_profile.last_survey_at IS NOT NULL AND v_profile.last_survey_at > NOW() - INTERVAL '10 minutes' THEN
        v_survey_active := TRUE;
    END IF;

    v_stability_penalty := v_static_heat * 0.05;
    IF v_survey_active THEN
        v_stability_penalty := v_stability_penalty * 0.5;
    END IF;

    v_final_stability := (v_base_stability + v_bonus_stability + v_overclock_bonus) - v_stability_penalty;

    -- Roll for success
    v_roll := random();
    v_success := v_roll < v_final_stability;

    IF v_success THEN
        -- Advance stage
        v_xp_gain := (v_stage + 1) * 25;
        UPDATE public.lab_state SET 
            current_stage = v_stage + 1,
            last_action_at = NOW()
        WHERE user_id = v_user_id;
        
        UPDATE public.profiles SET 
            restoration_xp = restoration_xp + v_xp_gain,
            fine_dust_balance = fine_dust_balance - v_total_cost
        WHERE id = v_user_id;

        RETURN jsonb_build_object(
            'success', true, 
            'outcome', 'SUCCESS', 
            'new_stage', v_stage + 1,
            'xp_gain', v_xp_gain,
            'stability_used', v_final_stability
        );
    ELSE
        -- 3. FAILURE SEVERITY (TRIAGE)
        v_base_crit_chance := (v_stage + 1) * 0.10; -- 10% base per stage
        
        -- Zone Multiplier
        IF p_zone = 1 THEN
            v_zone_mult := (v_stage + 1)::FLOAT; -- High risk in Danger zone
        ELSE
            v_zone_mult := 1.0; -- Standard risk in Safe zone
        END IF;

        -- Tether Multiplier
        v_tether_mult := POWER(0.5, p_tethers_used);
        
        v_final_crit_chance := LEAST(0.95, v_base_crit_chance * v_zone_mult * v_tether_mult);
        
        v_fail_roll := random();
        v_is_critical := v_fail_roll < v_final_crit_chance;

        -- Deduct dust for tethers used regardless of outcome
        UPDATE public.profiles SET fine_dust_balance = fine_dust_balance - v_total_cost WHERE id = v_user_id;

        IF v_is_critical THEN
            -- CRITICAL FAIL (SHATTERED)
            UPDATE public.lab_state SET 
                is_active = FALSE, 
                current_stage = 0, 
                last_action_at = NOW() 
            WHERE user_id = v_user_id;
            
            UPDATE public.profiles SET 
                tray_count = GREATEST(0, tray_count - 1) 
            WHERE id = v_user_id;

            RETURN jsonb_build_object(
                'success', true, 
                'outcome', 'SHATTERED',
                'critical', true,
                'crit_chance', v_final_crit_chance
            );
        ELSE
            -- STANDARD FAIL (STABILIZED)
            v_dust_payout := (v_stage * 2) + 3;
            
            -- Shatter Salvage Fragment Chance (25% at Stage 3+)
            IF v_stage >= 3 AND random() < 0.25 THEN
                v_pending_fragment := TRUE;
            END IF;
            
            -- Salvage Dust Payout (Stage 1-2 only)
            IF v_stage >= 1 AND v_stage <= 2 THEN
                v_pending_dust := v_dust_payout;
            END IF;

            v_salvage_token := gen_random_uuid();
            
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
                fine_dust_balance = fine_dust_balance + v_dust_payout
            WHERE id = v_user_id;
            
            RETURN jsonb_build_object(
                'success', true, 
                'outcome', 'STABILIZED_FAIL',
                'critical', false,
                'dust_payout', v_dust_payout,
                'salvage_token', v_salvage_token,
                'salvage_expires_at', (NOW() + INTERVAL '1.15 seconds'),
                'pending_dust', v_pending_dust,
                'pending_fragment', v_pending_fragment,
                'new_dust_balance', (SELECT fine_dust_balance FROM public.profiles WHERE id = v_user_id)
            );
        END IF;
    END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.rpc_sift_v2(UUID, INT, INT) TO anon, authenticated, service_role;
NOTIFY pgrst, 'reload schema';
