-- 20240118000000_master_audit_fix.sql
-- Consolidated logic for Heatmaps, Masteries, Specializations, and Meta-Game.

-- 1. UTILITY: Real Museum Scoring & Week Management
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

    RETURN jsonb_build_object('success', true, 'score', v_score, 'bonus_applied', v_bonus_mult > 1.0);
END;
$$;

-- 2. TUNED: Counter-Bazaar Risk
CREATE OR REPLACE FUNCTION public.rpc_check_confiscations()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_listing RECORD;
    v_appraisal_lvl INT;
    v_risk FLOAT;
    v_roll FLOAT;
    v_confiscated_count INT := 0;
BEGIN
    -- This should be restricted to service role in production
    -- For now, open for testing in audit
    FOR v_listing IN 
        SELECT m.*, p.appraisal_xp 
        FROM public.market_listings m
        JOIN public.profiles p ON m.seller_id = p.id
        WHERE m.status = 'active' 
        AND m.is_counter = TRUE 
        AND m.last_confiscation_check < NOW() - INTERVAL '24 hours'
    LOOP
        v_appraisal_lvl := floor(sqrt(v_listing.appraisal_xp / 100)) + 1;
        
        -- Tuning: 2% base, -0.25% per 10 levels
        v_risk := 0.02 - (LEAST(v_appraisal_lvl, 80) / 10.0 * 0.0025);
        v_risk := GREATEST(0.0025, v_risk); -- Min 0.25% at Level 70+

        v_roll := random();
        IF v_roll < v_risk THEN
            -- CONFISCATED
            UPDATE public.market_listings SET status = 'confiscated' WHERE id = v_listing.id;
            DELETE FROM public.vault_items WHERE id = v_listing.vault_item_id;
            
            INSERT INTO public.notifications (user_id, message, type)
            VALUES (v_listing.seller_id, 'ARCHIVE ALERT: Counter-Bazaar listing Lot #' || v_listing.id || ' has been confiscated.', 'error');
            
            v_confiscated_count := v_confiscated_count + 1;
        ELSE
            UPDATE public.market_listings SET last_confiscation_check = NOW() WHERE id = v_listing.id;
        END IF;
    END LOOP;

    RETURN jsonb_build_object('success', true, 'confiscated', v_confiscated_count);
END;
$$;

