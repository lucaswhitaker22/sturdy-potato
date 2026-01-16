-- 20240116000040_skill_patches.sql

-- 1. Patch rpc_sift_v2 to apply Fragment Alchemist Time Bonus
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
    v_base_stability FLOAT;
    v_bonus_stability FLOAT;
    v_final_stability FLOAT;
    v_roll FLOAT;
    v_success BOOLEAN;
    v_static_heat FLOAT := 0;
    v_survey_active BOOLEAN := FALSE;
    v_stability_penalty FLOAT := 0;
    v_xp_gain INT := 0;
    v_restoration_level INT;
    v_overclock_bonus FLOAT := 0;
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
    v_fragment_chance FLOAT := 0.25;
    v_salvage_window_bonus INTERVAL := '0 seconds';
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    SELECT * INTO v_lab FROM public.lab_state WHERE user_id = v_user_id;

    IF v_lab IS NULL OR NOT v_lab.is_active THEN RETURN jsonb_build_object('success', false, 'error', 'No active crate'); END IF;

    v_stage := v_lab.current_stage;
    v_restoration_level := public.get_level(COALESCE(v_profile.restoration_xp, 0));

    -- TETHER COST
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

        UPDATE public.profiles SET fine_dust_balance = fine_dust_balance - v_total_cost WHERE id = v_user_id;
    END IF;

    -- STABILITY CALCULATION
    IF v_stage = 0 THEN v_base_stability := 0.90;
    ELSIF v_stage = 1 THEN v_base_stability := 0.75;
    ELSIF v_stage = 2 THEN v_base_stability := 0.50;
    ELSIF v_stage = 3 THEN v_base_stability := 0.25;
    ELSIF v_stage = 4 THEN v_base_stability := 0.10;
    ELSE v_base_stability := 0.05;
    END IF;

    v_bonus_stability := v_restoration_level * 0.001;

    -- RESTORATION BRANCH BONUSES
    IF v_profile.restoration_branch = 'master_preserver' AND v_stage <= 3 THEN
        v_bonus_stability := v_bonus_stability + 0.03; -- +3% Early
    ELSIF v_profile.restoration_branch = 'swift_handler' AND v_stage >= 4 THEN
        v_bonus_stability := v_bonus_stability + 0.02; -- +2% Late
    END IF;

    v_static_heat := COALESCE(v_lab.active_crate->'contents'->>'found_in_static_intensity', '0')::FLOAT;
    v_stability_penalty := v_static_heat * 0.05;
    IF v_profile.is_focused_survey_active THEN v_stability_penalty := v_stability_penalty * 0.5; END IF;

    v_final_stability := GREATEST(0.01, v_base_stability + v_bonus_stability - v_stability_penalty);

    v_roll := random();
    v_success := v_roll < v_final_stability;

    IF v_success THEN
         v_xp_gain := (v_stage + 1) * 10;
        UPDATE public.lab_state SET current_stage = current_stage + 1, last_action_at = NOW(), salvage_token = NULL WHERE user_id = v_user_id;
        UPDATE public.profiles SET restoration_xp = restoration_xp + v_xp_gain WHERE id = v_user_id;

        RETURN jsonb_build_object('success', true, 'outcome', 'SUCCESS', 'new_stage', v_stage + 1, 'xp_gain', v_xp_gain);
    ELSE
        -- FAIL
        
        -- Fragment Alchemist Time Bonus Check
        IF v_profile.smelting_branch = 'fragment_alchemist' THEN
            v_salvage_window_bonus := '0.25 seconds';
        END IF;

        v_base_crit_chance := 0.20;
        IF p_zone = 1 THEN v_zone_mult := 2.5; ELSE v_zone_mult := 0.0; END IF; -- 0 mult if safe zone
        IF p_tethers_used > 0 THEN v_tether_mult := 0.5; ELSE v_tether_mult := 1.0; END IF;
        
        v_final_crit_chance := LEAST(0.9, v_base_crit_chance * v_zone_mult * v_tether_mult);
        v_final_crit_chance := v_final_crit_chance + (v_static_heat * 0.10);

        v_fail_roll := random();
        v_is_critical := v_fail_roll < v_final_crit_chance;

        IF v_is_critical THEN
             -- SHATTER
             v_salvage_token := gen_random_uuid();
             UPDATE public.lab_state 
                SET is_active = FALSE, 
                    current_stage = 0, 
                    last_action_at = NOW(), 
                    salvage_token = v_salvage_token, 
                    salvage_expires_at = NOW() + INTERVAL '1.0 seconds' + v_salvage_window_bonus, 
                    pending_salvage_dust = 0, 
                    pending_salvage_fragment = FALSE 
                WHERE user_id = v_user_id;
                
             UPDATE public.profiles SET tray_count = GREATEST(0, tray_count - 1) WHERE id = v_user_id;

             RETURN jsonb_build_object('success', true, 'outcome', 'SHATTERED', 'critical', true, 'salvage_token', v_salvage_token);
        ELSE
             -- STABILIZED (Standard Fail)
             v_dust_payout := (v_stage * 2) + 3;

             -- SMELTING BRANCH: Fragment Alchemist (+10% Dust)
             IF v_profile.smelting_branch = 'fragment_alchemist' AND v_stage >= 3 THEN
                v_dust_payout := floor(v_dust_payout * 1.10)::INT;
             END IF;

             IF v_profile.smelting_branch = 'fragment_alchemist' THEN v_fragment_chance := 0.40; END IF;
             IF v_stage >= 3 AND random() < v_fragment_chance THEN v_pending_fragment := TRUE; END IF;
             IF v_stage >= 1 AND v_stage <= 2 THEN v_pending_dust := v_dust_payout; END IF;

             v_salvage_token := gen_random_uuid();
             UPDATE public.lab_state 
                SET is_active = FALSE, 
                    current_stage = 0, 
                    last_action_at = NOW(), 
                    salvage_token = v_salvage_token, 
                    salvage_expires_at = NOW() + INTERVAL '1.15 seconds' + v_salvage_window_bonus, 
                    pending_salvage_dust = v_pending_dust, 
                    pending_salvage_fragment = v_pending_fragment 
                WHERE user_id = v_user_id;
                
             UPDATE public.profiles SET tray_count = GREATEST(0, tray_count - 1), fine_dust_balance = fine_dust_balance + v_dust_payout WHERE id = v_user_id;

             RETURN jsonb_build_object('success', true, 'outcome', 'STABILIZED_FAIL', 'critical', false, 'dust_payout', v_dust_payout, 'salvage_token', v_salvage_token, 'new_dust_balance', (v_profile.fine_dust_balance + v_dust_payout));
        END IF;
    END IF;
