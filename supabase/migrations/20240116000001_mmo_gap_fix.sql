-- 20240116000001_mmo_gap_fix.sql

-- 1. Profiles Schema Update
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS appraisal_xp BIGINT DEFAULT 0 CHECK (appraisal_xp >= 0),
ADD COLUMN IF NOT EXISTS owned_permits TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS owned_titles TEXT[] DEFAULT '{}';

-- 2. Museum Weeks Schema Update
ALTER TABLE public.museum_weeks
ADD COLUMN IF NOT EXISTS target_collection_id TEXT REFERENCES public.collection_definitions(id);

-- 3. Updated rpc_settle_listing (Dynamic Tax Logic)
CREATE OR REPLACE FUNCTION public.rpc_settle_listing(p_listing_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_listing RECORD;
    v_seller_profile RECORD;
    v_seller_payout BIGINT;
    v_tax BIGINT;
    v_tax_rate NUMERIC := 0.05;
    v_item_name TEXT;
    v_appraisal_level INT;
BEGIN
    SELECT m.*, v.item_id as item_name INTO v_listing 
    FROM public.market_listings m
    JOIN public.vault_items v ON m.vault_item_id = v.id
    WHERE m.id = p_listing_id;

    IF v_listing.status <> 'active' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Listing not active');
    END IF;

    IF v_listing.ends_at > NOW() THEN
         RETURN jsonb_build_object('success', false, 'error', 'Auction not yet ended');
    END IF;

    -- Update Listing Status
    UPDATE public.market_listings SET status = 'ended' WHERE id = p_listing_id;

    IF v_listing.highest_bidder_id IS NOT NULL THEN
        -- Check Seller Appraisal Level
        SELECT * INTO v_seller_profile FROM public.profiles WHERE id = v_listing.seller_id;
        
        -- Simple level calc: if xp > 13M (approx lvl 99) -> 2.5% tax
        -- Using a simplified check for now or calling a helper if it existed.
        -- Let's assume Level 99 threshold is 13,034,431 XP
        IF v_seller_profile.appraisal_xp >= 13034431 THEN
            v_tax_rate := 0.025;
        END IF;

        -- Award Appraisal XP to Seller (e.g. 10% of sale value)
        UPDATE public.profiles 
        SET appraisal_xp = appraisal_xp + floor(v_listing.highest_bid * 0.1)::BIGINT 
        WHERE id = v_listing.seller_id;

        -- Transfer Item
        UPDATE public.vault_items SET user_id = v_listing.highest_bidder_id WHERE id = v_listing.vault_item_id;
        
        -- Calculate Payout
        v_tax := floor(v_listing.highest_bid * v_tax_rate);
        v_seller_payout := (v_listing.highest_bid - v_tax) + v_listing.deposit_amount;
        
        -- Pay Seller
        UPDATE public.profiles SET scrap_balance = scrap_balance + v_seller_payout WHERE id = v_listing.seller_id;
        
        -- Notifications
        INSERT INTO public.notifications (user_id, message, type)
        VALUES (v_listing.seller_id, 'Your ' || v_listing.item_name || ' sold for ' || v_listing.highest_bid || ' scrap! Tax: ' || v_tax, 'success');
        
        INSERT INTO public.notifications (user_id, message, type)
        VALUES (v_listing.highest_bidder_id, 'You won the auction for ' || v_listing.item_name || '!', 'success');
        
        -- Global Event
        INSERT INTO public.global_events (event_type, user_id, details)
        VALUES ('sale', v_listing.seller_id, jsonb_build_object('item_id', v_listing.item_name, 'price', v_listing.highest_bid));
        
        RETURN jsonb_build_object('success', true, 'outcome', 'sold', 'tax_paid', v_tax);
    ELSE
        -- Refund Deposit
        UPDATE public.profiles SET scrap_balance = scrap_balance + v_listing.deposit_amount WHERE id = v_listing.seller_id;
        
        INSERT INTO public.notifications (user_id, message, type)
        VALUES (v_listing.seller_id, 'Your auction for ' || v_listing.item_name || ' expired with no bids.', 'info');
        
        RETURN jsonb_build_object('success', true, 'outcome', 'expired');
    END IF;
END;
$$;

-- 4. Updated rpc_museum_submit_item (Correct Scoring)
CREATE OR REPLACE FUNCTION public.rpc_museum_submit_item(p_vault_item_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_week RECORD;
    v_item RECORD;
    v_score NUMERIC;
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

    -- Calculate Score (Base from HV)
    v_score := COALESCE(v_item.historical_value, 10); 

    -- Update lock on item
    UPDATE public.vault_items SET locked_until = v_week.ends_at WHERE id = p_vault_item_id;

    -- Insert submission
    INSERT INTO public.museum_submissions (week_id, player_id, vault_item_id, score, locked_until)
    VALUES (v_week.id, v_user_id, p_vault_item_id, v_score, v_week.ends_at);

    -- Note: Set bonus is calculated on READ (get_current_week) because it depends on the full state of submissions
    
    RETURN jsonb_build_object('success', true, 'score', v_score);
END;
$$;

-- 5. Updated rpc_museum_get_current_week (Set Bonus)
CREATE OR REPLACE FUNCTION public.rpc_museum_get_current_week()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_week RECORD;
    v_submissions JSONB;
    v_total_score NUMERIC := 0;
    v_has_set_bonus BOOLEAN := FALSE;
    v_target_set_ids TEXT[];
    v_missing_count INT;
BEGIN
    SELECT * INTO v_week FROM public.museum_weeks WHERE status = 'active' ORDER BY ends_at ASC LIMIT 1;
    
    IF v_week IS NULL THEN
        RETURN jsonb_build_object('success', true, 'active_week', null);
    END IF;

    -- Get user submissions
    WITH user_subs AS (
        SELECT s.vault_item_id, s.score, i.item_id, i.mint_number
        FROM public.museum_submissions s
        JOIN public.vault_items i ON s.vault_item_id = i.id
        WHERE s.week_id = v_week.id AND s.player_id = v_user_id
    )
    SELECT 
        jsonb_agg(jsonb_build_object(
            'vault_item_id', vault_item_id,
            'score', score,
            'item_details', jsonb_build_object('item_id', item_id, 'mint_number', mint_number)
        )),
        COALESCE(SUM(score), 0)
    INTO v_submissions, v_total_score
    FROM user_subs;
    
    -- Calculate Set Bonus
    IF v_week.target_collection_id IS NOT NULL THEN
        SELECT required_item_ids INTO v_target_set_ids 
        FROM public.collection_definitions 
        WHERE id = v_week.target_collection_id;
        
        IF v_target_set_ids IS NOT NULL THEN
             -- Check if all target items are present in submissions
             -- This logic assumes one item per ID is enough
             SELECT COUNT(*) INTO v_missing_count
             FROM unnest(v_target_set_ids) AS req_id
             WHERE req_id NOT IN (
                 SELECT i.item_id 
                 FROM public.museum_submissions s
                 JOIN public.vault_items i ON s.vault_item_id = i.id
                 WHERE s.week_id = v_week.id AND s.player_id = v_user_id
             );
             
             IF v_missing_count = 0 THEN
                 v_has_set_bonus := TRUE;
                 v_total_score := floor(v_total_score * 1.5); -- 1.5x Multiplier
             END IF;
        END IF;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'active_week', jsonb_build_object(
            'id', v_week.id,
            'theme_name', v_week.theme_name,
            'description', v_week.description,
            'ends_at', v_week.ends_at,
            'target_collection_id', v_week.target_collection_id
        ),
        'user_submissions', COALESCE(v_submissions, '[]'::jsonb),
        'total_score', v_total_score,
        'set_bonus_active', v_has_set_bonus
    );
END;
$$;

-- 6. Updated rpc_purchase_influence_item (Unlock)
CREATE OR REPLACE FUNCTION public.rpc_purchase_influence_item(p_item_key TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_profile RECORD;
    v_cost INT;
    v_type TEXT; -- 'title' or 'permit'
BEGIN
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;
    
    -- Define items (Hardcoded for now as per phase specs)
    IF p_item_key = 'zone_permit_suburbs' THEN
        v_cost := 500;
        v_type := 'permit';
    ELSIF p_item_key = 'title_curator' THEN
        v_cost := 200;
        v_type := 'title';
    ELSIF p_item_key = 'title_auctioneer' THEN
        v_cost := 1000;
        v_type := 'title';
    ELSIF p_item_key = 'zone_permit_mall' THEN
        v_cost := 2500;
        v_type := 'permit';
    ELSE
        RETURN jsonb_build_object('success', false, 'error', 'Invalid item');
    END IF;
    
    -- Check if already owned
    IF v_type = 'permit' AND p_item_key = ANY(v_profile.owned_permits) THEN
         RETURN jsonb_build_object('success', false, 'error', 'Already owned');
    END IF;
    
    IF v_type = 'title' AND p_item_key = ANY(v_profile.owned_titles) THEN
         RETURN jsonb_build_object('success', false, 'error', 'Already owned');
    END IF;

    IF v_profile.historical_influence < v_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient influence');
    END IF;

    -- Deduct Cost
    UPDATE public.profiles SET historical_influence = historical_influence - v_cost WHERE id = v_user_id;

    -- Grant Item
    IF v_type = 'permit' THEN
        UPDATE public.profiles SET owned_permits = array_append(owned_permits, p_item_key) WHERE id = v_user_id;
    ELSE
        UPDATE public.profiles SET owned_titles = array_append(owned_titles, p_item_key) WHERE id = v_user_id;
    END IF;

    INSERT INTO public.historical_influence_transactions (player_id, amount, source)
    VALUES (v_user_id, -v_cost, 'shop_purchase_' || p_item_key);

    RETURN jsonb_build_object('success', true);
END;
$$;