-- 3. UNIFIED: Extract V6 (Heatmaps + Masteries + Specializations)
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
    v_heatmap RECORD;
    v_roll FLOAT;
    v_result TEXT;
    v_scrap_gain INT := 0;
    v_xp_gain INT := 0;
    v_crate_dropped BOOLEAN := FALSE;
    v_base_find_chance FLOAT := 0.15;
    v_bonus_find_chance FLOAT := 0.0;
    v_excavation_level INT;
    v_anomaly_rate FLOAT := 0.05;
    v_anomaly_happened BOOLEAN := FALSE;
    
    -- Bonuses
    v_static_bonus FLOAT := 0;
    v_focused_survey_bonus FLOAT := 0;
    v_double_loot BOOLEAN := FALSE;
    
    -- Seismic
    v_grades TEXT[];
    v_grade TEXT;
    v_perfect_count INT := 0;

    -- Output
    v_final_balance BIGINT;
    v_final_xp BIGINT;
    v_final_tray_count INT;
    v_final_crate_tray JSONB;
    
    -- New Crate
    v_crate_id UUID := gen_random_uuid();
    v_new_crate_data JSONB;
    v_contents JSONB;
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    
    -- 1. FETCH HEATMAP
    SELECT * INTO v_heatmap FROM public.vault_heatmaps WHERE zone_id = COALESCE(v_profile.active_zone_id, 'industrial_zone');
    
    -- 2. CALCULATE FIND CHANCE
    v_excavation_level := public.get_level(COALESCE(v_profile.excavation_xp, 0));
    
    -- Heatmap Bonus
    IF v_heatmap.static_tier = 'HIGH' THEN v_static_bonus := 0.02;
    ELSIF v_heatmap.static_tier = 'MED' THEN v_static_bonus := 0.01;
    END IF;
    
    -- Survey Bonus
    IF v_profile.is_focused_survey_active THEN
        v_focused_survey_bonus := 0.20;
        v_scrap_gain := v_scrap_gain - 10;
    END IF;

    -- Level Bonus (0.5% per 5 levels)
    v_bonus_find_chance := floor(v_excavation_level / 5) * 0.005;

    -- Seismic Bonus
    IF p_seismic_grade IS NOT NULL THEN
        v_grades := string_to_array(p_seismic_grade, ',');
        FOREACH v_grade IN ARRAY v_grades LOOP
            IF v_grade = 'PERFECT' THEN v_perfect_count := v_perfect_count + 1; END IF;
        END LOOP;
        IF v_perfect_count > 0 THEN v_bonus_find_chance := v_bonus_find_chance * 1.5; END IF;
    END IF;

    -- 3. DOUBLE LOOT (Lv 99 Mastery)
    IF v_excavation_level >= 99 AND random() < 0.15 THEN v_double_loot := TRUE; END IF;
    IF v_perfect_count >= 2 THEN v_double_loot := TRUE; v_xp_gain := v_xp_gain + 50; END IF;

    -- 4. ROLL
    v_roll := random();
    IF v_roll < v_anomaly_rate THEN
        v_result := 'ANOMALY';
        v_anomaly_happened := TRUE;
        v_xp_gain := v_xp_gain + 25;
    ELSIF v_roll < (v_anomaly_rate + v_base_find_chance + v_bonus_find_chance + v_static_bonus + v_focused_survey_bonus) AND v_profile.tray_count < 5 THEN
        v_crate_dropped := TRUE;
        v_result := 'CRATE_FOUND';
        v_xp_gain := v_xp_gain + 15;
    ELSE
        v_scrap_gain := v_scrap_gain + floor(random() * 11 + 5)::INT;
        v_result := 'SCRAP_FOUND';
        v_xp_gain := v_xp_gain + 5;
    END IF;

    IF v_double_loot THEN v_scrap_gain := v_scrap_gain * 2; END IF;

    -- 5. CRATE GENERATION (Applying Branch Bias)
    IF v_crate_dropped THEN
        v_contents := public.rpc_helper_generate_crate_contents(COALESCE(v_profile.active_zone_id, 'industrial_zone'), v_user_id);
        
        -- Insert into vault_items for persistence (from strategy migration)
        INSERT INTO public.vault_items (
            id, user_id, item_id, source_zone_id, source_static_tier, created_at, attributes
        ) VALUES (
            v_crate_id, v_user_id, 'unidentified_crate', 
            COALESCE(v_profile.active_zone_id, 'industrial_zone'), v_heatmap.static_tier, NOW(), v_contents
        );

        v_new_crate_data := jsonb_build_object(
            'id', v_crate_id,
            'source_zone_id', COALESCE(v_profile.active_zone_id, 'industrial_zone'),
            'source_static_tier', v_heatmap.static_tier,
            'found_at', NOW(),
            'contents', v_contents,
            'appraised', false
        );
    END IF;

    -- 6. UPDATE PROFILE
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
            WHEN v_crate_dropped AND v_double_loot AND tray_count < 4 THEN COALESCE(crate_tray, '[]'::JSONB) || v_new_crate_data || v_new_crate_data
            WHEN v_crate_dropped THEN COALESCE(crate_tray, '[]'::JSONB) || v_new_crate_data
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
        'double_loot', v_double_loot,
        'anomaly', v_anomaly_happened,
        'new_balance', v_final_balance,
        'new_xp', v_final_xp,
        'new_tray_count', v_final_tray_count,
        'crate_tray', v_final_crate_tray
    );
END;
$$;

