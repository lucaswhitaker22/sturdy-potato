-- 20240116000020_skill_specializations.sql

-- 1. Schema Updates
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS excavation_branch TEXT DEFAULT NULL,
ADD COLUMN IF NOT EXISTS restoration_branch TEXT DEFAULT NULL,
ADD COLUMN IF NOT EXISTS appraisal_branch TEXT DEFAULT NULL,
ADD COLUMN IF NOT EXISTS smelting_branch TEXT DEFAULT NULL;

ALTER TABLE public.vault_items
ADD COLUMN IF NOT EXISTS certified BOOLEAN DEFAULT FALSE;

ALTER TABLE public.item_definitions
ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';

-- 2. Backfill Tags (Simplistic categorization based on names)
UPDATE public.item_definitions SET tags = array_append(tags, 'household') WHERE (name ILIKE '%mug%' OR name ILIKE '%toaster%' OR name ILIKE '%spoon%' OR name ILIKE '%fork%' OR name ILIKE '%knife%' OR name ILIKE '%glass%' OR name ILIKE '%comb%') AND NOT ('household' = ANY(tags));
UPDATE public.item_definitions SET tags = array_append(tags, 'tech') WHERE (name ILIKE '%battery%' OR name ILIKE '%bulb%' OR name ILIKE '%mouse%' OR name ILIKE '%keyboard%' OR name ILIKE '%monitor%' OR name ILIKE '%phone%' OR name ILIKE '%tablet%' OR name ILIKE '%remote%' OR name ILIKE '%console%') AND NOT ('tech' = ANY(tags));
UPDATE public.item_definitions SET tags = array_append(tags, 'branded') WHERE (name ILIKE '%soda%' OR name ILIKE '%casio%' OR name ILIKE '%nike%') AND NOT ('branded' = ANY(tags)); -- Assuming implicit branding
UPDATE public.item_definitions SET tags = array_append(tags, 'cultural') WHERE (name ILIKE '%game%' OR name ILIKE '%disc%' OR name ILIKE '%book%' OR name ILIKE '%watch%') AND NOT ('cultural' = ANY(tags));

