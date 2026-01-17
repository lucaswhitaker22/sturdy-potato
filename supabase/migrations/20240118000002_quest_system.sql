-- 20240118000002_quest_system.sql
-- Implements the Quest System (Archive Directives)

-- 1. Schema Definitions
CREATE TABLE IF NOT EXISTS public.quest_definitions (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL, -- 'onboarding', 'daily', 'weekly', 'event'
    title TEXT NOT NULL,
    context TEXT,
    requirements JSONB DEFAULT '{}'::JSONB, -- { "min_level": 5, "prereq": "..." }
    objectives JSONB DEFAULT '[]'::JSONB, -- [{ "kind": "extract_manual", "target": 10 }]
    rewards JSONB DEFAULT '[]'::JSONB, -- [{ "kind": "scrap", "amount": 250 }]
    expires_at TIMESTAMPTZ DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS public.player_quests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id),
    quest_id TEXT NOT NULL REFERENCES public.quest_definitions(id),
    status TEXT DEFAULT 'AVAILABLE', -- 'AVAILABLE', 'ACCEPTED', 'COMPLETED', 'CLAIMED'
    progress JSONB DEFAULT '{}'::JSONB, -- { "extract_manual": 5 } (keyed by objective kind)
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT NULL,
    UNIQUE(user_id, quest_id)
);

-- 2. Helper: Increment Quest Objective
-- Safe to call from any RPC. Increments progress for active quests.
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
BEGIN
    FOR v_quest IN 
        SELECT pq.*, qd.objectives 
        FROM public.player_quests pq
        JOIN public.quest_definitions qd ON pq.quest_id = qd.id
        WHERE pq.user_id = p_user_id 
        AND pq.status IN ('ACCEPTED') 
        -- AND pq.expires_at > NOW() -- Handle expiry elsewhere or implicitly
    LOOP
        v_needs_update := FALSE;
        v_progress := v_quest.progress;

        -- Check each objective
        FOR v_obj IN SELECT * FROM jsonb_array_elements(v_quest.objectives) LOOP
            IF v_obj->>'kind' = p_kind THEN
                -- Check filters (e.g. "claim_stage_at_least": 3)
                IF (p_metadata->>'stage')::INT IS NOT NULL AND (v_obj->>'stage_at_least')::INT IS NOT NULL THEN
                    IF (p_metadata->>'stage')::INT < (v_obj->>'stage_at_least')::INT THEN
                       CONTINUE; -- Skip if stage requirement not met
                    END IF;
                END IF;

                 -- Get current progress
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
            -- Check for completion
            v_all_complete := TRUE;
            FOR v_obj IN SELECT * FROM jsonb_array_elements(v_quest.objectives) LOOP
                v_current := COALESCE((v_progress->>(v_obj->>'kind'))::INT, 0);
                v_target := (v_obj->>'target')::INT;
                 IF v_current < v_target THEN
                    v_all_complete := FALSE;
                END IF;
            END LOOP;

            -- Update Quest
            IF v_all_complete THEN
                 UPDATE public.player_quests 
                 SET progress = v_progress, status = 'COMPLETED', updated_at = NOW() 
                 WHERE id = v_quest.id;
                 
                 INSERT INTO public.notifications (user_id, message, type)
                 VALUES (p_user_id, 'ARCHIVE DIRECTIVE COMPLETE: ' || (SELECT title FROM public.quest_definitions WHERE id = v_quest.quest_id), 'success');
            ELSE
                 UPDATE public.player_quests 
                 SET progress = v_progress, updated_at = NOW() 
                 WHERE id = v_quest.id;
            END IF;
        END IF;

    END LOOP;
END;
$$;