-- 4. UNIFIED: Sift V2 (Heatmaps + Masteries + Specializations + Salvage)
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
    v_crate RECORD;
    v_base_stability FLOAT;
    v_bonus_stability FLOAT := 0;
    v_stability_penalty FLOAT := 0;
    v_survey_active BOOLEAN := FALSE;
    v_roll FLOAT;
    v_success BOOLEAN;
    v_xp_gain INT := 0;
    v_restoration_level INT;
    v_overclock_bonus FLOAT := 0;
    
    -- Fail/Salvage
    v_fail_roll FLOAT;
    v_base_crit_chance FLOAT := 0.20;
    v_zone_mult FLOAT := 0.0;
    v_tether_mult FLOAT := 1.0;
    v_final_crit_chance FLOAT;
    v_is_critical BOOLEAN;
    v_dust_payout INT := 0;
    v_salvage_token UUID := NULL;
    v_pending_fragment BOOLEAN := FALSE;
    v_fragment_chance FLOAT := 0.25;
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    SELECT * INTO v_lab FROM public.lab_state WHERE user_id = v_user_id;

    IF v_lab IS NULL OR NOT v_lab.is_active THEN RETURN jsonb_build_object('success', false, 'error', 'No active crate'); END IF;

    -- 1. BASE STABILITY
    CASE v_lab.current_stage
        WHEN 0 THEN v_base_stability := 0.90;
        WHEN 1 THEN v_base_stability := 0.75;
        WHEN 2 THEN v_base_stability := 0.50;
        WHEN 3 THEN v_base_stability := 0.25;
        WHEN 4 THEN v_base_stability := 0.10;
        ELSE v_base_stability := 0.05;
    END CASE;

    -- 2. PENALTIES (Heatmaps)
    -- Metadata from crate JSONB in lab_state
    -- v_lab.active_crate format: {"id": "...", "source_static_tier": "HIGH"}
    IF v_lab.active_crate->>'source_static_tier' = 'HIGH' THEN v_stability_penalty := 0.05;
    ELSIF v_lab.active_crate->>'source_static_tier' = 'MED' THEN v_stability_penalty := 0.025;
    END IF;

    -- Survey Mitigation
    IF v_profile.last_survey_at IS NOT NULL AND v_profile.last_survey_at > NOW() - INTERVAL '10 minutes' THEN
        v_survey_active := TRUE;
        v_stability_penalty := v_stability_penalty * 0.5;
    END IF;

    -- 3. BONUSES (Mastery + Level + Overclock)
    v_restoration_level := public.get_level(COALESCE(v_profile.restoration_xp, 0));
    v_bonus_stability := v_restoration_level * 0.001;
    v_overclock_bonus := COALESCE(v_profile.overclock_bonus, 0);
    
    -- Master Preserver Mastery (Lv 99)
    IF v_restoration_level >= 99 THEN
        v_bonus_stability := v_bonus_stability + 0.10;
    END IF;

    -- Restoration Branches
    IF v_profile.restoration_branch = 'master_preserver' AND v_lab.current_stage <= 3 THEN
        v_bonus_stability := v_bonus_stability + 0.03;
    ELSIF v_profile.restoration_branch = 'swift_handler' AND v_lab.current_stage >= 4 THEN
        v_bonus_stability := v_bonus_stability + 0.02;
    END IF;

    -- Tethers
    v_bonus_stability := v_bonus_stability + (p_tethers_used * 0.15);

    -- 4. ROLL SUCCESS
    v_roll := random();
    v_success := v_roll < (v_base_stability + v_bonus_stability + v_overclock_bonus - v_stability_penalty);

    IF v_success THEN
        v_xp_gain := (v_lab.current_stage + 1) * 10;
        UPDATE public.lab_state SET current_stage = current_stage + 1, last_action_at = NOW(), salvage_token = NULL WHERE user_id = v_user_id;
        UPDATE public.profiles SET restoration_xp = restoration_xp + v_xp_gain WHERE id = v_user_id;
        
        RETURN jsonb_build_object('success', true, 'outcome', 'SUCCESS', 'new_stage', v_lab.current_stage + 1, 'xp_gain', v_xp_gain);
    ELSE
        -- 5. FAIL LOGIC (Shatter vs Stabilized)
        IF p_zone = 1 THEN v_zone_mult := 2.5; END IF;
        IF p_tethers_used > 0 THEN v_tether_mult := 0.5; END IF;
        
        v_final_crit_chance := LEAST(0.9, v_base_crit_chance * v_zone_mult * v_tether_mult);
        IF v_lab.active_crate->>'source_static_tier' = 'HIGH' THEN v_final_crit_chance := v_final_crit_chance + 0.10; END IF;

        v_fail_roll := random();
        v_is_critical := v_fail_roll < v_final_crit_chance;

        v_salvage_token := gen_random_uuid();

        IF v_is_critical THEN
            -- SHATTERED
             UPDATE public.lab_state SET is_active = FALSE, current_stage = 0, last_action_at = NOW(), salvage_token = v_salvage_token, salvage_expires_at = NOW() + INTERVAL '1.0 seconds', pending_salvage_dust = 0, pending_salvage_fragment = FALSE WHERE user_id = v_user_id;
        ELSE
            -- STABILIZED_FAIL
            v_dust_payout := (v_lab.current_stage * 2) + 3;
            IF v_profile.smelting_branch = 'fragment_alchemist' THEN v_fragment_chance := 0.40; v_dust_payout := floor(v_dust_payout * 1.10); END IF;
            IF v_lab.current_stage >= 3 AND random() < v_fragment_chance THEN v_pending_fragment := TRUE; END IF;

            UPDATE public.lab_state SET is_active = FALSE, current_stage = 0, last_action_at = NOW(), salvage_token = v_salvage_token, salvage_expires_at = NOW() + INTERVAL '1.15 seconds', pending_salvage_dust = v_dust_payout, pending_salvage_fragment = v_pending_fragment WHERE user_id = v_user_id;
            UPDATE public.profiles SET fine_dust_balance = fine_dust_balance + v_dust_payout WHERE id = v_user_id;
        END IF;

        -- Cleanup tray
        UPDATE public.profiles SET tray_count = GREATEST(0, tray_count - 1), crate_tray = array_remove(crate_tray, v_lab.active_crate->>'id') WHERE id = v_user_id;

        RETURN jsonb_build_object(
            'success', true, 
            'outcome', CASE WHEN v_is_critical THEN 'SHATTERED' ELSE 'STABILIZED_FAIL' END, 
            'critical', v_is_critical, 
            'salvage_token', v_salvage_token,
            'dust_payout', v_dust_payout
        );
    END IF;