-- 3. Branch Management RPCs
CREATE OR REPLACE FUNCTION public.rpc_choose_specialization(
    p_skill TEXT,
    p_branch TEXT,
    p_user_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := public.get_auth_user(p_user_id);
    v_profile RECORD;
    v_level INT;
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;

    -- validate inputs
    IF p_skill NOT IN ('excavation', 'restoration', 'appraisal', 'smelting') THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invalid skill');
    END IF;

    -- Check Level 60
    CASE p_skill
        WHEN 'excavation' THEN v_level := public.get_level(v_profile.excavation_xp);
        WHEN 'restoration' THEN v_level := public.get_level(v_profile.restoration_xp);
        WHEN 'appraisal' THEN v_level := public.get_level(v_profile.appraisal_xp);
        WHEN 'smelting' THEN v_level := public.get_level(v_profile.smelting_xp);
    END CASE;

    IF v_level < 60 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Level 60 required');
    END IF;

    -- Check if already chosen
    IF (p_skill = 'excavation' AND v_profile.excavation_branch IS NOT NULL) OR
       (p_skill = 'restoration' AND v_profile.restoration_branch IS NOT NULL) OR
       (p_skill = 'appraisal' AND v_profile.appraisal_branch IS NOT NULL) OR
       (p_skill = 'smelting' AND v_profile.smelting_branch IS NOT NULL) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Specialization already chosen');
    END IF;

    -- Update
    EXECUTE format('UPDATE public.profiles SET %I = $1 WHERE id = $2', p_skill || '_branch') USING p_branch, v_user_id;

    RETURN jsonb_build_object('success', true, 'skill', p_skill, 'branch', p_branch);
END;
$$;

CREATE OR REPLACE FUNCTION public.rpc_respec_specialization(
    p_skill TEXT,
    p_user_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := public.get_auth_user(p_user_id);
    v_cost INT := 25000;
    v_profile RECORD;
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;

    IF v_profile.scrap_balance < v_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient Scrap (25,000 required)');
    END IF;

    -- Deduct and Reset
    EXECUTE format('UPDATE public.profiles SET scrap_balance = scrap_balance - $1, %I = NULL WHERE id = $2', p_skill || '_branch') USING v_cost, v_user_id;

    RETURN jsonb_build_object('success', true, 'skill', p_skill, 'new_balance', v_profile.scrap_balance - v_cost);
END;
$$;

-- 4. Helper: Loot Generation (Excavation Branch Logic)
CREATE OR REPLACE FUNCTION public.rpc_helper_generate_crate_contents(
    p_zone_id TEXT,
    p_user_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    v_contents JSONB;
    v_profile RECORD;
    v_branch TEXT;
    v_items RECORD;
    v_selected_id UUID;
    v_tier_item_ids JSONB := '{}'::JSONB;
    v_tier TEXT;
    v_tiers TEXT[] := ARRAY['common', 'uncommon', 'rare', 'epic', 'mythic'];
    v_pool UUID[];
    v_biased_pool UUID[];
    v_item RECORD;
BEGIN
    SELECT * INTO v_profile FROM public.profiles WHERE id = p_user_id;
    v_branch := v_profile.excavation_branch; -- area_specialist (urban) or deep_seeker (tech)

    -- Loop through tiers to pre-roll an item for each tier (lazy generation)
    FOREACH v_tier IN ARRAY v_tiers LOOP
        -- Select pool
        SELECT array_agg(id) INTO v_pool FROM public.item_definitions WHERE tier = v_tier::item_tier;
        v_biased_pool := v_pool;

        -- Apply Bias if Branch active
        IF v_branch IS NOT NULL AND v_pool IS NOT NULL THEN
            IF v_branch = 'area_specialist' THEN
                -- Add 'household' and 'branded' items to pool AGAIN to increase weight (2x chance)
                SELECT array_agg(id) INTO v_biased_pool 
                FROM public.item_definitions 
                WHERE tier = v_tier::item_tier AND ('household' = ANY(tags) OR 'branded' = ANY(tags));
                
                IF v_biased_pool IS NOT NULL THEN
                    v_pool := v_pool || v_biased_pool; 
                END IF;
            ELSIF v_branch = 'deep_seeker' THEN
                 -- Add 'tech' and 'cultural' items again
                SELECT array_agg(id) INTO v_biased_pool 
                FROM public.item_definitions 
                WHERE tier = v_tier::item_tier AND ('tech' = ANY(tags) OR 'cultural' = ANY(tags));
                
                IF v_biased_pool IS NOT NULL THEN
                    v_pool := v_pool || v_biased_pool;
                END IF;
            END IF;
        END IF;

        IF array_length(v_pool, 1) > 0 THEN
             v_selected_id := v_pool[floor(random() * array_length(v_pool, 1)) + 1];
             v_tier_item_ids := v_tier_item_ids || jsonb_build_object(v_tier, v_selected_id);
        END IF;
    END LOOP;

    -- Generate Mint Numbers (Fake pre-calc)
    -- Generate Condition
    v_contents := jsonb_build_object(
        'items_by_tier', v_tier_item_ids,
        'condition', (ARRAY['wrecked','weathered','preserved','mint'])[floor(random()*4)+1],
        'is_prismatic', (random() < 0.01),
        'mint_numbers', jsonb_build_object('common', floor(random()*1000), 'rare', floor(random()*100))
    );

    RETURN v_contents;
END;
$$;

-- 5. Update rpc_extract_v6 to use Helper
CREATE OR REPLACE FUNCTION public.rpc_extract_v6(payload JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    p_user_id UUID := (payload->>'p_user_id')::UUID;
    p_seismic_grade TEXT := payload->>'p_seismic_grade';
    v_user_id UUID := public.get_auth_user(p_user_id);
    v_profile RECORD;
    v_roll FLOAT;
    v_result TEXT;
    v_scrap_gain INT := 0;
    v_xp_gain INT := 0;
    v_crate_dropped BOOLEAN := FALSE;
    v_base_crate_rate FLOAT := 0.15;
    v_bonus_rate FLOAT := 0.0;
    v_excavation_level INT;
    v_anomaly_rate FLOAT := 0.05;
    v_anomaly_happened BOOLEAN := FALSE;
    
    -- Expansion logic
    v_static FLOAT;
    v_zone_crate_bonus FLOAT := 0;
    v_focused_survey_bonus FLOAT := 0;
    v_double_loot BOOLEAN := FALSE;
    
    -- Seismic grades
    v_grades TEXT[];
    v_grade TEXT;
    v_perfect_count INT := 0;
    v_hit_count INT := 0;

    -- Final values
    v_final_balance BIGINT;
    v_final_xp BIGINT;
    v_final_tray_count INT;
    v_final_crate_tray JSONB;
    
    -- New Crate logic
    v_new_crate JSONB;
    v_contents JSONB;
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    
    v_excavation_level := public.get_level(COALESCE(v_profile.excavation_xp, 0));
    v_static := public.get_zone_static(COALESCE(v_profile.active_zone_id, 'industrial_zone'));
    v_zone_crate_bonus := v_static * 0.02;
    
    IF v_profile.is_focused_survey_active THEN
        v_focused_survey_bonus := 0.20;
        v_scrap_gain := v_scrap_gain - 10;
    END IF;

    v_bonus_rate := floor(v_excavation_level / 5) * 0.005;

    IF p_seismic_grade IS NOT NULL THEN
        v_grades := string_to_array(p_seismic_grade, ',');
        FOREACH v_grade IN ARRAY v_grades LOOP
            IF v_grade = 'PERFECT' THEN v_perfect_count := v_perfect_count + 1;
            ELSIF v_grade = 'HIT' THEN v_hit_count := v_hit_count + 1;
            END IF;
        END LOOP;
    END IF;

    IF v_excavation_level >= 99 AND random() < 0.15 THEN v_double_loot := TRUE; END IF;
    IF v_perfect_count >= 2 THEN v_double_loot := TRUE; v_xp_gain := v_xp_gain + 50; END IF;

    v_roll := random();
    IF v_roll < v_anomaly_rate THEN
        v_result := 'ANOMALY';
        v_anomaly_happened := TRUE;
        v_xp_gain := v_xp_gain + 25;
    ELSIF v_roll < (v_anomaly_rate + v_base_crate_rate + v_bonus_rate + v_zone_crate_bonus + v_focused_survey_bonus) AND v_profile.tray_count < 5 THEN
        v_crate_dropped := TRUE;
        v_result := 'CRATE_FOUND';
        v_xp_gain := v_xp_gain + 15;
    ELSE
        v_scrap_gain := v_scrap_gain + floor(random() * 11 + 5)::INT;
        v_result := 'SCRAP_FOUND';
        v_xp_gain := v_xp_gain + 5;
    END IF;

    IF v_double_loot THEN v_scrap_gain := v_scrap_gain * 2; END IF;

    IF v_crate_dropped THEN
        -- Generate contents using Helper (applies Branch Bias)
        v_contents := public.rpc_helper_generate_crate_contents(COALESCE(v_profile.active_zone_id, 'industrial_zone'), v_user_id);
        
        v_new_crate := jsonb_build_object(
            'id', gen_random_uuid(),
            'rarity', 'COMMON',
            'origin_zone', COALESCE(v_profile.active_zone_id, 'industrial_zone'),
            'static_heat', v_static,
            'found_at', NOW(),
            'contents', v_contents, -- Now populated!
            'appraised', false
        );
    END IF;

    UPDATE public.profiles
    SET 
        scrap_balance = scrap_balance + v_scrap_gain,
        excavation_xp = excavation_xp + v_xp_gain,
        tray_count = CASE 
            WHEN v_crate_dropped AND v_double_loot AND tray_count < 4 THEN tray_count + 2
            WHEN v_crate_dropped THEN tray_count + 1
            ELSE tray_count
        END,
        crate_tray = CASE 
            WHEN v_crate_dropped AND v_double_loot AND tray_count < 4 THEN COALESCE(crate_tray, '[]'::JSONB) || v_new_crate || v_new_crate
            WHEN v_crate_dropped THEN COALESCE(crate_tray, '[]'::JSONB) || v_new_crate
            ELSE crate_tray
        END,
        last_extract_at = NOW()
    WHERE id = v_user_id
    RETURNING scrap_balance, excavation_xp, tray_count, crate_tray 
    INTO v_final_balance, v_final_xp, v_final_tray_count, v_final_crate_tray;

    RETURN jsonb_build_object(
        'success', true,
        'result', v_result,
        'scrap_gain', v_scrap_gain,
        'xp_gain', v_xp_gain,
        'crate_dropped', v_crate_dropped,
        'new_balance', v_final_balance,
        'new_xp', v_final_xp,
        'new_tray_count', v_final_tray_count,
        'crate_tray', v_final_crate_tray
    );
END;
$$;


-- 6. Update rpc_sift_v2 (Restoration & Smelting Logic)
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
             UPDATE public.lab_state SET is_active = FALSE, current_stage = 0, last_action_at = NOW(), salvage_token = v_salvage_token, salvage_expires_at = NOW() + INTERVAL '1.0 seconds', pending_salvage_dust = 0, pending_salvage_fragment = FALSE WHERE user_id = v_user_id;
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
             UPDATE public.lab_state SET is_active = FALSE, current_stage = 0, last_action_at = NOW(), salvage_token = v_salvage_token, salvage_expires_at = NOW() + INTERVAL '1.15 seconds', pending_salvage_dust = v_pending_dust, pending_salvage_fragment = v_pending_fragment WHERE user_id = v_user_id;
             UPDATE public.profiles SET tray_count = GREATEST(0, tray_count - 1), fine_dust_balance = fine_dust_balance + v_dust_payout WHERE id = v_user_id;

             RETURN jsonb_build_object('success', true, 'outcome', 'STABILIZED_FAIL', 'critical', false, 'dust_payout', v_dust_payout, 'salvage_token', v_salvage_token, 'new_dust_balance', (v_profile.fine_dust_balance + v_dust_payout));
        END IF;
    END IF;
END;
$$;

-- 7. New RPC: Certify Item (Appraisal Branch)
CREATE OR REPLACE FUNCTION public.rpc_certify_item(p_item_id UUID, p_user_id UUID DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := public.get_auth_user(p_user_id);
    v_profile RECORD;
    v_item RECORD;
    v_cost INT := 500; -- Base cert cost?
    v_final_cost INT;
    v_hv_bonus INT;
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    SELECT * INTO v_item FROM public.vault_items WHERE id = p_item_id AND user_id = v_user_id;

    IF v_item IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Item not found'); END IF;
    IF v_item.certified THEN RETURN jsonb_build_object('success', false, 'error', 'Item already certified'); END IF;

    -- Authenticator Discount (-25%)
    IF v_profile.appraisal_branch = 'authenticator' THEN
        v_final_cost := floor(v_cost * 0.75)::INT;
    ELSE
        v_final_cost := v_cost;
    END IF;

    IF v_profile.scrap_balance < v_final_cost THEN RETURN jsonb_build_object('success', false, 'error', 'Insufficient Scrap'); END IF;

    -- Apply HV Bonus (+2% for Authenticator)
    v_hv_bonus := 0;
    IF v_profile.appraisal_branch = 'authenticator' THEN
        v_hv_bonus := floor(v_item.historical_value * 0.02)::INT;
    END IF;

    UPDATE public.profiles SET scrap_balance = scrap_balance - v_final_cost WHERE id = v_user_id;
    UPDATE public.vault_items SET certified = TRUE, historical_value = historical_value + v_hv_bonus WHERE id = p_item_id;

    RETURN jsonb_build_object('success', true, 'new_balance', v_profile.scrap_balance - v_final_cost, 'hv_gain', v_hv_bonus);
END;
$$;

-- 8. New RPC: Smelt Item (Smelting Branch)
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

    RETURN jsonb_build_object('success', true, 'scrap_gain', v_final_scrap, 'new_balance', v_profile.scrap_balance + v_final_scrap);
END;
$$;


-- Grant Permissions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;
NOTIFY pgrst, 'reload schema';
