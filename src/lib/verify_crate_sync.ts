import { createClient } from '@supabase/supabase-js';
import * as dotenv from 'dotenv';
import * as fs from 'fs';

async function verify() {
    const env = dotenv.parse(fs.readFileSync('.env'));
    const supabase = createClient(env.VITE_SUPABASE_URL, env.VITE_SUPABASE_ANON_KEY);

    const testUserId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479'; // Common test ID

    console.log('--- CRATE SYNC VERIFICATION ---');

    // 1. Clear tray first
    console.log('Clearing tray for testing...');
    await supabase.from('profiles').update({ tray_count: 0, crate_tray: [] }).eq('id', testUserId);

    // 2. Loop extraction until crate found
    console.log('Extracting until crate found (max 20 attempts)...');
    let crateFound = false;
    for (let i = 0; i < 20; i++) {
        const { data, error } = await supabase.rpc('rpc_extract_v6', {
            payload: {
                p_user_id: testUserId,
                p_seismic_grade: 'PERFECT,PERFECT' // Force double loot chance or high quality
            }
        });

        if (error) {
            console.error('RPC Error:', error);
            break;
        }

        console.log(`Attempt ${i + 1}: Result: ${data.result}, Crate Dropped: ${data.crate_dropped}`);

        if (data.crate_dropped) {
            crateFound = true;
            console.log('SUCCESS: Crate dropped!');
            console.log('Initial Response Tray Count:', data.new_tray_count);
            console.log('Initial Response Crate Tray:', JSON.stringify(data.crate_tray, null, 2));

            // 3. Verify in database
            const { data: profile } = await supabase.from('profiles').select('tray_count, crate_tray').eq('id', testUserId).single();
            console.log('Database Verification:');
            console.log('Tray Count:', profile?.tray_count);
            console.log('Crate Tray Length:', profile?.crate_tray?.length);
            console.log('Crate Tray Data:', JSON.stringify(profile?.crate_tray, null, 2));

            if (profile?.crate_tray && profile.crate_tray.length > 0) {
                console.log('\n--- VERIFICATION PASSED ---');
            } else {
                console.error('\n--- VERIFICATION FAILED: Tray empty in database ---');
            }
            break;
        }
    }

    if (!crateFound) {
        console.error('Failed to find a crate in 20 attempts.');
    }
}

verify();
