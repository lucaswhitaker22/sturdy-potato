-- 20240118000001_micro_loop_fix.sql

-- 1. rpc_sift_v3: Unifies Heatmaps and Shatter & Salvage
CREATE OR REPLACE FUNCTION public.rpc_sift_v3(
    p_user_id UUID DEFAULT NULL,
    p_tethers_used INT DEFAULT 0,
    p_zone INT DEFAULT 0 -- Kept for signature compatibility, unused in favor of profile zone
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
    
    -- Shatter & Salvage
    v_stage INT;
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
    
    -- 1. Calculate Penalty (Heatmaps)
    IF v_crate.source_static_tier = 'HIGH' THEN v_stability_penalty := 0.05;
    ELSIF v_crate.source_static_tier = 'MED' THEN v_stability_penalty := 0.025;
    END IF;

    -- Survey Mitigation
    IF v_profile.last_survey_at IS NOT NULL AND v_profile.last_survey_at > NOW() - INTERVAL '10 minutes' THEN
        v_survey_active := TRUE;
        v_stability_penalty := v_stability_penalty * 0.5;
    END IF;

    -- 2. Base Stability
    CASE v_stage
        WHEN 0 THEN v_base_stability := 0.90;
        WHEN 1 THEN v_base_stability := 0.75;
        WHEN 2 THEN v_base_stability := 0.50;
        WHEN 3 THEN v_base_stability := 0.25;
        WHEN 4 THEN v_base_stability := 0.10;
        ELSE v_base_stability := 0;
    END CASE;

    -- 3. Tether Bonus
    v_bonus_stability := p_tethers_used * 0.15;
    
    -- 4. Final Calc
    v_final_stability := v_base_stability + v_bonus_stability - v_stability_penalty;
    -- Restoration Level Bonus (small base bonus)
    v_final_stability := v_final_stability + (public.get_level(v_profile.restoration_xp) * 0.001);
    
    v_final_stability := GREATEST(0.01, LEAST(0.99, v_final_stability));

    -- 5. Roll
    v_roll := random();
    v_success := v_roll < v_final_stability;

    IF v_success THEN
        -- Level Up Stage
        UPDATE public.lab_state SET current_stage = current_stage + 1 WHERE user_id = v_user_id;
        
        -- XP Gain (Base 15 + Stage Bonus)
        v_xp_gain := 15 + (v_stage * 10);
        UPDATE public.profiles SET restoration_xp = restoration_xp + v_xp_gain WHERE id = v_user_id;
        
        RETURN jsonb_build_object(
            'success', true, 
            'outcome', 'SUCCESS', 
            'new_stage', v_stage + 1,
            'xp_gain', v_xp_gain,
            'penalty_applied', v_stability_penalty
        );
    ELSE
        -- CHECK FOR SALVAGE (Shatter & Salvage)
        
        -- Fragment Alchemist Perk (Smelting)
        IF v_profile.smelting_branch = 'fragment_alchemist' THEN
            v_fragment_chance := v_fragment_chance + 0.10; -- +10%
        END IF;

        -- Generate Salvage Token
        v_salvage_token := gen_random_uuid();
        
        -- Calculate Potential Salvage
        -- Dust: Stage 1-2 gives dust back
        IF v_stage >= 1 AND v_stage <= 2 THEN
            v_pending_dust := 5 + (v_stage * 5); -- Simple dust return
        END IF;
        
        -- Fragment: Stage 3+ gives chance
        IF v_stage >= 3 AND random() < v_fragment_chance THEN
            v_pending_fragment := TRUE;
        END IF;

        -- Update Lab State (Failed)
        UPDATE public.lab_state SET 
            is_active = FALSE, 
            current_stage = 0, 
            last_action_at = NOW(),
            salvage_token = v_salvage_token,
            salvage_expires_at = NOW() + INTERVAL '1.15 seconds',
            pending_salvage_dust = v_pending_dust,
            pending_salvage_fragment = v_pending_fragment
        WHERE user_id = v_user_id;
        
        -- Remove Crate
        UPDATE public.profiles SET 
            tray_count = GREATEST(0, tray_count - 1),
            crate_tray = array_remove(crate_tray, v_lab.active_crate)
        WHERE id = v_user_id;
        
        RETURN jsonb_build_object(
            'success', true, 
            'outcome', 'SHATTERED',
            'salvage_token', v_salvage_token,
            'salvage_expires_at', (NOW() + INTERVAL '1.15 seconds'),
            'pending_dust', v_pending_dust,
            'pending_fragment', v_pending_fragment
        );
    END IF;
END;
$$;


-- 2. rpc_extract_v7: Unifies Seismic Surge and Perks
CREATE OR REPLACE FUNCTION public.rpc_extract_v7(payload JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := public.get_auth_user((payload->>'p_user_id')::UUID);
    v_profile RECORD;
    v_seismic_grade TEXT := payload->>'p_seismic_grade'; -- Comma separated if multiple
    
    -- Base Constants
    v_base_scrap INT := 5;
    v_base_xp INT := 25;
    v_crate_chance FLOAT := 0.25;
    
    -- Bonuses
    v_drop_bonus FLOAT := 0;
    v_xp_bonus INT := 0;
    v_double_loot BOOLEAN := FALSE;
    
    -- Grades
    v_grades TEXT[];
    v_g TEXT;
    
    -- Outcomes
    v_crate_dropped BOOLEAN := FALSE;
    v_scrap_gain INT;
    v_new_balance INT;
    v_new_xp INT;
    v_final_crate_tray UUID[];
    v_new_crate_id UUID;
    
BEGIN
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated');
    END IF;

    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    
    -- Cooldown Check
    IF v_profile.last_extract_at IS NOT NULL AND v_profile.last_extract_at > NOW() - INTERVAL '2 seconds' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Cooldown active');
    END IF;

    -- 1. Parse Seismic Grades
    IF v_seismic_grade IS NOT NULL THEN
        v_grades := string_to_array(v_seismic_grade, ',');
        
        FOREACH v_g IN ARRAY v_grades LOOP
            IF v_g = 'PERFECT' THEN
                v_drop_bonus := v_drop_bonus + 0.05;
                v_xp_bonus := v_xp_bonus + 15;
            ELSIF v_g = 'HIT' THEN
                v_drop_bonus := v_drop_bonus + 0.02;
                v_xp_bonus := v_xp_bonus + 5;
            END IF;
        END LOOP;
        
        -- Endless Vein (Mastery Perk): Dual hits
        IF array_length(v_grades, 1) > 1 AND public.get_level(v_profile.excavation_xp) >= 99 THEN
            IF random() < 0.15 THEN
                v_double_loot := TRUE;
            END IF;
        END IF;
    END IF;

    -- 2. Apply Zone Heat Bonus
    -- Using get_zone_static utility from previous migrations
    IF public.get_zone_static(v_profile.active_zone_id) > 0.66 THEN -- HIGH
        v_drop_bonus := v_drop_bonus + 0.10;
    END IF;

    -- 3. Roll for Crate
    v_crate_chance := v_crate_chance + v_drop_bonus;
    
    -- Ensure Tray capacity
    IF v_profile.tray_count < 3 THEN -- Hardcoded cap for now, could be dynamic
        IF random() < v_crate_chance THEN
            v_crate_dropped := TRUE;
            
            -- Insert Crate
            INSERT INTO public.vault_items (
                user_id, item_id, tier, 
                source_zone_id, source_static_tier
            ) VALUES (
                v_user_id, 
                'mysterious_crate', -- placeholder, real logic usually selects tier
                1,
                v_profile.active_zone_id,
                CASE 
                    WHEN public.get_zone_static(v_profile.active_zone_id) > 0.66 THEN 'HIGH'
                    WHEN public.get_zone_static(v_profile.active_zone_id) > 0.33 THEN 'MED'
                    ELSE 'LOW'
                END
            ) RETURNING id INTO v_new_crate_id;
            
            -- Update Profile Tray
            UPDATE public.profiles SET 
                tray_count = tray_count + 1,
                crate_tray = array_append(crate_tray, v_new_crate_id)
            WHERE id = v_user_id;
            
            -- Double Loot (Mastery) logic would go here (repeat insert)
            IF v_double_loot AND v_profile.tray_count < 2 THEN
                 INSERT INTO public.vault_items (
                    user_id, item_id, tier, source_zone_id, source_static_tier
                ) VALUES (
                    v_user_id, 'mysterious_crate', 1, v_profile.active_zone_id, 'LOW'
                );
                UPDATE public.profiles SET tray_count = tray_count + 1 WHERE id = v_user_id; -- Simplified array append logic needed if strict
            END IF;
        END IF;
    END IF;

    -- 4. Give Rewards
    v_scrap_gain := v_base_scrap; 
    -- Double scrap on double loot? Or just crates? Let's say crates.
    
    -- XP
    v_new_xp := v_profile.excavation_xp + v_base_xp + v_xp_bonus;
    v_new_balance := v_profile.scrap_balance + v_scrap_gain;
    
    UPDATE public.profiles SET 
        scrap_balance = v_new_balance,
        excavation_xp = v_new_xp,
        last_extract_at = NOW()
    WHERE id = v_user_id
    RETURNING crate_tray INTO v_final_crate_tray;

    RETURN jsonb_build_object(
        'success', true,
        'result', CASE WHEN v_crate_dropped THEN 'CRATE_FOUND' ELSE 'SCRAP_FOUND' END,
        'scrap_gain', v_scrap_gain,
        'new_balance', v_new_balance,
        'new_xp', v_new_xp,
        'crate_dropped', v_crate_dropped,
        'crate_tray', v_final_crate_tray
    );
END;
$$;

NOTIFY pgrst, 'reload schema';
