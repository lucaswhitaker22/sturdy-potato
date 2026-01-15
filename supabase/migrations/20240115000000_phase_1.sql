-- Phase 1 Schema: The Clicker Foundation

-- 1. Profiles (Player State)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    scrap_balance BIGINT DEFAULT 0 CHECK (scrap_balance >= 0),
    tray_count INT DEFAULT 0 CHECK (tray_count >= 0 AND tray_count <= 5),
    last_extract_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Vault Items (Collection)
CREATE TABLE IF NOT EXISTS public.vault_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    item_id TEXT NOT NULL,
    discovered_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Lab State (Current Crate)
CREATE TABLE IF NOT EXISTS public.lab_state (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    current_stage INT DEFAULT 0, -- 0 to 5
    is_active BOOLEAN DEFAULT FALSE,
    last_action_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vault_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lab_state ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can view own vault" ON public.vault_items;
CREATE POLICY "Users can view own vault" ON public.vault_items FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own lab state" ON public.lab_state;
CREATE POLICY "Users can view own lab state" ON public.lab_state FOR SELECT USING (auth.uid() = user_id);

-- RPC: handle_extraction
CREATE OR REPLACE FUNCTION public.rpc_extract()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_profile RECORD;
    v_roll FLOAT;
    v_result TEXT;
    v_scrap_gain INT := 0;
    v_crate_dropped BOOLEAN := FALSE;
    v_cooldown_sec INT := 3;
BEGIN
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    
    -- Check cooldown
    IF v_profile.last_extract_at > NOW() - (v_cooldown_sec || ' seconds')::INTERVAL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Cooldown active');
    END IF;

    v_roll := random();
    
    IF v_roll < 0.2 AND v_profile.tray_count < 5 THEN
        -- Crate Drop (20%)
        v_crate_dropped := TRUE;
        v_result := 'CRATE_FOUND';
    ELSIF v_roll < 0.9 THEN
        -- Scrap (70%)
        v_scrap_gain := floor(random() * (15 - 5 + 1) + 5)::INT;
        v_result := 'SCRAP_FOUND';
    ELSE
        -- Nothing (10%)
        v_result := 'NOTHING_FOUND';
    END IF;

    UPDATE public.profiles
    SET 
        scrap_balance = scrap_balance + v_scrap_gain,
        tray_count = CASE WHEN v_crate_dropped THEN tray_count + 1 ELSE tray_count END,
        last_extract_at = NOW(),
        updated_at = NOW()
    WHERE id = v_user_id;

    RETURN jsonb_build_object(
        'success', true, 
        'result', v_result, 
        'scrap_gain', v_scrap_gain, 
        'crate_dropped', v_crate_dropped,
        'new_balance', v_profile.scrap_balance + v_scrap_gain,
        'new_tray_count', CASE WHEN v_crate_dropped THEN v_profile.tray_count + 1 ELSE v_profile.tray_count END
    );
END;
$$;

-- RPC: rpc_sift
CREATE OR REPLACE FUNCTION public.rpc_sift()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_lab RECORD;
    v_stability FLOAT;
    v_roll FLOAT;
    v_success BOOLEAN;
BEGIN
    SELECT * INTO v_lab FROM public.lab_state WHERE user_id = v_user_id;
    
    IF v_lab IS NULL OR NOT v_lab.is_active THEN
        RETURN jsonb_build_object('success', false, 'error', 'No active crate in lab');
    END IF;

    -- Stability based on stage
    CASE v_lab.current_stage
        WHEN 0 THEN v_stability := 0.90;
        WHEN 1 THEN v_stability := 0.75;
        WHEN 2 THEN v_stability := 0.50;
        WHEN 3 THEN v_stability := 0.25;
        WHEN 4 THEN v_stability := 0.10;
        ELSE v_stability := 0;
    END CASE;

    v_roll := random();
    v_success := v_roll < v_stability;

    IF v_success THEN
        UPDATE public.lab_state SET current_stage = current_stage + 1, last_action_at = NOW() WHERE user_id = v_user_id;
        RETURN jsonb_build_object('success', true, 'outcome', 'SUCCESS', 'new_stage', v_lab.current_stage + 1);
    ELSE
        UPDATE public.lab_state SET is_active = FALSE, current_stage = 0, last_action_at = NOW() WHERE user_id = v_user_id;
        UPDATE public.profiles SET tray_count = tray_count - 1 WHERE id = v_user_id;
        RETURN jsonb_build_object('success', true, 'outcome', 'SHATTERED');
    END IF;
END;
$$;

-- RPC: rpc_claim
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
BEGIN
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

    -- Pick random item (MVP shortcut: we assume the catalog is known or we just return a slug)
    -- In a real app, we might have an items table. Here we'll just pick from a list of strings
    -- matching the constants.
    IF v_tier = 'rare' THEN
        SELECT item INTO v_item_id FROM unnest(ARRAY['calculated_tablet', 'wrist_chronometer', 'compact_disc', 'remote_control', 'computer_mouse', 'flashlight', 'headphone_set', 'digital_camera']) AS item ORDER BY random() LIMIT 1;
    ELSE
        SELECT item INTO v_item_id FROM unnest(ARRAY['rusty_key', 'ceramic_mug', 'aa_battery', 'plastic_comb', 'steel_fork', 'lightbulb', 'ballpoint_pen', 'eyeglass_frame', 'soda_tab', 'safety_pin', 'rubber_band', 'broken_watch']) AS item ORDER BY random() LIMIT 1;
    END IF;

    -- Save to vault
    INSERT INTO public.vault_items (user_id, item_id) VALUES (v_user_id, v_item_id);

    -- Clean up lab and tray
    UPDATE public.lab_state SET is_active = FALSE, current_stage = 0, last_action_at = NOW() WHERE user_id = v_user_id;
    UPDATE public.profiles SET tray_count = tray_count - 1 WHERE id = v_user_id;

    RETURN jsonb_build_object('success', true, 'item_id', v_item_id, 'tier', v_tier);
END;
$$;
