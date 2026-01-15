-- Robusifying Sift and Claim for Local Identity Support
-- 1. Robust Sift
CREATE OR REPLACE FUNCTION public.rpc_sift()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_lab RECORD;
    v_profile RECORD;
    v_base_stability FLOAT;
    v_bonus_stability FLOAT;
    v_final_stability FLOAT;
    v_roll FLOAT;
    v_success BOOLEAN;
    v_xp_gain INT := 0;
    v_restoration_level INT;
    v_overclock_bonus FLOAT := 0;
BEGIN
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated');
    END IF;

    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    SELECT * INTO v_lab FROM public.lab_state WHERE user_id = v_user_id;
    
    IF v_lab IS NULL OR NOT v_lab.is_active THEN
        RETURN jsonb_build_object('success', false, 'error', 'No active crate in lab');
    END IF;

    -- Base Stability per stage
    CASE v_lab.current_stage
        WHEN 0 THEN v_base_stability := 0.90;
        WHEN 1 THEN v_base_stability := 0.75;
        WHEN 2 THEN v_base_stability := 0.50;
        WHEN 3 THEN v_base_stability := 0.25;
        WHEN 4 THEN v_base_stability := 0.10;
        ELSE v_base_stability := 0;
    END CASE;

    -- Level Bonus: +0.1% per level
    v_restoration_level := public.get_level(COALESCE(v_profile.restoration_xp, 0));
    v_bonus_stability := v_restoration_level * 0.001;
    v_overclock_bonus := COALESCE(v_profile.overclock_bonus, 0);
    
    v_final_stability := v_base_stability + v_bonus_stability + v_overclock_bonus;

    -- Roll
    v_roll := random();
    v_success := v_roll < v_final_stability;

    IF v_success THEN
        v_xp_gain := (v_lab.current_stage + 1) * 10;
        UPDATE public.lab_state SET current_stage = current_stage + 1, last_action_at = NOW() WHERE user_id = v_user_id;
        UPDATE public.profiles SET restoration_xp = COALESCE(restoration_xp, 0) + v_xp_gain WHERE id = v_user_id;
        
        RETURN jsonb_build_object(
            'success', true, 
            'outcome', 'SUCCESS', 
            'new_stage', v_lab.current_stage + 1,
            'xp_gain', v_xp_gain
        );
    ELSE
        -- SHATTERED
        UPDATE public.lab_state SET is_active = FALSE, current_stage = 0, last_action_at = NOW() WHERE user_id = v_user_id;
        UPDATE public.profiles SET tray_count = GREATEST(0, COALESCE(tray_count, 0) - 1) WHERE id = v_user_id;
        
        RETURN jsonb_build_object(
            'success', true, 
            'outcome', 'SHATTERED',
            'xp_gain', 2 -- Pity XP
        );
    END IF;
END;
$$;

-- 2. Robust Claim
CREATE OR REPLACE FUNCTION public.rpc_claim()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_lab RECORD;
    v_item_id TEXT;
    v_tier TEXT;
    v_mint_num BIGINT;
BEGIN
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated');
    END IF;

    SELECT * INTO v_lab FROM public.lab_state WHERE user_id = v_user_id;
    
    IF v_lab IS NULL OR NOT v_lab.is_active THEN
        RETURN jsonb_build_object('success', false, 'error', 'No active crate to claim');
    END IF;

    -- Determine Tier
    IF v_lab.current_stage >= 3 THEN
        v_tier := 'rare';
    ELSE
        v_tier := 'common';
    END IF;

    -- Pick random item
    IF v_tier = 'rare' THEN
        SELECT item INTO v_item_id FROM unnest(ARRAY['calculated_tablet', 'wrist_chronometer', 'compact_disc', 'remote_control', 'computer_mouse', 'flashlight', 'headphone_set', 'digital_camera']) AS item ORDER BY random() LIMIT 1;
    ELSE
        SELECT item INTO v_item_id FROM unnest(ARRAY['rusty_key', 'ceramic_mug', 'aa_battery', 'plastic_comb', 'steel_fork', 'lightbulb', 'ballpoint_pen', 'eyeglass_frame', 'soda_tab', 'safety_pin', 'rubber_band', 'broken_watch']) AS item ORDER BY random() LIMIT 1;
    END IF;

    -- Assign mint number
    INSERT INTO public.item_mints (item_id, next_mint_number)
    VALUES (v_item_id, 1)
    ON CONFLICT (item_id) DO UPDATE SET next_mint_number = public.item_mints.next_mint_number + 1
    RETURNING next_mint_number - 1 INTO v_mint_num;

    -- Save to vault
    INSERT INTO public.vault_items (user_id, item_id, mint_number) 
    VALUES (v_user_id, v_item_id, v_mint_num);

    -- Clean up lab and tray
    UPDATE public.lab_state SET is_active = FALSE, current_stage = 0, last_action_at = NOW() WHERE user_id = v_user_id;
    UPDATE public.profiles SET tray_count = GREATEST(0, COALESCE(tray_count, 0) - 1) WHERE id = v_user_id;

    RETURN jsonb_build_object(
        'success', true, 
        'item_id', v_item_id, 
        'tier', v_tier,
        'mint_number', v_mint_num
    );
END;
$$;
