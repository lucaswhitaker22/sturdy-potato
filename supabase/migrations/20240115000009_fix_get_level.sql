-- Fix get_level to handle NULLs and ensure stability
CREATE OR REPLACE FUNCTION public.get_level(xp BIGINT)
RETURNS INT LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
    level INT := 1;
    threshold BIGINT := 0;
    v_xp BIGINT := COALESCE(xp, 0);
BEGIN
    FOR i IN 1..98 LOOP
        threshold := threshold + floor(i + 300 * power(2, i::float/7));
        IF v_xp < threshold THEN
            RETURN i;
        END IF;
    END LOOP;
    RETURN 99;
END;
$$;
