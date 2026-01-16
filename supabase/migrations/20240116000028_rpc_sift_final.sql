
-- Resolve rpc_sift overloads definitively
DROP FUNCTION IF EXISTS public.rpc_sift CASCADE;

CREATE OR REPLACE FUNCTION public.rpc_sift(
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

    -- 1. CALCULATE COST & DEDUCT DUST
    IF p_tethers_used > 0 THEN
        CASE v_stage
            WHEN 0 THEN v_tether_cost := 0;
            WHEN 1 THEN v_tether_cost := 2;
            WHEN 2 THEN v_tether_cost := 3;
            WHEN 3 THEN v_tether_cost := 5;
            WHEN 4 THEN v_tether_cost := 8;
            WHEN 5 THEN v_tether_cost := 12;
            ELSE v_tether_cost := 12;
        END CASE;
        
        v_tether_cost := CEIL(v_tether_cost::FLOAT * GREATEST(0.6, 1.0 - (v_restoration_level * 0.004)))::INT;
        v_total_cost := v_tether_cost * p_tethers_used;
        
        IF COALESCE(v_profile.fine_dust_balance, 0) < v_total_cost THEN
            RETURN jsonb_build_object('success', false, 'error', 'Insufficient Fine Dust');
        END IF;
        
        UPDATE public.profiles 
        SET fine_dust_balance = fine_dust_balance - v_total_cost 
        WHERE id = v_user_id;
    END IF;

    -- 2. CALCULATE SUCCESS CHANCE
    CASE v_stage
        WHEN 0 THEN v_base_stability := 0.90;
        WHEN 1 THEN v_base_stability := 0.75;
        WHEN 2 THEN v_base_stability := 0.50;
        WHEN 3 THEN v_base_stability := 0.25;
        WHEN 4 THEN v_base_stability := 0.10;
        ELSE v_base_stability := 0;
    END CASE;

    v_bonus_stability := v_restoration_level * 0.001;
    v_overclock_bonus := COALESCE(v_profile.overclock_bonus, 0);
    v_final_stability := v_base_stability + v_bonus_stability + v_overclock_bonus;

    v_roll := random();
    v_success := v_roll < v_final_stability;

    IF v_success THEN
        v_xp_gain := (v_stage + 1) * 10;
        UPDATE public.lab_state SET current_stage = current_stage + 1, last_action_at = NOW() WHERE user_id = v_user_id;
        UPDATE public.profiles SET restoration_xp = restoration_xp + v_xp_gain WHERE id = v_user_id;
        
        RETURN jsonb_build_object(
            'success', true, 
            'outcome', 'SUCCESS', 
            'new_stage', v_stage + 1, 
            'xp_gain', v_xp_gain
        );
    ELSE
        -- FAILURE FLOW
        CASE v_stage
            WHEN 0 THEN v_base_crit_chance := 0.00;
            WHEN 1 THEN v_base_crit_chance := 0.05;
            WHEN 2 THEN v_base_crit_chance := 0.07;
            WHEN 3 THEN v_base_crit_chance := 0.10;
            WHEN 4 THEN v_base_crit_chance := 0.15;
            WHEN 5 THEN v_base_crit_chance := 0.20;
            ELSE v_base_crit_chance := 0.20;
        END CASE;
        
        IF p_zone = 0 THEN v_zone_mult := 0.35; ELSE v_zone_mult := 1.0; END IF;
        v_tether_mult := POWER(0.8, p_tethers_used);
        v_final_crit_chance := v_base_crit_chance * v_zone_mult * v_tether_mult;
        IF v_final_crit_chance > 0.90 THEN v_final_crit_chance := 0.90; END IF;
        
        v_fail_roll := random();
        v_is_critical := v_fail_roll < v_final_crit_chance;
        
        IF v_is_critical THEN
            UPDATE public.lab_state SET 
                is_active = FALSE, 
                current_stage = 0, 
                last_action_at = NOW(),
                salvage_token = NULL,
                salvage_expires_at = NULL,
                pending_salvage_dust = 0,
                pending_salvage_fragment = FALSE
            WHERE user_id = v_user_id;
            UPDATE public.profiles SET tray_count = GREATEST(0, tray_count - 1) WHERE id = v_user_id;
            
            RETURN jsonb_build_object(
                'success', true, 
                'outcome', 'SHATTERED',
                'critical', true
            );
        ELSE
            v_dust_payout := (v_stage * 2) + 3;
            
            -- Salvage Logic
            IF v_stage >= 1 AND v_stage <= 2 THEN
                v_pending_dust := v_dust_payout;
            ELSIF v_stage >= 3 THEN
                IF random() < 0.25 THEN -- Increased chance for testing
                    v_pending_fragment := TRUE;
                END IF;
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

GRANT EXECUTE ON FUNCTION public.rpc_sift(UUID, INT, INT) TO anon, authenticated, service_role;
NOTIFY pgrst, 'reload schema';