END;
$$;

-- 2. Patch rpc_appraise_crate to include Market Maker bonus
CREATE OR REPLACE FUNCTION public.rpc_appraise_crate(p_crate_id UUID, p_user_id UUID DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := COALESCE(p_user_id, auth.uid());
    v_profile RECORD;
    v_player_level INT;
    v_crate JSONB;
    v_contents JSONB;
    v_found BOOLEAN := FALSE;
    v_new_tray JSONB := '[]'::JSONB;
    v_cost INT;
    v_success_roll FLOAT := random();
    v_success_chance FLOAT;
    v_success BOOLEAN;
    v_intel JSONB := '[]'::JSONB;
    
    -- Intel values
    v_item_def RECORD;
    v_approx_hv INT;
    v_condition_mult FLOAT := 1.0;
    v_prismatic_mult FLOAT := 1.0;
    v_mint_mult FLOAT := 1.0;
    v_zone_id TEXT;
    v_trends TEXT[];
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;

    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    IF v_profile IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Profile not found'); END IF;

    v_player_level := public.get_level(COALESCE(v_profile.appraisal_xp, 0));
    v_zone_id := COALESCE(v_profile.active_zone_id, 'industrial_zone');
    
    -- 1. Cost & Chance Scaling
    v_cost := 50 + (v_player_level * 50);
    
    IF v_player_level >= 99 THEN
        v_success_chance := 0.90;
    ELSIF v_player_level >= 61 THEN
        v_success_chance := 0.70 + (v_player_level - 60) * 0.004;
    ELSIF v_player_level >= 31 THEN
        v_success_chance := 0.50 + (v_player_level - 30) * 0.006;
    ELSE
        v_success_chance := 0.30 + (v_player_level * 0.0067);
    END IF;

    IF v_profile.scrap_balance < v_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient Scrap');
    END IF;

    -- 2. Locate Crate
    FOR v_crate IN SELECT jsonb_array_elements(v_profile.crate_tray) LOOP
        IF (v_crate->>'id')::UUID = p_crate_id THEN
            v_found := TRUE;
            v_contents := v_crate->'contents';

            IF (v_crate->>'appraised')::BOOLEAN = TRUE AND v_player_level < 99 THEN
                 RETURN jsonb_build_object('success', false, 'error', 'Crate already appraised');
            END IF;

            -- 3. Resolve Appraisal
            v_success := (v_success_roll < v_success_chance);
            
            IF v_success THEN
                -- A. Basic Intel (Condition)
                v_intel := v_intel || jsonb_build_object('type', 'condition', 'label', 'Hull Integrity', 'value', upper(v_contents->>'condition'));

                -- B. Rarity / Tier Intel
                IF v_player_level >= 10 THEN
                    v_intel := v_intel || jsonb_build_object('type', 'rarity_match', 'label', 'Rarity Signature', 'value', 'COMMON DETECTED');
                END IF;

                -- C. Economic Intel (HV)
                IF v_player_level >= 30 THEN
                    SELECT * INTO v_item_def FROM public.item_definitions WHERE id = (v_contents->'items_by_tier'->>'common')::UUID;
                    IF v_item_def IS NOT NULL THEN
                        IF (v_contents->>'is_prismatic')::BOOLEAN THEN v_prismatic_mult := 3.0; END IF;
                        CASE v_contents->>'condition'
                            WHEN 'mint' THEN v_condition_mult := 2.5;
                            WHEN 'preserved' THEN v_condition_mult := 1.5;
                            WHEN 'weathered' THEN v_condition_mult := 1.0;
                            ELSE v_condition_mult := 0.5;
                        END CASE;
                        IF (v_contents->'mint_numbers'->>'common')::INT <= 10 THEN v_mint_mult := 1.5; END IF;
                        
                        v_approx_hv := floor(v_item_def.base_hv * v_condition_mult * v_prismatic_mult * v_mint_mult)::INT;
                        v_intel := v_intel || jsonb_build_object('type', 'exact_hv', 'label', 'Market Valuation', 'value', v_approx_hv || ' HV');
                    END IF;
                END IF;

                -- D. Sub-Stat Reveal (Level 60+)
                IF v_player_level >= 60 THEN
                    v_intel := v_intel || jsonb_build_object('type', 'sub_stats', 'label', 'Inner Affixes', 'value', 'Critical, Luck');
                END IF;

                -- E. The Oracle: Zone Trends (Level 99 OR Market Maker Branch)
                IF v_player_level >= 99 OR v_profile.appraisal_branch = 'market_maker' THEN
                    v_trends := public.rpc_helper_get_zone_trends(v_zone_id);
                    -- Differentiate label based on source
                    IF v_player_level >= 99 THEN
                         v_intel := v_intel || jsonb_build_object('type', 'zone_trends', 'label', 'Oracle Market Trends', 'value', array_to_string(v_trends, ', '));
                    ELSE
                         v_intel := v_intel || jsonb_build_object('type', 'zone_trends', 'label', 'Market Maker Prediction', 'value', array_to_string(v_trends, ', '));
                    END IF;
                END IF;
            END IF;

            v_crate := v_crate || jsonb_build_object('appraised', true, 'appraisal_success', v_success, 'intel', v_intel);
        END IF;
        v_new_tray := v_new_tray || v_crate;
    END LOOP;

    IF NOT v_found THEN
        RETURN jsonb_build_object('success', false, 'error', 'Crate not found in tray');
    END IF;

    UPDATE public.profiles 
    SET scrap_balance = scrap_balance - v_cost, crate_tray = v_new_tray 
    WHERE id = v_user_id;

    RETURN jsonb_build_object(
        'success', true, 
        'appraisal_success', v_success, 
        'intel', v_intel,
        'new_balance', (v_profile.scrap_balance - v_cost),
        'crate_tray', v_new_tray
    );
END;
$$;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;
NOTIFY pgrst, 'reload schema';
