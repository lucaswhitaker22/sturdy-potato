-- 20240116000000_loot_schema_complete.sql

-- 1. Create Enums
DO $$ BEGIN
    CREATE TYPE item_tier AS ENUM ('junk', 'common', 'uncommon', 'rare', 'epic', 'mythic', 'unique');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE item_condition AS ENUM ('wrecked', 'weathered', 'preserved', 'mint');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. Item Definitions (Source of Truth)
CREATE TABLE IF NOT EXISTS public.item_definitions (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    tier item_tier NOT NULL,
    base_hv INTEGER NOT NULL DEFAULT 10,
    flavor_text TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.item_definitions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read item defs" ON public.item_definitions;
CREATE POLICY "Public read item defs" ON public.item_definitions FOR SELECT USING (true);

-- 3. Collection Definitions
CREATE TABLE IF NOT EXISTS public.collection_definitions (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    required_item_ids TEXT[] NOT NULL,
    bonus_type TEXT, -- e.g., 'passive_scrap', 'cooldown'
    bonus_value NUMERIC,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.collection_definitions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read collections" ON public.collection_definitions;
CREATE POLICY "Public read collections" ON public.collection_definitions FOR SELECT USING (true);


-- 4. Update Vault Items
ALTER TABLE public.vault_items 
ADD COLUMN IF NOT EXISTS condition item_condition DEFAULT 'weathered',
ADD COLUMN IF NOT EXISTS is_prismatic BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS historical_value INTEGER DEFAULT 0;

-- 5. Seed Data (Comprehensive Catalog)
INSERT INTO public.item_definitions (id, name, tier, base_hv, flavor_text) VALUES
-- JUNK (1-5 HV)
('broken_glass', 'Broken Glass', 'junk', 2, 'Sharp, transparent sand-rock.'),
('rusted_wire', 'Rusted Wire', 'junk', 3, 'Orange snake-metal, prone to snapping.'),
('plastic_scrap', 'Plastic Scrap', 'junk', 1, 'Eternal material, shaped like nothing.'),
('bottle_cap', 'Bottle Cap', 'junk', 4, 'Currency of a false timeline.'),

-- COMMON (20 HV)
('ceramic_mug', 'Ceramic Mug', 'common', 20, 'A vessel for brown caffeinated rituals.'),
('rusty_toaster', 'Rusty Toaster', 'common', 20, 'A spring-loaded bread warmer.'),
('spoon', 'Spoon', 'common', 20, 'A shallow scoop for liquid consumption.'),
('aa_battery', 'AA Battery', 'common', 20, 'A dead ancient power cell.'),
('plastic_comb', 'Plastic Comb', 'common', 20, 'A scalp-scraping tool of the old elite.'),
('steel_fork', 'Steel Fork', 'common', 20, 'A three-pronged food-spear.'),
('lightbulb', 'Lightbulb', 'common', 20, 'A fragile glass orb that once held lightning.'),
('ballpoint_pen', 'Ballpoint Pen', 'common', 20, 'A manual data-entry stylus (no ink).'),
('rusty_key', 'Rusty Key', 'common', 20, 'Unlocks a door that no longer exists.'),
('eyeglass_frame', 'Eyeglass Frame', 'common', 20, 'A visual-enhancement harness.'),
('soda_tab', 'Soda Tab', 'common', 20, 'Small aluminum currency? Purpose unknown.'),
('safety_pin', 'Safety Pin', 'common', 20, 'A primitive emergency garment fastener.'),
('rubber_band', 'Rubber Band', 'common', 20, 'High-elasticity synthetic binding.'),
('dull_kitchen_knife', 'Dull Kitchen Knife', 'common', 20, 'A primitive steak-searing blade.'),

-- UNCOMMON (75 HV)
('soda_can', 'Soda Can', 'uncommon', 75, 'Aluminum cylinder for pressurized sugar.'),
('basic_tools', 'Basic Tools', 'uncommon', 75, 'Levers and twists for primitive construction.'),
('manual_can_opener', 'Manual Can Opener', 'uncommon', 75, 'Key to the eternal metal food cylinders.'),
('silicone_spatula', 'Silicone Spatula', 'uncommon', 75, 'Flexible food-pusher.'),
('wired_mouse', 'Wired Mouse', 'uncommon', 75, 'Tethered navigation rodent.'),

-- RARE (250 HV)
('calculated_tablet', 'Calculated Tablet', 'rare', 250, 'A solar-powered math-engine (Casio).'),
('wrist_chronometer', 'Wrist Chronometer', 'rare', 250, 'Tracks time via ticking gears.'),
('compact_disc', 'Compact Disc', 'rare', 250, 'A shimmering circle of lost music.'),
('remote_control', 'Remote Control', 'rare', 250, 'A long-range button-array for glowing boxes.'),
('computer_mouse', 'Computer Mouse', 'rare', 250, 'A handheld navigation rodent.'),
('flashlight', 'Flashlight', 'rare', 250, 'A portable photon-emitter.'),
('headphone_set', 'Headphone Set', 'rare', 250, 'Private ear-drums for personal audio.'),
('digital_camera', 'Digital Camera', 'rare', 250, 'A device that freezes light into memories.'),
('mobile_phone_brick', 'Mobile Phone (Brick)', 'rare', 250, 'Indestructible communication monolith.'),

-- EPIC (1000 HV)
('game_console', 'Game Console', 'epic', 1000, 'Entertainment alter for the digital gods.'),
('designer_bag', 'Designer Bag', 'epic', 1000, 'Leather sack for social signaling.'),
('mechanical_keyboard', 'Mechanical Keyboard', 'epic', 1000, 'Click-clack text input engine.'),
('crt_monitor', 'CRT Monitor', 'epic', 1000, 'Heavy glass window into the cyber-void.'),

-- MYTHIC (5000 HV)
('prototype_smartphone', 'Prototype Smartphone', 'mythic', 5000, 'The first black mirror.'),
('diamond_tennis_bracelet', 'Diamond Tennis Bracelet', 'mythic', 5000, 'Wrist-sparkle, purely decorative.'),
('gold_plated_lighter', 'Gold Plated Lighter', 'mythic', 5000, 'Fire-maker for the wealthy.'),
('silk_necktie', 'Silk Necktie', 'mythic', 5000, 'Formal strangulation cord.')

ON CONFLICT (id) DO UPDATE SET 
    name = EXCLUDED.name,
    tier = EXCLUDED.tier,
    base_hv = EXCLUDED.base_hv,
    flavor_text = EXCLUDED.flavor_text;


-- Seed Collections
INSERT INTO public.collection_definitions (id, name, description, required_item_ids, bonus_type, bonus_value) VALUES
('morning_ritual', 'The Morning Ritual', 'Caffeine Rush: Reduces EXTRACT cooldown.', ARRAY['ceramic_mug', 'rusty_toaster', 'spoon'], 'cooldown_reduction', 0.5),
('the_20th_century_kitchen', 'The 20th Century Kitchen', '10% more scrap from digging.', ARRAY['rusty_toaster', 'ceramic_mug', 'silicone_spatula', 'manual_can_opener'], 'scrap_gain_mult', 0.10),
('digital_dark_age', 'The Digital Dark Age', '5% more sift stability.', ARRAY['crt_monitor', 'mechanical_keyboard', 'compact_disc', 'wired_mouse'], 'stability_bonus', 0.05),
('high_delivery_gala', 'The High Delivery Gala', '15% lower auction fees.', ARRAY['diamond_tennis_bracelet', 'silk_necktie', 'gold_plated_lighter', 'designer_bag'], 'auction_fee_discount', 0.15)
ON CONFLICT (id) DO UPDATE SET
    required_item_ids = EXCLUDED.required_item_ids,
    description = EXCLUDED.description,
    bonus_type = EXCLUDED.bonus_type,
    bonus_value = EXCLUDED.bonus_value;


-- 6. Helper: Check Collection Completion
CREATE OR REPLACE FUNCTION public.check_collection_completion(p_user_id UUID, p_item_id TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_set_record RECORD;
    v_missing_count INT;
BEGIN
    -- Find all sets that contain this item
    FOR v_set_record IN 
        SELECT * FROM public.collection_definitions 
        WHERE p_item_id = ANY(required_item_ids)
    LOOP
        -- Check if user has already completed this set
        IF EXISTS (SELECT 1 FROM public.completed_sets WHERE user_id = p_user_id AND set_id = v_set_record.id) THEN
            CONTINUE;
        END IF;

        -- Check if user collects all items in this set
        -- We check if there are any required items NOT in the user's vault
        SELECT COUNT(*) INTO v_missing_count
        FROM unnest(v_set_record.required_item_ids) AS req_item
        WHERE req_item NOT IN (
            SELECT item_id FROM public.vault_items WHERE user_id = p_user_id
        );

        IF v_missing_count = 0 THEN
            -- Complete the set!
            INSERT INTO public.completed_sets (user_id, set_id) VALUES (p_user_id, v_set_record.id);
            -- Note: We could notify user here via a logs table if we had one
        END IF;
    END LOOP;
END;
$$;


-- 7. Rewrite rpc_claim with Full Logic
CREATE OR REPLACE FUNCTION public.rpc_claim(p_user_id UUID DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := public.get_auth_user(p_user_id);
    v_lab RECORD;
    v_item_def RECORD;
    v_tier item_tier;
    v_condition item_condition;
    v_condition_mult FLOAT;
    v_is_prismatic BOOLEAN := FALSE;
    v_prismatic_mult FLOAT := 1.0;
    v_mint_mult FLOAT := 1.0;
    v_final_hv INT;
    v_mint_num BIGINT;
    v_roll FLOAT;
    v_new_item_id UUID;
BEGIN
    IF v_user_id IS NULL THEN RETURN jsonb_build_object('success', false, 'error', 'Unauthenticated'); END IF;

    SELECT * INTO v_lab FROM public.lab_state WHERE user_id = v_user_id;
    
    IF v_lab IS NULL OR NOT v_lab.is_active THEN
        RETURN jsonb_build_object('success', false, 'error', 'No active crate to claim');
    END IF;

    -- 1. Determine Tier based on Stage
    CASE 
        WHEN v_lab.current_stage >= 5 THEN v_tier := 'mythic'; -- Or Epic/Unique
        WHEN v_lab.current_stage = 4 THEN v_tier := 'epic';
        WHEN v_lab.current_stage = 3 THEN v_tier := 'rare';
        WHEN v_lab.current_stage = 2 THEN v_tier := 'uncommon';
        ELSE v_tier := 'common';
    END CASE;
    
    -- Fallback for better game feel: Chance to upgrade tier? For now stick to strict mapping.

    -- 2. Pick Random Item of Tier
    SELECT * INTO v_item_def 
    FROM public.item_definitions 
    WHERE tier = v_tier 
    ORDER BY random() 
    LIMIT 1;

    IF v_item_def IS NULL THEN
        -- Fallback if DB is empty for that tier
        SELECT * INTO v_item_def FROM public.item_definitions WHERE tier = 'common' LIMIT 1;
    END IF;

    -- 3. Prismatic Roll (1%)
    IF random() < 0.01 THEN
        v_is_prismatic := TRUE;
        v_prismatic_mult := 3.0;
    END IF;

    -- 4. Condition Roll
    v_roll := random();
    IF v_roll < 0.05 THEN
        v_condition := 'mint';
        v_condition_mult := 2.5;
    ELSIF v_roll < 0.20 THEN
        v_condition := 'preserved';
        v_condition_mult := 1.5;
    ELSIF v_roll < 0.70 THEN
        v_condition := 'weathered';
        v_condition_mult := 1.0;
    ELSE
        v_condition := 'wrecked';
        v_condition_mult := 0.5;
    END IF;

    -- 5. Mint Number
    INSERT INTO public.item_mints (item_id, next_mint_number)
    VALUES (v_item_def.id, 2)
    ON CONFLICT (item_id) DO UPDATE SET next_mint_number = item_mints.next_mint_number + 1
    RETURNING next_mint_number - 1 INTO v_mint_num;

    -- Low Mint Bonus (First 10)
    IF v_mint_num <= 10 THEN
        v_mint_mult := 1.5;
    END IF;

    -- 6. Calculate HV
    v_final_hv := floor(v_item_def.base_hv * v_condition_mult * v_prismatic_mult * v_mint_mult)::INT;

    -- 7. Insert Vault Item
    INSERT INTO public.vault_items (
        user_id, item_id, mint_number, condition, is_prismatic, historical_value, discovered_at
    ) 
    VALUES (
        v_user_id, v_item_def.id, v_mint_num, v_condition, v_is_prismatic, v_final_hv, NOW()
    )
    RETURNING id INTO v_new_item_id;

    -- 8. Cleanup Lab
    UPDATE public.lab_state SET is_active = FALSE, current_stage = 0, last_action_at = NOW() WHERE user_id = v_user_id;
    UPDATE public.profiles SET tray_count = GREATEST(0, COALESCE(tray_count, 0) - 1) WHERE id = v_user_id;

    -- 9. Auto-Check Collections
    PERFORM public.check_collection_completion(v_user_id, v_item_def.id);

    -- 10. Global Event for Good Stuff
    IF v_is_prismatic OR v_tier IN ('epic', 'mythic', 'unique') THEN
        INSERT INTO public.global_events (event_type, user_id, details)
        VALUES ('find', v_user_id, jsonb_build_object(
            'item_id', v_item_def.id, 
            'mint_number', v_mint_num, 
            'is_prismatic', v_is_prismatic,
            'hv', v_final_hv
        ));
    END IF;

    RETURN jsonb_build_object(
        'success', true, 
        'item', jsonb_build_object(
            'id', v_item_def.id,
            'name', v_item_def.name,
            'tier', v_item_def.tier,
            'mint_number', v_mint_num,
            'condition', v_condition,
            'is_prismatic', v_is_prismatic,
            'historical_value', v_final_hv,
            'flavor_text', v_item_def.flavor_text
        )
    );
END;
$$;