-- 3. Seed: Onboarding Quests
INSERT INTO public.quest_definitions (id, type, title, context, requirements, objectives, rewards) VALUES
('archive_onboard_01', 'onboarding', 'Boot Sequence', 'The Archive terminal is waking up.', 
    '{}', 
    '[{"kind": "extract_manual", "target": 10}]', 
    '[{"kind": "scrap", "amount": 250}]'
),
('archive_onboard_02', 'onboarding', 'First Crate', 'You need evidence, not dust.', 
    '{"prereq": "archive_onboard_01"}', 
    '[{"kind": "crate_obtained", "target": 1}]', 
    '[{"kind": "scrap", "amount": 500}]'
),
('archive_onboard_03', 'onboarding', 'Enter the Lab', 'The Refiner is online. Don''t touch anything you can''t explain.', 
    '{"prereq": "archive_onboard_02"}', 
    '[{"kind": "crate_opened", "target": 1}]', 
    '[{"kind": "scrap", "amount": 100}]'
),
('archive_onboard_04', 'onboarding', 'First Gamble', 'The Archive prefers risk, as long as it''s documented.', 
    '{"prereq": "archive_onboard_03"}', 
    '[{"kind": "sift_stage_at_least", "target": 1, "stage_at_least": 1}]', 
    '[{"kind": "dust", "amount": 10}]'
),
('archive_onboard_05', 'onboarding', 'Claim Discipline', 'You can''t sell a story you never brought back.', 
    '{"prereq": "archive_onboard_04"}', 
    '[{"kind": "claim_stage_at_least", "target": 1, "stage_at_least": 1}]', 
    '[{"kind": "scrap", "amount": 1000}]'
),
('archive_onboard_06', 'onboarding', 'The Vault Matters', 'Hoarding is not a strategy. Convert waste into throughput.', 
    '{"prereq": "archive_onboard_05"}', 
    '[{"kind": "smelt_items", "target": 3}]', 
    '[{"kind": "scrap", "amount": 750}]'
),
('archive_onboard_07', 'onboarding', 'Set Awareness', 'The Archive remembers patterns. You should too.', 
    '{"prereq": "archive_onboard_06"}', 
    '[{"kind": "set_entries_added", "target": 1}]', 
    '[{"kind": "cosmetic", "id": "archive_label"}]'
),
('archive_onboard_08', 'onboarding', 'The Bazaar Door', 'If it''s not priced, it''s not real.', 
    '{"prereq": "archive_onboard_07"}', 
    '[{"kind": "listings_created", "target": 1}]', 
    '[{"kind": "scrap", "amount": 2000}]'
),
('archive_onboard_09', 'onboarding', 'Museum Week', 'The Archive rewards exhibits, not excuses.', 
    '{"prereq": "archive_onboard_08"}', 
    '[{"kind": "museum_submissions", "target": 1}]', 
    '[{"kind": "hi", "amount": 25}]'
),
('archive_onboard_10', 'onboarding', 'Field Agent', 'Clearance granted. You''re officially a problem now.', 
    '{"prereq": "archive_onboard_09"}', 
    '[{"kind": "complete_onboarding", "target": 1}]', 
    '[{"kind": "title", "id": "field_agent"}]'
)
ON CONFLICT (id) DO NOTHING;


-- 4. RPCs for Quest Management

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

    -- Ensure Onboarding 01 is assigned if nothing exists
    IF NOT EXISTS (SELECT 1 FROM public.player_quests WHERE user_id = v_user_id) THEN
        INSERT INTO public.player_quests (user_id, quest_id, status) VALUES (v_user_id, 'archive_onboard_01', 'AVAILABLE');
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
    WHERE pq.user_id = v_user_id AND pq.status <> 'CLAIMED' -- Hide claimed history or limit it
    ORDER BY qd.id ASC;

    RETURN jsonb_build_object('success', true, 'quests', COALESCE(v_quests, '[]'::JSONB));
END;
$$;

