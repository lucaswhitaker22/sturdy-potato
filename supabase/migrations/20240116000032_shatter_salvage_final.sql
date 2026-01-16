-- 20240116000032_shatter_salvage_final.sql

-- 1. Add smelting_branch if not exists
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS smelting_branch TEXT DEFAULT NULL;

-- 2. Refined rpc_sift_v3 (with Fragment Alchemist logic)
-- We'll version it as v3 to avoid any conflicts with existing v2 if it's being used
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
    v_fragment_chance FLOAT := 0.25; -- Base 25% at Stage 3+
    
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
    
    -- 1. Cost check
    v_tether_cost := public.get_tether_cost(v_stage, v_restoration_level); -- Assumes this helper exists or we inline
    -- Inlining get_tether_cost logic for robustness
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

    -- 2. Stability Logic
    -- Stage base: 90, 75, 50, 25, 10
    IF v_stage = 0 THEN v_base_stability := 0.90;
    ELSIF v_stage = 1 THEN v_base_stability := 0.75;
    ELSIF v_stage = 2 THEN v_base_stability := 0.50;
    ELSIF v_stage = 3 THEN v_base_stability := 0.25;
    ELSIF v_stage = 4 THEN v_base_stability := 0.10;
    ELSE v_base_stability := 0.05;
    END IF;

    v_overclock_bonus := COALESCE(v_profile.overclock_bonus, 0);
    v_bonus_stability := (v_restoration_level * 0.001) + v_overclock_bonus;
    
    -- Static Heat Penalty
    v_static_heat := COALESCE(v_lab.active_crate->'contents'->>'found_in_static_intensity', '0')::FLOAT;
    v_survey_active := COALESCE(v_profile.last_survey_at > NOW() - INTERVAL '10 minutes', FALSE);
    v_stability_penalty := v_static_heat * 0.05;
    IF v_survey_active THEN v_stability_penalty := v_stability_penalty * 0.5; END IF;
    
    v_final_stability := GREATEST(0.01, v_base_stability + v_bonus_stability - v_stability_penalty);
    
    -- Roll
    v_roll := random();
    v_success := v_roll < v_final_stability;

    IF v_success THEN
        -- SUCCESS
        v_xp_gain := (v_stage + 1) * 10;
        UPDATE public.lab_state SET 
            current_stage = current_stage + 1, 
            last_action_at = NOW(),
            salvage_token = NULL -- Clear any old tokens
        WHERE user_id = v_user_id;
        
        UPDATE public.profiles SET 
            restoration_xp = restoration_xp + v_xp_gain,
            fine_dust_balance = fine_dust_balance - v_total_cost
        WHERE id = v_user_id;
        
        RETURN jsonb_build_object(
            'success', true, 
            'outcome', 'SUCCESS', 
            'new_stage', v_stage + 1,
            'xp_gain', v_xp_gain
        );
    ELSE
        -- FAILURE
        -- 3. Determine if Critical Shatter
        v_base_crit_chance := 0.20; -- 20% base fail -> crit
        v_zone_mult := 1.0;
        v_tether_mult := 1.0;
        
        IF p_zone = 1 THEN v_zone_mult := 2.5; END IF; -- Danger Zone = 2.5x crit chance (50%)
        IF p_tethers_used > 0 THEN v_tether_mult := 0.5; END IF; -- Any tether used halves crit chance
        
        v_final_crit_chance := LEAST(0.9, v_base_crit_chance * v_zone_mult * v_tether_mult);
        
        v_fail_roll := random();
        v_is_critical := v_fail_roll < v_final_crit_chance;

        IF v_is_critical THEN
            -- CRITICAL FAIL (SHATTERED)
            UPDATE public.lab_state SET 
                is_active = FALSE, 
                current_stage = 0, 
                last_action_at = NOW(),
                salvage_token = NULL 
            WHERE user_id = v_user_id;
            
            UPDATE public.profiles SET 
                tray_count = GREATEST(0, tray_count - 1),
                fine_dust_balance = fine_dust_balance - v_total_cost
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
            
            -- Shatter Salvage Logic
            -- Fragment Alchemist Bonus: 25% -> 40% chance
            IF v_profile.smelting_branch = 'fragment_alchemist' THEN
                v_fragment_chance := 0.40;
            END IF;

            -- Fragment Chance (Stage 3+)
            IF v_stage >= 3 AND random() < v_fragment_chance THEN
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
                salvage_expires_at = NOW() + INTERVAL '1.15 seconds', -- 1.0s window + 150ms grace
                pending_salvage_dust = v_pending_dust,
                pending_salvage_fragment = v_pending_fragment
            WHERE user_id = v_user_id;
            
            UPDATE public.profiles SET 
                tray_count = GREATEST(0, tray_count - 1),
                fine_dust_balance = fine_dust_balance + v_dust_payout - v_total_cost
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

-- Grant Execution (re-grant just in case)
GRANT EXECUTE ON FUNCTION public.rpc_sift_v2(UUID, INT, INT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.rpc_shatter_salvage(UUID, UUID) TO anon, authenticated, service_role;
NOTIFY pgrst, 'reload schema';
