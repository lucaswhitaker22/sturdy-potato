-- 20240116000035_blueprint_appraisal.sql
-- Enhances Appraisal with level curves, sub-stat reveals, and Level 99 Oracle intel.

-- 1. Helper: Get Zone Trending IDs
-- Returns a sample of names found in the specified zone.
CREATE OR REPLACE FUNCTION public.rpc_helper_get_zone_trends(p_zone_id TEXT)
RETURNS TEXT[]
LANGUAGE plpgsql
AS $$
DECLARE
    v_item_names TEXT[];
BEGIN
    SELECT array_agg(DISTINCT name) INTO v_item_names
    FROM (
        SELECT name FROM public.item_definitions 
        -- This logic assumes items have a zone_id or similar, 
        -- providing a fallback to random items if zone tags aren't implemented yet.
        ORDER BY random() 
        LIMIT 3
    ) x;
    RETURN v_item_names;
END;
$$;

-- 2. Enhanced Appraisal RPC
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
        v_success_chance := 0.70 + (v_player_level - 60) * 0.004; -- Up to ~0.85
    ELSIF v_player_level >= 31 THEN
        v_success_chance := 0.50 + (v_player_level - 30) * 0.006; -- Up to 0.68
    ELSE
        v_success_chance := 0.30 + (v_player_level * 0.0067); -- Up to 0.50
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
                    -- Reveal sub-stats (placeholders representing keys)
                    v_intel := v_intel || jsonb_build_object('type', 'sub_stats', 'label', 'Inner Affixes', 'value', 'Critical, Luck');
                END IF;

                -- E. The Oracle: Zone Trends (Level 99)
                IF v_player_level >= 99 THEN
                    v_trends := public.rpc_helper_get_zone_trends(v_zone_id);
                    v_intel := v_intel || jsonb_build_object('type', 'zone_trends', 'label', 'Local Market Trends', 'value', array_to_string(v_trends, ', '));
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
