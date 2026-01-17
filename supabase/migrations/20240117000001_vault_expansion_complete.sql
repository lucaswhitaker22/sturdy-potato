-- 20240117000001_vault_expansion_complete.sql

-- 1. Counter-Bazaar Schema Updates
ALTER TABLE public.market_listings 
ADD COLUMN IF NOT EXISTS is_counter BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS is_under_the_table BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS last_confiscation_check TIMESTAMPTZ DEFAULT NOW();

-- 2. Update rpc_list_item to support Counter-Bazaar
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

    RETURN jsonb_build_object('success', true, 'is_under_the_table', v_is_under_the_table);
END;
$$;

-- 3. Confiscation Check Logic
CREATE OR REPLACE FUNCTION public.rpc_check_confiscations()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_listing RECORD;
    v_confiscated_count INT := 0;
    v_roll FLOAT;
    v_risk FLOAT;
    v_appraisal_lvl INT;
BEGIN
    -- This would be called by a cron or admin tool
    FOR v_listing IN 
        SELECT m.*, p.appraisal_xp 
        FROM public.market_listings m
        JOIN public.profiles p ON m.seller_id = p.id
        WHERE m.status = 'active' 
        AND m.is_counter = TRUE 
        AND m.last_confiscation_check < NOW() - INTERVAL '24 hours'
    LOOP
        v_appraisal_lvl := floor(sqrt(v_listing.appraisal_xp / 100)) + 1;
        v_risk := 0.05 - (LEAST(v_appraisal_lvl, 99) / 100 * 0.045); -- Risk from 5% to 0.5%
        v_risk := GREATEST(0.005, v_risk);

        v_roll := random();
        IF v_roll < v_risk THEN
            -- CONFISCATED
            UPDATE public.market_listings SET status = 'confiscated' WHERE id = v_listing.id;
            DELETE FROM public.vault_items WHERE id = v_listing.vault_item_id;
            
            INSERT INTO public.notifications (user_id, message, type)
            VALUES (v_listing.seller_id, 'BLACK MARKET ALERT: Your listing Lot #' || v_listing.id || ' was confiscated by the Archive!', 'error');
            
            v_confiscated_count := v_confiscated_count + 1;
        ELSE
            UPDATE public.market_listings SET last_confiscation_check = NOW() WHERE id = v_listing.id;
        END IF;
    END LOOP;

    RETURN jsonb_build_object('success', true, 'confiscated', v_confiscated_count);
END;
$$;

-- 4. Update rpc_settle_listing for 0% Tax
CREATE OR REPLACE FUNCTION public.rpc_settle_listing(p_listing_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_listing RECORD;
    v_seller_payout BIGINT;
    v_tax BIGINT;
    v_item_name TEXT;
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

    -- Mark as ended immediately
    UPDATE public.market_listings SET status = 'ended' WHERE id = p_listing_id;

    IF v_listing.highest_bidder_id IS NOT NULL THEN
        -- Sold!
        UPDATE public.vault_items SET user_id = v_listing.highest_bidder_id WHERE id = v_listing.vault_item_id;
        
        -- Tax Rule
        IF v_listing.is_counter THEN
            v_tax := 0;
        ELSE
            v_tax := floor(v_listing.highest_bid * 0.05);
        END IF;
        
        v_seller_payout := (v_listing.highest_bid - v_tax) + v_listing.deposit_amount;
        
        UPDATE public.profiles SET scrap_balance = scrap_balance + v_seller_payout WHERE id = v_listing.seller_id;
        
        INSERT INTO public.notifications (user_id, message, type)
        VALUES (v_listing.seller_id, 'Auction Resolved: Lot #' || v_listing.id || ' sold. Payout: ' || v_seller_payout || ' scrap.', 'success');
        
        RETURN jsonb_build_object('success', true, 'outcome', 'sold', 'payout', v_seller_payout);
    ELSE
        -- No bids
        UPDATE public.profiles SET scrap_balance = scrap_balance + v_listing.deposit_amount WHERE id = v_listing.seller_id;
        RETURN jsonb_build_object('success', true, 'outcome', 'expired');
    END IF;
END;
$$;

-- 5. Heatmap Trending Rotation
CREATE OR REPLACE FUNCTION public.rpc_refresh_heatmaps()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_zone TEXT;
    v_tier TEXT;
    v_roll FLOAT;
    v_trending TEXT[];
BEGIN
    FOR v_zone IN SELECT zone_id FROM public.vault_heatmaps LOOP
        v_roll := random();
        IF v_roll < 0.15 THEN v_tier := 'HIGH';
        ELSIF v_roll < 0.50 THEN v_tier := 'MED';
        ELSE v_tier := 'LOW';
        END IF;

        -- Random Trending Items (Mocks for demo)
        SELECT array_agg(id) INTO v_trending FROM (
            SELECT id FROM public.item_definitions ORDER BY random() LIMIT 3
        ) sub;

        UPDATE public.vault_heatmaps 
        SET 
            static_tier = v_tier,
            trending_items = v_trending,
            updated_at = NOW()
        WHERE zone_id = v_zone;

        -- Global Event: Static Shift
        INSERT INTO public.global_events (event_type, details)
        VALUES ('static_shift', jsonb_build_object('zone_id', v_zone, 'tier', v_tier));
    END LOOP;

    RETURN jsonb_build_object('success', true);
END;
$$;

-- 6. Updated rpc_get_lab_state (Hydrated)
CREATE OR REPLACE FUNCTION public.rpc_get_lab_state(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_lab RECORD;
    v_crate JSONB;
BEGIN
    IF p_user_id IS NULL THEN
         RETURN jsonb_build_object('success', true, 'lab_state', null);
    END IF;

    SELECT * INTO v_lab FROM public.lab_state WHERE user_id = p_user_id;
    
    IF v_lab IS NULL THEN
        RETURN jsonb_build_object('success', true, 'lab_state', null);
    END IF;

    -- Hydrate active crate info
    IF v_lab.active_crate IS NOT NULL THEN
        SELECT jsonb_build_object(
            'id', id,
            'item_id', item_id,
            'source_zone_id', source_zone_id,
            'source_static_tier', source_static_tier
        ) INTO v_crate
        FROM public.vault_items
        WHERE id = v_lab.active_crate;
    END IF;

    RETURN jsonb_build_object('success', true, 'lab_state', jsonb_build_object(
        'is_active', v_lab.is_active,
        'current_stage', v_lab.current_stage,
        'active_crate', v_lab.active_crate,
        'crate_info', v_crate
    ));
END;
$$;

-- 6. RPC: Get Active Listings (with Master Trader logic)
CREATE OR REPLACE FUNCTION public.rpc_get_active_listings()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_profile RECORD;
BEGIN
    SELECT * INTO v_profile FROM public.profiles WHERE id = v_user_id;

    RETURN (
        SELECT coalesce(jsonb_agg(jsonb_build_object(
            'id', m.id,
            'seller_id', m.seller_id,
            'vault_item_id', m.vault_item_id,
            'item_id', v.item_id,
            'mint_number', v.mint_number,
            'reserve_price', m.reserve_price,
            'highest_bid', m.highest_bid,
            'ends_at', m.ends_at,
            'is_counter', m.is_counter,
            'is_under_the_table', m.is_under_the_table
        )), '[]'::jsonb)
        FROM public.market_listings m
        JOIN public.vault_items v ON m.vault_item_id = v.id
        WHERE m.status = 'active'
        AND (
            NOT m.is_under_the_table 
            OR (v_profile IS NOT NULL AND v_profile.appraisal_xp >= 100000)
        )
    );
END;
$$;
