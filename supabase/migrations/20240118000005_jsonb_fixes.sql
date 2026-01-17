-- 20240118000004_fix_verification_issues.sql
-- Fixes missing RPCs (rpc_get_lab_state) and type errors (uuid=jsonb, malformed array)
-- Ensures consistency for Quest System verification
-- UPDATED: Correctly handles JSONB types for crate_tray and active_crate

-- 1. Ensure rpc_get_lab_state exists (Was missing or returned 404)
CREATE OR REPLACE FUNCTION public.rpc_get_lab_state(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_lab RECORD;
    v_crate JSONB;
    v_crate_id UUID;
BEGIN
    IF p_user_id IS NULL THEN
         RETURN jsonb_build_object('success', true, 'lab_state', null);
    END IF;

    SELECT * INTO v_lab FROM public.lab_state WHERE user_id = p_user_id;
    
    IF v_lab IS NULL THEN
        RETURN jsonb_build_object('success', true, 'lab_state', null);
    END IF;

    -- Hydrate active crate info if present
    -- active_crate is JSONB, extract ID
    IF v_lab.active_crate IS NOT NULL THEN
        v_crate_id := (v_lab.active_crate->>'id')::UUID;
        
        IF v_crate_id IS NOT NULL THEN
            SELECT jsonb_build_object(
                'id', id,
                'item_id', item_id,
                'source_zone_id', source_zone_id,
                'source_static_tier', source_static_tier
            ) INTO v_crate
            FROM public.vault_items
            WHERE id = v_crate_id;
        END IF;
    END IF;

    RETURN jsonb_build_object('success', true, 'lab_state', jsonb_build_object(
        'is_active', v_lab.is_active,
        'current_stage', v_lab.current_stage,
        'active_crate', v_lab.active_crate, -- Return raw JSONB object as expected by some clients?
        'crate_info', v_crate -- Hydrated info
    ));
END;
$$;

-- 2. Hardened internal_increment_quest_objective (Fix uuid=jsonb error)
CREATE OR REPLACE FUNCTION public.internal_increment_quest_objective(
    p_user_id UUID,
    p_kind TEXT,
    p_amount INT DEFAULT 1,
    p_metadata JSONB DEFAULT '{}'::JSONB
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_quest RECORD;
    v_obj JSONB;
    v_current INT;
    v_target INT;
    v_all_complete BOOLEAN;
    v_needs_update BOOLEAN;
    v_progress JSONB;
    v_quest_uuid UUID;
BEGIN
    FOR v_quest IN 
        SELECT pq.id, pq.user_id, pq.quest_id, pq.status, pq.progress, qd.objectives 
        FROM public.player_quests pq
        JOIN public.quest_definitions qd ON pq.quest_id = qd.id
        WHERE pq.user_id = p_user_id 
        AND pq.status IN ('ACCEPTED') 
    LOOP
        v_needs_update := FALSE;
        v_progress := COALESCE(v_quest.progress, '{}'::JSONB);
        v_quest_uuid := v_quest.id; -- Ensure strict typing

        FOR v_obj IN SELECT * FROM jsonb_array_elements(v_quest.objectives) LOOP
            IF v_obj->>'kind' = p_kind THEN
                -- Check filters 
                IF (p_metadata->>'stage') IS NOT NULL AND (v_obj->>'stage_at_least') IS NOT NULL THEN
                    IF (p_metadata->>'stage')::INT < (v_obj->>'stage_at_least')::INT THEN
                       CONTINUE;
                    END IF;
                END IF;

                 v_current := COALESCE((v_progress->>(v_obj->>'kind'))::INT, 0);
                v_target := (v_obj->>'target')::INT;
                
                IF v_current < v_target THEN
                    v_current := v_current + p_amount;
                    v_progress := jsonb_set(v_progress, ARRAY[v_obj->>'kind'], to_jsonb(v_current));
                    v_needs_update := TRUE;
                END IF;
            END IF;
        END LOOP;

        IF v_needs_update THEN
            v_all_complete := TRUE;
            FOR v_obj IN SELECT * FROM jsonb_array_elements(v_quest.objectives) LOOP
                v_current := COALESCE((v_progress->>(v_obj->>'kind'))::INT, 0);
                v_target := (v_obj->>'target')::INT;
                 IF v_current < v_target THEN
                    v_all_complete := FALSE;
                END IF;
            END LOOP;

            IF v_all_complete THEN
                 UPDATE public.player_quests 
                 SET progress = v_progress, status = 'COMPLETED', updated_at = NOW() 
                 WHERE id = v_quest_uuid; -- Use explicit variable
                 
                 INSERT INTO public.notifications (user_id, message, type)
                 VALUES (p_user_id, 'ARCHIVE DIRECTIVE COMPLETE: ' || (SELECT title FROM public.quest_definitions WHERE id = v_quest.quest_id), 'success');
            ELSE
                 UPDATE public.player_quests 
                 SET progress = v_progress, updated_at = NOW() 
                 WHERE id = v_quest_uuid; -- Use explicit variable
            END IF;
        END IF;

    END LOOP;
END;
$$;

-- 3. Fix rpc_extract_v7 (Handle malformed array / empty string inputs / correct JSONB tray)
CREATE OR REPLACE FUNCTION public.rpc_extract_v7(payload JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := public.get_auth_user((payload->>'p_user_id')::UUID);
    v_profile RECORD;
    v_seismic_grade_raw TEXT := payload->>'p_seismic_grade';
    
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
    v_final_crate_tray JSONB; -- Changed to JSONB
    v_new_crate_id UUID;
    v_new_crate_json JSONB;
    
BEGIN
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated');
    END IF;

    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    
    -- Cooldown Check
    IF v_profile.last_extract_at IS NOT NULL AND v_profile.last_extract_at > NOW() - INTERVAL '2 seconds' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Cooldown active');
    END IF;

    -- 1. Parse Seismic Grades (Safe Parsing)
    IF v_seismic_grade_raw IS NOT NULL AND length(v_seismic_grade_raw) > 0 THEN
        BEGIN
            v_grades := string_to_array(v_seismic_grade_raw, ',');
        EXCEPTION WHEN OTHERS THEN
            v_grades := ARRAY[]::TEXT[];
        END;

        FOREACH v_g IN ARRAY v_grades LOOP
            IF v_g = 'PERFECT' THEN
                v_drop_bonus := v_drop_bonus + 0.05;
                v_xp_bonus := v_xp_bonus + 15;
            ELSIF v_g = 'HIT' THEN
                v_drop_bonus := v_drop_bonus + 0.02;
                v_xp_bonus := v_xp_bonus + 5;
            END IF;
        END LOOP;
        
        IF array_length(v_grades, 1) > 1 AND public.get_level(v_profile.excavation_xp) >= 99 THEN
            IF random() < 0.15 THEN
                 v_double_loot := TRUE;
            END IF;
        END IF;
    END IF;

    -- 2. Apply Zone Heat Bonus
    IF public.get_zone_static(v_profile.active_zone_id) > 0.66 THEN
        v_drop_bonus := v_drop_bonus + 0.10;
    END IF;

    -- 3. Roll for Crate
    v_crate_chance := v_crate_chance + v_drop_bonus;
    
    IF COALESCE(v_profile.tray_count, 0) < 3 THEN 
        IF random() < v_crate_chance THEN
            v_crate_dropped := TRUE;
            
            INSERT INTO public.vault_items (
                user_id, item_id, tier, 
                source_zone_id, source_static_tier
            ) VALUES (
                v_user_id, 'mysterious_crate', 1, v_profile.active_zone_id, 'LOW'
            ) RETURNING id INTO v_new_crate_id;
            
            v_new_crate_json := jsonb_build_object(
                'id', v_new_crate_id,
                'item_id', 'mysterious_crate',
                'tier', 1,
                'source_zone_id', v_profile.active_zone_id
            );

            -- JSONB Append
            UPDATE public.profiles SET 
                tray_count = COALESCE(tray_count, 0) + 1,
                crate_tray = COALESCE(crate_tray, '[]'::JSONB) || v_new_crate_json
            WHERE id = v_user_id;
            
            -- Double Loot (Mastery)
            IF v_double_loot AND COALESCE(v_profile.tray_count, 0) < 2 THEN
                 INSERT INTO public.vault_items (
                    user_id, item_id, tier, source_zone_id, source_static_tier
                ) VALUES (
                    v_user_id, 'mysterious_crate', 1, v_profile.active_zone_id, 'LOW'
                ) RETURNING id INTO v_new_crate_id;
                
                v_new_crate_json := jsonb_build_object(
                    'id', v_new_crate_id,
                    'item_id', 'mysterious_crate',
                    'tier', 1,
                    'source_zone_id', v_profile.active_zone_id
                );
                
                UPDATE public.profiles SET 
                    tray_count = tray_count + 1,
                    crate_tray = crate_tray || v_new_crate_json 
                WHERE id = v_user_id;
            END IF;

            PERFORM public.internal_increment_quest_objective(v_user_id, 'crate_obtained', 1);
        END IF;
    END IF;

    -- 4. Give Rewards
    v_scrap_gain := v_base_scrap; 
    
    v_new_xp := COALESCE(v_profile.excavation_xp, 0) + v_base_xp + v_xp_bonus;
    v_new_balance := COALESCE(v_profile.scrap_balance, 0) + v_scrap_gain;
    
    UPDATE public.profiles SET 
        scrap_balance = v_new_balance,
        excavation_xp = v_new_xp,
        last_extract_at = NOW()
    WHERE id = v_user_id
    RETURNING crate_tray INTO v_final_crate_tray;

    PERFORM public.internal_increment_quest_objective(v_user_id, 'extract_manual', 1);

    RETURN jsonb_build_object(
        'success', true,
        'result', CASE WHEN v_crate_dropped THEN 'CRATE_FOUND' ELSE 'SCRAP_FOUND' END,
        'scrap_gain', v_scrap_gain,
        'new_balance', v_new_balance,
        'new_xp', v_new_xp,
        'crate_dropped', v_crate_dropped,
        'crate_tray', COALESCE(v_final_crate_tray, '[]'::JSONB)
    );
END;
$$;


-- 4. Fix rpc_sift_v3 (Fix uuid=jsonb error)
CREATE OR REPLACE FUNCTION public.rpc_sift_v3(
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
    v_crate RECORD;
    v_crate_id UUID;
    
    v_base_stability FLOAT;
    v_bonus_stability FLOAT;
    v_stability_penalty FLOAT := 0;
    v_final_stability FLOAT;
    v_roll FLOAT;
    v_success BOOLEAN;
    
    v_survey_active BOOLEAN := FALSE;
    
    v_xp_gain INT := 0;
    
    v_stage INT;
    v_dust_payout INT := 0;
    v_salvage_token UUID := NULL;
    v_pending_fragment BOOLEAN := FALSE;
    v_pending_dust INT := 0;
    v_fragment_chance FLOAT := 0.25;
    v_is_critical BOOLEAN;
    v_fail_roll FLOAT;
    v_crit_chance FLOAT;
    
BEGIN
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated');
    END IF;

    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    SELECT * INTO v_lab FROM public.lab_state WHERE user_id = v_user_id;
    
    IF v_lab IS NULL OR NOT v_lab.is_active THEN
        RETURN jsonb_build_object('success', false, 'error', 'No active crate');
    END IF;
    
    -- Extract UUID from JSONB
    v_crate_id := (v_lab.active_crate->>'id')::UUID;
    SELECT * INTO v_crate FROM public.vault_items WHERE id = v_crate_id;

    v_stage := v_lab.current_stage;
    
    IF v_stage = 0 THEN
        PERFORM public.internal_increment_quest_objective(v_user_id, 'crate_opened', 1);
    END IF;

    PERFORM public.internal_increment_quest_objective(v_user_id, 'sift_attempted', 1);
    PERFORM public.internal_increment_quest_objective(v_user_id, 'sift_stage_at_least', 1, jsonb_build_object('stage', v_stage));

    IF v_crate.source_static_tier = 'HIGH' THEN v_stability_penalty := 0.05;
    ELSIF v_crate.source_static_tier = 'MED' THEN v_stability_penalty := 0.025;
    END IF;

    IF v_profile.last_survey_at IS NOT NULL AND v_profile.last_survey_at > NOW() - INTERVAL '10 minutes' THEN
        v_survey_active := TRUE;
        v_stability_penalty := v_stability_penalty * 0.5;
    END IF;

    CASE v_stage
        WHEN 0 THEN v_base_stability := 0.90;
        WHEN 1 THEN v_base_stability := 0.75;
        WHEN 2 THEN v_base_stability := 0.50;
        WHEN 3 THEN v_base_stability := 0.25;
        WHEN 4 THEN v_base_stability := 0.10;
        ELSE v_base_stability := 0;
    END CASE;

    v_bonus_stability := p_tethers_used * 0.15;
    
    v_final_stability := v_base_stability + v_bonus_stability - v_stability_penalty;
    v_final_stability := v_final_stability + (public.get_level(v_profile.restoration_xp) * 0.001);
    
    v_final_stability := GREATEST(0.01, LEAST(0.99, v_final_stability));

    v_roll := random();
    v_success := v_roll < v_final_stability;

    IF v_success THEN
        UPDATE public.lab_state SET current_stage = current_stage + 1 WHERE user_id = v_user_id;
        
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
        -- FAILURE LOGIC (With Shatter Salvage)
        IF v_profile.smelting_branch = 'fragment_alchemist' THEN
            v_fragment_chance := v_fragment_chance + 0.10;
        END IF;

        -- Critical Check
        v_crit_chance := 0.20; -- Base 20%
        IF p_zone = 1 THEN v_crit_chance := 0.50; END IF; -- Danger = 50%
        -- Tethers reduce crit chance
        IF p_tethers_used > 0 THEN v_crit_chance := v_crit_chance * 0.5; END IF;

        v_fail_roll := random();
        v_is_critical := v_fail_roll < v_crit_chance;

        IF v_is_critical THEN
             -- CRITICAL FAIL (SHATTTERED) - NO SALVAGE
             UPDATE public.lab_state SET 
                is_active = FALSE, 
                current_stage = 0, 
                active_crate = NULL, -- Clear crate
                salvage_token = NULL 
             WHERE user_id = v_user_id;

             -- Remove from tray (assuming active_crate was in tray? rpc_start_sifting handles this? 
             -- Actually start_sifting usually removes it from tray and puts in lab? No, it often keeps in tray in some versions.
             -- But standard logic is: remove from tray when claimed or destroyed.
             
             UPDATE public.profiles SET tray_count = GREATEST(0, tray_count - 1) WHERE id = v_user_id;
             -- Note: we don't need to remove from crate_tray jsonb if start_sifting already did?
             -- rpc_start_sifting in ...21 removes from tray. So we are good.

             RETURN jsonb_build_object('success', true, 'outcome', 'SHATTERED', 'critical', true);
        ELSE
            -- STANDARD FAIL - GRANT SALVAGE TOKEN
            v_salvage_token := gen_random_uuid();
            
            IF v_stage >= 1 AND v_stage <= 2 THEN
                v_pending_dust := 5 + (v_stage * 5);
            END IF;
            
            IF v_stage >= 3 AND random() < v_fragment_chance THEN
                v_pending_fragment := TRUE;
            END IF;

            UPDATE public.lab_state SET 
                is_active = FALSE, 
                current_stage = 0, 
                active_crate = NULL,
                salvage_token = v_salvage_token,
                salvage_expires_at = NOW() + INTERVAL '1.5 seconds',
                pending_salvage_dust = v_pending_dust,
                pending_salvage_fragment = v_pending_fragment
            WHERE user_id = v_user_id;
            
            UPDATE public.profiles SET tray_count = GREATEST(0, tray_count - 1) WHERE id = v_user_id;

            RETURN jsonb_build_object(
                'success', true, 
                'outcome', 'STABILIZED_FAIL', 
                'critical', false,
                'salvage_token', v_salvage_token,
                'salvage_expires_at', NOW() + INTERVAL '1.5 seconds',
                'pending_dust', v_pending_dust,
                'pending_fragment', v_pending_fragment
            );
        END IF;

    END IF;
END;
$$;

-- 5. Ensure rpc_get_quests matches
CREATE OR REPLACE FUNCTION public.rpc_get_quests(p_user_id UUID DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := public.get_auth_user(p_user_id);
    v_quests JSONB;
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;

    IF NOT EXISTS (SELECT 1 FROM public.player_quests WHERE user_id = v_user_id) THEN
        INSERT INTO public.player_quests (user_id, quest_id, status) VALUES (v_user_id, 'archive_onboard_01', 'AVAILABLE')
        ON CONFLICT DO NOTHING;
    END IF;

    SELECT jsonb_agg(
        jsonb_build_object(
            'id', pq.id,
            'quest_id', pq.quest_id,
            'status', pq.status,
            'progress', pq.progress,
            'title', qd.title,
            'context', qd.context,
            'objectives', qd.objectives,
            'rewards', qd.rewards
        )
    ) INTO v_quests
    FROM public.player_quests pq
    JOIN public.quest_definitions qd ON pq.quest_id = qd.id
    WHERE pq.user_id = v_user_id AND pq.status <> 'CLAIMED'
    ORDER BY qd.id ASC;

    RETURN jsonb_build_object('success', true, 'quests', COALESCE(v_quests, '[]'::JSONB));
END;
$$;
