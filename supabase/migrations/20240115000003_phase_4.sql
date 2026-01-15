-- Phase 4: The High Curator Meta-Game

-- 1. Modify Profiles
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS historical_influence INTEGER DEFAULT 0 NOT NULL CHECK (historical_influence >= 0);

-- 2. Modify Vault Items (Corrected from inventory_items)
ALTER TABLE public.vault_items
ADD COLUMN IF NOT EXISTS certified_by_player_id UUID REFERENCES public.profiles(id),
ADD COLUMN IF NOT EXISTS certification_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS attributes JSONB DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS locked_until TIMESTAMPTZ;

-- 3. Museum Tables
DO $$ BEGIN
    CREATE TYPE museum_week_status AS ENUM ('active', 'calculating', 'finalized');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS public.museum_weeks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    theme_name TEXT NOT NULL,
    description TEXT,
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    status museum_week_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.museum_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    week_id UUID REFERENCES public.museum_weeks(id) NOT NULL,
    player_id UUID REFERENCES public.profiles(id) NOT NULL,
    vault_item_id UUID REFERENCES public.vault_items(id) NOT NULL,
    score NUMERIC NOT NULL,
    locked_until TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(week_id, vault_item_id)
);

-- 4. Historical Influence Transactions
CREATE TABLE IF NOT EXISTS public.historical_influence_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID REFERENCES public.profiles(id) NOT NULL,
    amount INTEGER NOT NULL,
    source TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. World Events
DO $$ BEGIN
    CREATE TYPE world_event_status AS ENUM ('upcoming', 'active', 'ended');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS public.world_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    status world_event_status NOT NULL DEFAULT 'upcoming',
    modifiers JSONB DEFAULT '{}'::jsonb,
    global_goal_target BIGINT NOT NULL,
    global_goal_progress BIGINT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.world_event_contributions (
    event_id UUID REFERENCES public.world_events(id) NOT NULL,
    player_id UUID REFERENCES public.profiles(id) NOT NULL,
    contribution_value BIGINT NOT NULL DEFAULT 0,
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (event_id, player_id)
);

-- 6. RLS Policies

-- Museum Weeks
ALTER TABLE public.museum_weeks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Everyone can view museum weeks" ON public.museum_weeks;
CREATE POLICY "Everyone can view museum weeks" ON public.museum_weeks FOR SELECT USING (true);

-- Museum Submissions
ALTER TABLE public.museum_submissions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Everyone can view museum submissions" ON public.museum_submissions;
CREATE POLICY "Everyone can view museum submissions" ON public.museum_submissions FOR SELECT USING (true);

-- Historical Influence Transactions
ALTER TABLE public.historical_influence_transactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own influence transactions" ON public.historical_influence_transactions;
CREATE POLICY "Users can view own influence transactions" ON public.historical_influence_transactions FOR SELECT USING (auth.uid() = player_id);

-- World Events
ALTER TABLE public.world_events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Everyone can view world events" ON public.world_events;
CREATE POLICY "Everyone can view world events" ON public.world_events FOR SELECT USING (true);

-- World Event Contributions
ALTER TABLE public.world_event_contributions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Everyone can view event contributions" ON public.world_event_contributions;
CREATE POLICY "Everyone can view event contributions" ON public.world_event_contributions FOR SELECT USING (true);


-- 7. RPC: Get Current Museum Week
CREATE OR REPLACE FUNCTION public.rpc_museum_get_current_week()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_week RECORD;
    v_submissions JSONB;
BEGIN
    SELECT * INTO v_week FROM public.museum_weeks WHERE status = 'active' ORDER BY ends_at ASC LIMIT 1;
    
    IF v_week IS NULL THEN
        RETURN jsonb_build_object('success', true, 'active_week', null);
    END IF;

    SELECT jsonb_agg(jsonb_build_object(
        'vault_item_id', s.vault_item_id,
        'score', s.score,
        'item_details', (SELECT jsonb_build_object('item_id', i.item_id, 'mint_number', i.mint_number) FROM public.vault_items i WHERE i.id = s.vault_item_id)
    )) INTO v_submissions 
    FROM public.museum_submissions s
    WHERE s.week_id = v_week.id AND s.player_id = v_user_id;

    RETURN jsonb_build_object(
        'success', true,
        'active_week', jsonb_build_object(
            'id', v_week.id,
            'theme_name', v_week.theme_name,
            'description', v_week.description,
            'ends_at', v_week.ends_at
        ),
        'user_submissions', COALESCE(v_submissions, '[]'::jsonb)
    );
END;
$$;

-- 8. RPC: Submit Item to Museum
CREATE OR REPLACE FUNCTION public.rpc_museum_submit_item(p_vault_item_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_week RECORD;
    v_item RECORD;
    v_score NUMERIC := 100; -- Placeholder
    v_submission_count INT;
BEGIN
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
    SELECT * INTO v_item FROM public.vault_items WHERE id = p_vault_item_id AND user_id = v_user_id;
    IF v_item IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Item not found');
    END IF;

    IF v_item.locked_until IS NOT NULL AND v_item.locked_until > NOW() THEN
        RETURN jsonb_build_object('success', false, 'error', 'Item is locked');
    END IF;

    -- Update lock on item
    UPDATE public.vault_items SET locked_until = v_week.ends_at WHERE id = p_vault_item_id;

    -- Insert submission
    INSERT INTO public.museum_submissions (week_id, player_id, vault_item_id, score, locked_until)
    VALUES (v_week.id, v_user_id, p_vault_item_id, v_score, v_week.ends_at);

    RETURN jsonb_build_object('success', true, 'score', v_score);
END;
$$;

-- 9. RPC: Purchase Influence Item
CREATE OR REPLACE FUNCTION public.rpc_purchase_influence_item(p_item_key TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_profile RECORD;
    v_cost INT;
BEGIN
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    
    -- Hardcoded shop logic for now
    IF p_item_key = 'zone_permit_suburbs' THEN
        v_cost := 500;
    ELSIF p_item_key = 'title_curator' THEN
        v_cost := 200;
    ELSE
        RETURN jsonb_build_object('success', false, 'error', 'Invalid item');
    END IF;

    IF v_profile.historical_influence < v_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient influence');
    END IF;

    UPDATE public.profiles SET historical_influence = historical_influence - v_cost WHERE id = v_user_id;

    INSERT INTO public.historical_influence_transactions (player_id, amount, source)
    VALUES (v_user_id, -v_cost, 'shop_purchase_' || p_item_key);

    RETURN jsonb_build_object('success', true);
END;
$$;

-- 10. RPC: Get Active World Event
CREATE OR REPLACE FUNCTION public.rpc_world_event_get_active()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_event RECORD;
BEGIN
    SELECT * INTO v_event FROM public.world_events WHERE status = 'active' AND ends_at > NOW() LIMIT 1;
    
    IF v_event IS NULL THEN
        RETURN jsonb_build_object('success', true, 'active_event', null);
    END IF;

    RETURN jsonb_build_object('success', true, 'active_event', row_to_json(v_event));
END;
$$;
