-- 20240116000003_fix_settlement_level.sql
-- Fix rpc_settle_listing to use public.get_level for consistency

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
        
        -- Use standard level calculation
        v_appraisal_level := public.get_level(COALESCE(v_seller_profile.appraisal_xp, 0));
        
        -- Mastery Perk: "Market Maker" (Lvl 99) -> 2.5% tax (Half tax)
        IF v_appraisal_level >= 99 THEN
            v_tax_rate := 0.025;
        END IF;

        -- Award Appraisal XP to Seller (e.g. 10% of sale value)
        UPDATE public.profiles 
        SET appraisal_xp = COALESCE(appraisal_xp, 0) + floor(v_listing.highest_bid * 0.1)::BIGINT 
        WHERE id = v_listing.seller_id;

        -- Transfer Item
        UPDATE public.vault_items SET user_id = v_listing.highest_bidder_id WHERE id = v_listing.vault_item_id;
        
        -- Calculate Payout
        v_tax := floor(v_listing.highest_bid * v_tax_rate);
        v_seller_payout := (v_listing.highest_bid - v_tax) + v_listing.deposit_amount;
        
        -- Pay Seller
        UPDATE public.profiles SET scrap_balance = COALESCE(scrap_balance, 0) + v_seller_payout WHERE id = v_listing.seller_id;
        
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
        UPDATE public.profiles SET scrap_balance = COALESCE(scrap_balance, 0) + v_listing.deposit_amount WHERE id = v_listing.seller_id;
        
        INSERT INTO public.notifications (user_id, message, type)
        VALUES (v_listing.seller_id, 'Your auction for ' || v_listing.item_name || ' expired with no bids.', 'info');
        
        RETURN jsonb_build_object('success', true, 'outcome', 'expired');
    END IF;
END;
$$;
