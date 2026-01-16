
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://qzspfutrvcfxpwgqohgn.supabase.co';
const SUPABASE_KEY = 'sb_publishable_8YqJf5Fz94z2w3RKEoEYLw_H0Rm-1Bc'; // Anon key is fine for these RPCs if policies allow

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function verify() {
    console.log('Starting Verification...');

    // 1. Verify rpc_helper_get_zone_trends
    console.log('Testing rpc_helper_get_zone_trends...');
    const { data: trends, error: trendError } = await supabase.rpc('rpc_helper_get_zone_trends', { p_zone_id: 'industrial_zone' });

    if (trendError) {
        console.error('FAILED: rpc_helper_get_zone_trends', trendError);
    } else {
        console.log('SUCCESS: rpc_helper_get_zone_trends returned:', trends);
        if (!Array.isArray(trends) || trends.length === 0) {
            console.warn('WARNING: trends is not a non-empty array');
        }
    }

    // 2. Verify rpc_sift_v2 (Syntax check and basic execution)
    // We won't simulate a full game loop, just check if it's callable without schema error.
    console.log('Testing rpc_sift_v2 signature...');
    // We pass null user_id which returns 'Unauthenticated' error, but proves function exists
    const { data: siftData, error: siftError } = await supabase.rpc('rpc_sift_v2', {
        p_user_id: null,
        p_tethers_used: 0,
        p_zone: 0
    });

    if (siftError) {
        console.error('FAILED: rpc_sift_v2 call error', siftError);
    } else {
        console.log('SUCCESS: rpc_sift_v2 responded:', siftData);
    }

    console.log('Verification Complete.');
}

verify();