END;
$$;

-- 5. NEW: World Event Contribution
CREATE OR REPLACE FUNCTION public.rpc_world_event_contribute(p_amount INT, p_currency TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_event RECORD;
    v_profile RECORD;
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;
    
    SELECT * INTO v_event FROM public.world_events WHERE status = 'active' AND ends_at > NOW() LIMIT 1;
    IF v_event IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'No active world event'); END IF;

    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;

    IF p_currency = 'scrap' THEN
        IF v_profile.scrap_balance < p_amount THEN RETURN jsonb_build_object('success', false, 'error', 'Insufficient Scrap'); END IF;
        UPDATE public.profiles SET scrap_balance = scrap_balance - p_amount WHERE id = v_user_id;
    ELSIF p_currency = 'dust' THEN
        IF v_profile.fine_dust_balance < p_amount THEN RETURN jsonb_build_object('success', false, 'error', 'Insufficient Dust'); END IF;
        UPDATE public.profiles SET fine_dust_balance = fine_dust_balance - p_amount WHERE id = v_user_id;
    ELSE
        RETURN jsonb_build_object('success', false, 'error', 'Invalid currency');
    END IF;

    -- Update Event Progress
    -- 1 Scrap = 1 Progress, 1 Dust = 5 Progress
    UPDATE public.world_events 
    SET global_goal_progress = global_goal_progress + (CASE WHEN p_currency = 'scrap' THEN p_amount ELSE p_amount * 5 END)
    WHERE id = v_event.id;

    -- Award HI (1 HI per 100 progress contributed)
    UPDATE public.profiles SET historical_influence = historical_influence + (CASE WHEN p_currency = 'scrap' THEN p_amount / 100 ELSE p_amount * 5 / 100 END)::INT WHERE id = v_user_id;

    RETURN jsonb_build_object('success', true, 'new_progress', (SELECT global_goal_progress FROM public.world_events WHERE id = v_event.id));
END;
$$;

-- 6. IMPROVED: Trending Item Rotation
CREATE OR REPLACE FUNCTION public.rpc_refresh_heatmaps()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_zone TEXT;
    v_tier TEXT;
    v_trending UUID[];
BEGIN
    FOR v_zone IN SELECT zone_id FROM public.vault_heatmaps LOOP
        v_tier := (ARRAY['LOW', 'MED', 'HIGH'])[floor(random() * 3) + 1];
        
        -- Pick trending items that actually exist in definitions
        SELECT array_agg(id) INTO v_trending FROM (
            SELECT id FROM public.item_definitions 
            WHERE tier IN ('uncommon', 'rare', 'epic') 
            ORDER BY random() 
            LIMIT 3
        ) sub;

        UPDATE public.vault_heatmaps 
        SET 
            static_tier = v_tier,
            trending_items = v_trending,
            updated_at = NOW()
        WHERE zone_id = v_zone;

        -- Global Event
        INSERT INTO public.global_events (event_type, details)
        VALUES ('static_shift', jsonb_build_object('zone_id', v_zone, 'tier', v_tier));
    END LOOP;

    RETURN jsonb_build_object('success', true);
END;
$$;

-- Permissions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;
NOTIFY pgrst, 'reload schema';
