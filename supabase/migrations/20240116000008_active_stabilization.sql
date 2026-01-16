-- Active Stabilization (Lab Triage) Implementation
-- 1. Add fine_dust_balance to profiles
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS fine_dust_balance BIGINT DEFAULT 0 CHECK (fine_dust_balance >= 0);

-- 2. Update rpc_sift to support Active Stabilization
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
    
    -- Active Stabilization
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
    
BEGIN
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated');
    END IF;

    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    SELECT * INTO v_lab FROM public.lab_state WHERE user_id = v_user_id;
    
    IF v_lab IS NULL OR NOT v_lab.is_active THEN
        RETURN jsonb_build_object('success', false, 'error', 'No active crate in lab');
    END IF;

    v_stage := v_lab.current_stage;
    v_restoration_level := public.get_level(COALESCE(v_profile.restoration_xp, 0));

    -- 1. CALCULATE COST & DEDUCT DUST
    IF p_tethers_used > 0 THEN
        -- Base cost per stage
        CASE v_stage
            WHEN 0 THEN v_tether_cost := 0; -- Should not happen (100% success)
            WHEN 1 THEN v_tether_cost := 2;
            WHEN 2 THEN v_tether_cost := 3;
            WHEN 3 THEN v_tether_cost := 5;
            WHEN 4 THEN v_tether_cost := 8;
            WHEN 5 THEN v_tether_cost := 12; -- Theoretical
            ELSE v_tether_cost := 12;
        END CASE;
        
        -- Restoration Discount: ceil(cost * (1 - (Level * 0.004)))
        -- Cap discount at 40% (Level 100 * 0.004 = 0.4)
        v_tether_cost := CEIL(v_tether_cost::FLOAT * GREATEST(0.6, 1.0 - (v_restoration_level * 0.004)))::INT;
        
        v_total_cost := v_tether_cost * p_tethers_used;
        
        IF COALESCE(v_profile.fine_dust_balance, 0) < v_total_cost THEN
            RETURN jsonb_build_object('success', false, 'error', 'Insufficient Fine Dust');
        END IF;
        
        -- Deduct Cost
        UPDATE public.profiles 
        SET fine_dust_balance = fine_dust_balance - v_total_cost 
        WHERE id = v_user_id;
    END IF;

    -- 2. CALCULATE SUCCESS CHANCE
    -- Base Stability per stage
    CASE v_stage
        WHEN 0 THEN v_base_stability := 0.90;
        WHEN 1 THEN v_base_stability := 0.75;
        WHEN 2 THEN v_base_stability := 0.50;
        WHEN 3 THEN v_base_stability := 0.25;
        WHEN 4 THEN v_base_stability := 0.10;
        ELSE v_base_stability := 0;
    END CASE;

    -- Level Bonus: +0.1% per level
    v_bonus_stability := v_restoration_level * 0.001;
    v_overclock_bonus := COALESCE(v_profile.overclock_bonus, 0);
    
    v_final_stability := v_base_stability + v_bonus_stability + v_overclock_bonus;

    -- Roll Success
    v_roll := random();
    v_success := v_roll < v_final_stability;

    IF v_success THEN
        -- SUCCESS FLOW
        v_xp_gain := (v_stage + 1) * 10;
        UPDATE public.lab_state SET current_stage = current_stage + 1, last_action_at = NOW() WHERE user_id = v_user_id;
        
        -- If complete (Stage 5 done), auto-claim logic is separate or user calls claim?
        -- Usually user calls claim after stage reaches target? 
        -- Existing logic just increments stage.
        
        RETURN jsonb_build_object(
            'success', true, 
            'outcome', 'SUCCESS', 
            'new_stage', v_stage + 1, 
            'xp_gain', v_xp_gain
        );
        
    ELSE
        -- FAILURE FLOW - Active Stabilization Triage
        
        -- Base Critical Chance
        CASE v_stage
            WHEN 0 THEN v_base_crit_chance := 0.00; -- No fail at 0?
            WHEN 1 THEN v_base_crit_chance := 0.05;
            WHEN 2 THEN v_base_crit_chance := 0.07;
            WHEN 3 THEN v_base_crit_chance := 0.10;
            WHEN 4 THEN v_base_crit_chance := 0.15;
            WHEN 5 THEN v_base_crit_chance := 0.20;
            ELSE v_base_crit_chance := 0.20;
        END CASE;
        
        -- Zone Multiplier (Safe=0 -> 0.35x, Danger=1 -> 1.0x)
        IF p_zone = 0 THEN
            v_zone_mult := 0.35;
        ELSE
            v_zone_mult := 1.0;
        END IF;
        
        -- Tether Multiplier (0.8 ^ count)
        v_tether_mult := POWER(0.8, p_tethers_used);
        
        -- Final Critical Chance
        v_final_crit_chance := v_base_crit_chance * v_zone_mult * v_tether_mult;
        
        -- Clamp 0% - 90%
        IF v_final_crit_chance > 0.90 THEN v_final_crit_chance := 0.90; END IF;
        
        -- Roll for Critical
        v_fail_roll := random();
        v_is_critical := v_fail_roll < v_final_crit_chance;
        
        IF v_is_critical THEN
            -- CRITICAL FAIL (SHATTERED)
            -- Destroy Crate, No Payout
            UPDATE public.lab_state SET is_active = FALSE, current_stage = 0, last_action_at = NOW() WHERE user_id = v_user_id;
            UPDATE public.profiles SET tray_count = GREATEST(0, tray_count - 1) WHERE id = v_user_id;
            
            RETURN jsonb_build_object(
                'success', true, 
                'outcome', 'SHATTERED',
                'critical', true,
                'dust_cost', COALESCE(v_total_cost, 0)
            );
        ELSE
            -- STANDARD FAIL
            -- Fail but "Stabilized".
            -- Grant Fine Dust Payout.
            -- Crate is still lost? "Standard Fail (Fine Dust payout)".
            -- Usually fails reset the loop.
            
            -- Dust Payout: Stage * 2 + 3 (Generous base to ensure positive loop for active play)
            v_dust_payout := (v_stage * 2) + 3;
            
            UPDATE public.lab_state SET is_active = FALSE, current_stage = 0, last_action_at = NOW() WHERE user_id = v_user_id;
            UPDATE public.profiles SET 
                tray_count = GREATEST(0, tray_count - 1),
                fine_dust_balance = fine_dust_balance + v_dust_payout
            WHERE id = v_user_id;
            
            RETURN jsonb_build_object(
                'success', true, 
                'outcome', 'STABILIZED_FAIL',
                'critical', false,
                'dust_payout', v_dust_payout,
                'dust_cost', COALESCE(v_total_cost, 0),
                'new_dust_balance', (SELECT fine_dust_balance FROM public.profiles WHERE id = v_user_id)
            );
        END IF;
    END IF;
END;
$$;
