-- Phase 2: The Amateur Archaeologist Progression

-- 1. Extend Profiles
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS excavation_xp BIGINT DEFAULT 0 CHECK (excavation_xp >= 0),
ADD COLUMN IF NOT EXISTS restoration_xp BIGINT DEFAULT 0 CHECK (restoration_xp >= 0),
ADD COLUMN IF NOT EXISTS active_tool_id TEXT DEFAULT 'rusty_shovel',
ADD COLUMN IF NOT EXISTS last_logout_at TIMESTAMPTZ DEFAULT NOW();

-- 2. Owned Tools Table
CREATE TABLE IF NOT EXISTS public.owned_tools (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    tool_id TEXT NOT NULL,
    purchased_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, tool_id)
);

-- 3. Completed Sets Table
CREATE TABLE IF NOT EXISTS public.completed_sets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    set_id TEXT NOT NULL,
    claimed_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, set_id)
);

-- RLS for new tables
ALTER TABLE public.owned_tools ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.completed_sets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own tools" ON public.owned_tools;
CREATE POLICY "Users can view own tools" ON public.owned_tools FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own completed sets" ON public.completed_sets;
CREATE POLICY "Users can view own completed sets" ON public.completed_sets FOR SELECT USING (auth.uid() = user_id);

-- 4. Updated RPC: rpc_extract
-- Awards XP and applies tool bonuses
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
    v_xp_gain INT := 0;
    v_crate_dropped BOOLEAN := FALSE;
    v_cooldown_sec INT := 3;
    v_crate_rate FLOAT := 0.20; -- Base 20%
BEGIN
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    
    -- Check cooldown
    IF v_profile.last_extract_at > NOW() - (v_cooldown_sec || ' seconds')::INTERVAL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Cooldown active');
    END IF;

    -- Apply Tool Bonuses (Simplistic for now, should ideally be lookup in a tools table/config)
    IF v_profile.active_tool_id = 'pneumatic_pick' THEN v_crate_rate := 0.25; END IF;
    IF v_profile.active_tool_id = 'ground_radar' THEN v_crate_rate := 0.30; END IF;

    v_roll := random();
    
    IF v_roll < v_crate_rate AND v_profile.tray_count < 5 THEN
        v_crate_dropped := TRUE;
        v_result := 'CRATE_FOUND';
        v_xp_gain := 15;
    ELSIF v_roll < 0.9 THEN
        v_scrap_gain := floor(random() * (15 - 5 + 1) + 5)::INT;
        v_result := 'SCRAP_FOUND';
        v_xp_gain := 5;
    ELSE
        v_result := 'NOTHING_FOUND';
        v_xp_gain := 1;
    END IF;

    UPDATE public.profiles
    SET 
        scrap_balance = scrap_balance + v_scrap_gain,
        excavation_xp = excavation_xp + v_xp_gain,
        tray_count = CASE WHEN v_crate_dropped THEN tray_count + 1 ELSE tray_count END,
        last_extract_at = NOW(),
        updated_at = NOW()
    WHERE id = v_user_id;

    RETURN jsonb_build_object(
        'success', true, 
        'result', v_result, 
        'scrap_gain', v_scrap_gain, 
        'xp_gain', v_xp_gain,
        'crate_dropped', v_crate_dropped,
        'new_balance', v_profile.scrap_balance + v_scrap_gain,
        'new_xp', v_profile.excavation_xp + v_xp_gain,
        'new_tray_count', CASE WHEN v_crate_dropped THEN v_profile.tray_count + 1 ELSE v_profile.tray_count END
    );
END;
$$;

-- 5. Updated RPC: rpc_sift
-- Awards Restoration XP
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
    v_xp_gain INT := 0;
BEGIN
    SELECT * INTO v_lab FROM public.lab_state WHERE user_id = v_user_id;
    
    IF v_lab IS NULL OR NOT v_lab.is_active THEN
        RETURN jsonb_build_object('success', false, 'error', 'No active crate in lab');
    END IF;

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
        v_xp_gain := (v_lab.current_stage + 1) * 10;
        UPDATE public.lab_state SET current_stage = current_stage + 1, last_action_at = NOW() WHERE user_id = v_user_id;
        UPDATE public.profiles SET restoration_xp = restoration_xp + v_xp_gain WHERE id = v_user_id;
        RETURN jsonb_build_object('success', true, 'outcome', 'SUCCESS', 'new_stage', v_lab.current_stage + 1, 'xp_gain', v_xp_gain);
    ELSE
        UPDATE public.lab_state SET is_active = FALSE, current_stage = 0, last_action_at = NOW() WHERE user_id = v_user_id;
        UPDATE public.profiles SET tray_count = tray_count - 1 WHERE id = v_user_id;
        RETURN jsonb_build_object('success', true, 'outcome', 'SHATTERED');
    END IF;
END;
$$;

-- 6. RPC: rpc_upgrade_tool
CREATE OR REPLACE FUNCTION public.rpc_upgrade_tool(p_tool_id TEXT, p_cost INT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_profile RECORD;
BEGIN
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    
    IF v_profile.scrap_balance < p_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient scrap');
    END IF;

    INSERT INTO public.owned_tools (user_id, tool_id) 
    VALUES (v_user_id, p_tool_id)
    ON CONFLICT (user_id, tool_id) DO NOTHING;

    UPDATE public.profiles 
    SET scrap_balance = scrap_balance - p_cost, active_tool_id = p_tool_id, updated_at = NOW()
    WHERE id = v_user_id;

    RETURN jsonb_build_object('success', true, 'active_tool_id', p_tool_id);
END;
$$;