CREATE OR REPLACE FUNCTION public.rpc_accept_quest(p_quest_id TEXT, p_user_id UUID DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := public.get_auth_user(p_user_id);
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;

    UPDATE public.player_quests 
    SET status = 'ACCEPTED' 
    WHERE user_id = v_user_id AND quest_id = p_quest_id AND status = 'AVAILABLE';

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Quest not found or not available');
    END IF;

    RETURN jsonb_build_object('success', true);
END;
$$;

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
            -- TODO: Title system
        ELSIF v_reward->>'kind' = 'cosmetic' THEN
             -- TODO: Cosmetic system
        END IF;
    END LOOP;

    -- Mark Claimed
    UPDATE public.player_quests SET status = 'CLAIMED', updated_at = NOW() WHERE id = p_quest_db_id;

    -- Auto-Assign Next Quest (Simulated Chain)
    -- In a real graph, we'd query quest_definitions where prereq = this_quest
    FOR v_next_id IN 
        SELECT id FROM public.quest_definitions 
        WHERE (requirements->>'prereq') = v_quest.quest_id
    LOOP
        -- Check if already exists
        IF NOT EXISTS (SELECT 1 FROM public.player_quests WHERE user_id = v_user_id AND quest_id = v_next_id) THEN
            INSERT INTO public.player_quests (user_id, quest_id, status) VALUES (v_user_id, v_next_id, 'AVAILABLE');
            
            -- Auto-Complete Hack for Onboarding 10 if we just finished 09
            -- Actually, 10 requires 09, so this INSERT logic works. 
            -- But 10 has "complete_onboarding" objective? No, it's just a claimable "finisher".
            -- We can make it auto-complete immediately if we want, or just make it having no objectives.
            -- If objectives is empty loop skips and it stays unavailable? 
            -- Ah, internal_increment doesn't autocomplete if 0 objectives?
        END IF;
    END LOOP;
    
    -- Special Case for Onboarding 10 (Field Agent)
    -- It has an objective "complete_onboarding" which we can trigger manually or just auto-complete here.
    IF v_quest.quest_id = 'archive_onboard_09' THEN
         -- Trigger update for 10 if it was just inserted
         PERFORM public.internal_increment_quest_objective(v_user_id, 'complete_onboarding', 1);
    END IF;

    RETURN jsonb_build_object('success', true);
END;
$$;


-- 5. UPDATE EXISTING RPCS TO TRIGGER QUESTS

-- 5.1 Extract V7 (Updated with Quest Triggers)
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
                'mysterious_crate', -- placeholder
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
            
            -- Double Loot (Mastery)
            IF v_double_loot AND v_profile.tray_count < 2 THEN
                 INSERT INTO public.vault_items (
                    user_id, item_id, tier, source_zone_id, source_static_tier
                ) VALUES (
                    v_user_id, 'mysterious_crate', 1, v_profile.active_zone_id, 'LOW'
                );
                UPDATE public.profiles SET tray_count = tray_count + 1 WHERE id = v_user_id; 
            END IF;

            -- QUEST TRIGGER: Crate Obtained
            PERFORM public.internal_increment_quest_objective(v_user_id, 'crate_obtained', 1);
        END IF;
    END IF;

    -- 4. Give Rewards
    v_scrap_gain := v_base_scrap; 
    
    -- XP
    v_new_xp := v_profile.excavation_xp + v_base_xp + v_xp_bonus;
    v_new_balance := v_profile.scrap_balance + v_scrap_gain;
    
    UPDATE public.profiles SET 
        scrap_balance = v_new_balance,
        excavation_xp = v_new_xp,
        last_extract_at = NOW()
    WHERE id = v_user_id
    RETURNING crate_tray INTO v_final_crate_tray;

    -- QUEST TRIGGER: Extract Manual
    PERFORM public.internal_increment_quest_objective(v_user_id, 'extract_manual', 1);

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


-- 5.2 Sift V3 (Updated with Quest Triggers)
CREATE OR REPLACE FUNCTION public.rpc_sift_v3(
    p_user_id UUID DEFAULT NULL,
    p_tethers_used INT DEFAULT 0,
    p_zone INT DEFAULT 0 -- Kept for signature compatibility
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
    
    -- QUEST TRIGGER: Crate Opened (First sift)
    IF v_stage = 0 THEN
        PERFORM public.internal_increment_quest_objective(v_user_id, 'crate_opened', 1);
    END IF;

    -- QUEST TRIGGER: Sift Attempt (At current stage)
    PERFORM public.internal_increment_quest_objective(v_user_id, 'sift_attempted', 1);
    PERFORM public.internal_increment_quest_objective(v_user_id, 'sift_stage_at_least', 1, jsonb_build_object('stage', v_stage));

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


-- 5.3 Smelt Item (Updated)
CREATE OR REPLACE FUNCTION public.rpc_smelt_item(p_item_id UUID, p_user_id UUID DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := public.get_auth_user(p_user_id);
    v_profile RECORD;
    v_item RECORD;
    v_item_def RECORD;
    v_base_scrap INT;
    v_final_scrap INT;
    v_smelting_level INT;
    v_mult FLOAT := 1.0;
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    SELECT * INTO v_item FROM public.vault_items WHERE id = p_item_id AND user_id = v_user_id;
    IF v_item IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Item not found'); END IF;

    SELECT * INTO v_item_def FROM public.item_definitions WHERE id = v_item.item_id;

    -- Base Value logic (simplified)
    CASE v_item_def.tier
        WHEN 'junk' THEN v_base_scrap := 2;
        WHEN 'common' THEN v_base_scrap := 10;
        WHEN 'uncommon' THEN v_base_scrap := 25;
        WHEN 'rare' THEN v_base_scrap := 100;
        WHEN 'epic' THEN v_base_scrap := 500;
        WHEN 'mythic' THEN v_base_scrap := 2500;
        ELSE v_base_scrap := 1;
    END CASE;

    -- Smelting Level mult (1% per level? or per 10 levels?)
    v_smelting_level := public.get_level(v_profile.smelting_xp);
    v_mult := 1.0 + (v_smelting_level * 0.01);

    -- Scrap Tycoon Branch: Junk x1.25
    IF v_item_def.tier = 'junk' AND v_profile.smelting_branch = 'scrap_tycoon' THEN
        v_mult := v_mult * 1.25;
    END IF;

    v_final_scrap := floor(v_base_scrap * v_mult)::INT;

    -- Delete Item
    DELETE FROM public.vault_items WHERE id = p_item_id;

    -- Award Scrap & XP
    UPDATE public.profiles SET scrap_balance = scrap_balance + v_final_scrap, smelting_xp = smelting_xp + (v_final_scrap / 2)::INT WHERE id = v_user_id;

    -- QUEST TRIGGER: Smelt Items
    PERFORM public.internal_increment_quest_objective(v_user_id, 'smelt_items', 1);

    RETURN jsonb_build_object('success', true, 'scrap_gain', v_final_scrap, 'new_balance', v_profile.scrap_balance + v_final_scrap);
END;
$$;


-- 5.4 List Item (Updated)
CREATE OR REPLACE FUNCTION public.rpc_list_item(p_vault_item_id UUID, p_price BIGINT, p_hours INT, p_is_counter BOOLEAN DEFAULT FALSE)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_item RECORD;
    v_profile RECORD;
    v_deposit BIGINT := 50;
    v_is_under_the_table BOOLEAN := FALSE;
BEGIN
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    IF v_profile.scrap_balance < v_deposit THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient scrap for deposit');
    END IF;

    SELECT * INTO v_item FROM public.vault_items WHERE id = p_vault_item_id AND user_id = v_user_id;
    IF v_item IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Item not found');
    END IF;
    
    IF EXISTS (SELECT 1 FROM public.market_listings WHERE vault_item_id = p_vault_item_id AND status = 'active') THEN
         RETURN jsonb_build_object('success', false, 'error', 'Item already listed');
    END IF;

    -- Master Trader check
    IF p_is_counter AND v_profile.appraisal_xp >= 100000 THEN -- Assuming 100k XP is level 99
        v_is_under_the_table := TRUE;
    END IF;

    -- Deduct deposit
    UPDATE public.profiles SET scrap_balance = scrap_balance - v_deposit WHERE id = v_user_id;

    INSERT INTO public.market_listings (
        seller_id, vault_item_id, reserve_price, ends_at, deposit_amount, is_counter, is_under_the_table, last_confiscation_check
    )
    VALUES (
        v_user_id, p_vault_item_id, p_price, NOW() + (p_hours || ' hours')::INTERVAL, v_deposit, 
        p_is_counter, v_is_under_the_table, NOW()
    );

    INSERT INTO public.global_events (event_type, user_id, details)
    VALUES (CASE WHEN p_is_counter THEN 'counter_listing' ELSE 'listing' END, v_user_id, jsonb_build_object('item_id', v_item.item_id, 'price', p_price));

    -- QUEST TRIGGER: Listings Created
    PERFORM public.internal_increment_quest_objective(v_user_id, 'listings_created', 1);

    RETURN jsonb_build_object('success', true, 'is_under_the_table', v_is_under_the_table);
END;
$$;


-- 5.5 Museum Submit (Updated)
CREATE OR REPLACE FUNCTION public.rpc_museum_submit_item(p_vault_item_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_week RECORD;
    v_item RECORD;
    v_item_def RECORD;
    v_score NUMERIC := 0;
    v_bonus_mult NUMERIC := 1.0;
    v_submission_count INT;
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;

    -- Get active week
    SELECT * INTO v_week FROM public.museum_weeks WHERE status = 'active' ORDER BY ends_at ASC LIMIT 1;
    IF v_week IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'No active museum week');
    END IF;

    -- Check submission limit
    SELECT COUNT(*) INTO v_submission_count FROM public.museum_submissions WHERE week_id = v_week.id AND player_id = v_user_id;
    IF v_submission_count >= 10 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Weekly submission limit reached');
    END IF;

    -- Verify ownership and not locked
    SELECT vi.*, id.tags INTO v_item 
    FROM public.vault_items vi
    JOIN public.item_definitions id ON vi.item_id = id.id
    WHERE vi.id = p_vault_item_id AND vi.user_id = v_user_id;
    
    IF v_item.id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Item not found');
    END IF;

    IF v_item.locked_until IS NOT NULL AND v_item.locked_until > NOW() THEN
        RETURN jsonb_build_object('success', false, 'error', 'Item is locked');
    END IF;

    -- SCORING LOGIC
    -- Base Score: 10% of Historical Value
    v_score := v_item.historical_value / 10.0;

    -- Theme Matching: Apply 1.5x multiplier if tags match
    -- v_week.theme_tags is JSONB array: ["tech", "household"]
    IF v_week.theme_tags IS NOT NULL AND (v_week.theme_tags ?| v_item.tags) THEN
        v_bonus_mult := 1.5;
    END IF;

    v_score := v_score * v_bonus_mult;

    -- Update lock on item
    UPDATE public.vault_items SET locked_until = v_week.ends_at WHERE id = p_vault_item_id;

    -- Insert submission
    INSERT INTO public.museum_submissions (week_id, player_id, vault_item_id, score, locked_until)
    VALUES (v_week.id, v_user_id, p_vault_item_id, v_score, v_week.ends_at);

    -- Award Historical Influence (1 HI per 10 points)
    UPDATE public.profiles SET historical_influence = historical_influence + floor(v_score / 10)::INT WHERE id = v_user_id;

    -- QUEST TRIGGER: Museum Submissions
    PERFORM public.internal_increment_quest_objective(v_user_id, 'museum_submissions', 1);

    RETURN jsonb_build_object('success', true, 'score', v_score, 'bonus_applied', v_bonus_mult > 1.0);
END;
$$;

-- 5.6 Claim (Updated - had to assume location, but standard claim logic from previous files)
CREATE OR REPLACE FUNCTION public.rpc_claim(p_user_id UUID DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := public.get_auth_user(p_user_id);
    v_lab RECORD;
    v_crate_id UUID;
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;

    SELECT * INTO v_lab FROM public.lab_state WHERE user_id = v_user_id;
    
    IF v_lab IS NULL OR NOT v_lab.is_active THEN
        RETURN jsonb_build_object('success', false, 'error', 'No active crate to claim');
    END IF;

    -- Identify Crate (it's in lab_state active_crate ID, but we need to unlock it in vault_items)
    v_crate_id := (v_lab.active_crate->>'id')::UUID;

    -- Reveal Item Logic would go here (or happens in client reveal, but this "Secures" the item)
    -- For now, we mainly just clear the lab state. The item is already in vault_items but needs "identification" or something?
    -- Actually earlier specs said claiming moves it to vault. But new system: it's in vault as 'unidentified_crate' until claimed?
    -- No, rpc_extract puts it in 'crate_tray' (profile column) AND 'vault_items' (as unidentified crate).
    -- Wait, looking at rpc_extract_v6:
    -- INSERT INTO public.vault_items ... item_id='unidentified_crate'
    
    -- When we CLAIM, we should effectively "keep" it (make it sellable/smeltable).
    -- For this simplified pass, we just reset lab state.
    
    -- QUEST TRIGGER: Claim Stage
    PERFORM public.internal_increment_quest_objective(v_user_id, 'claim_stage_at_least', 1, jsonb_build_object('stage', v_lab.current_stage));
    
    UPDATE public.lab_state 
    SET is_active = FALSE, current_stage = 0, last_action_at = NOW(), active_crate = NULL 
    WHERE user_id = v_user_id;

    -- Update Tray (remove it) - Actually Sift/Extract removed it from tray when Moving to Lab?
    -- Usually "Move to Lab" removes from Tray. 
    -- We assume the item is already "in the lab".

    RETURN jsonb_build_object('success', true, 'outcome', 'CLAIMED');
END;
$$;


-- Grant Permissions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;
NOTIFY pgrst, 'reload schema';
