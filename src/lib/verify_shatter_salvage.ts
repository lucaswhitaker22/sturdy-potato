import { createClient } from '@supabase/supabase-js';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';
import { readFileSync } from 'fs';

// Load env manually
const __dirname = dirname(fileURLToPath(import.meta.url));
const envPath = resolve(__dirname, '../../.env');
const envContent = readFileSync(envPath, 'utf-8');
const env: Record<string, string> = {};
envContent.split('\n').forEach(line => {
    const parts = line.split('=');
    if (parts.length >= 2) {
        const key = parts[0].trim();
        const value = parts.slice(1).join('=').trim().replace(/^['"]|['"]$/g, '');
        env[key] = value;
    }
});

const supabaseUrl = env.VITE_SUPABASE_URL || '';
const supabaseKey = env.VITE_SUPABASE_ANON_KEY || '';
const supabase = createClient(supabaseUrl, supabaseKey);

async function verify() {
    console.log('--- Shatter Salvage Verification ---');

    // 1. Get a test user
    const { data: users } = await supabase.from('profiles').select('id').limit(1);
    if (!users || users.length === 0) {
        console.error('No users found.');
        return;
    }
    const userId = users[0].id;
    console.log(`User: ${userId}`);

    // 2. Ensure user has a crate in lab or at least a tray count
    const { data: profile } = await supabase.from('profiles').select('*').eq('id', userId).single();
    if (profile.tray_count === 0) {
        console.log('Adding tray count for test...');
        await supabase.from('profiles').update({ tray_count: 5 }).eq('id', userId);
    }

    // Attempt to start sifting if not active
    const { data: labState } = await supabase.rpc('rpc_get_lab_state', { p_user_id: userId });
    if (!labState?.lab_state?.is_active) {
        console.warn('Lab not active. Attempting to force a crate find...');
        await supabase.rpc('rpc_extract_v6', { payload: { p_user_id: userId } });
        // Start sifting if we have a tray
        const { data: profile2 } = await supabase.from('profiles').select('crate_tray').eq('id', userId).single();
        if (profile2 && profile2.crate_tray && profile2.crate_tray.length > 0) {
            await supabase.rpc('rpc_start_sifting', { payload: { p_user_id: userId, p_crate_id: profile2.crate_tray[0].id } });
        } else {
            console.error('Could not setup lab state for test.');
            return;
        }
    }

    // 3. Test Sift -> Stabilized Fail (Salvage Trigger)
    let outcome = '';
    let siftData: any = null;
    let attempts = 0;
    while (outcome !== 'STABILIZED_FAIL' && attempts < 10) {
        attempts++;
        console.log(`Triggering Sift (Attempt ${attempts})...`);
        const { data, error } = await supabase.rpc('rpc_sift_v2', {
            p_user_id: userId,
            p_tethers_used: 0,
            p_zone: 0 // Safe Zone for more stable rolls, higher chance of STABILIZED_FAIL vs SHATTERED
        });

        if (error) {
            console.error('Sift Error:', error);
            return;
        }
        siftData = data;
        outcome = data.outcome;
        console.log('Outcome:', outcome);

        if (outcome === 'SUCCESS') {
            // Need to reload lab state or just loop if v2 allows it? 
            // v2 checks if active. Success keeps it active (next stage).
            continue;
        }

        if (outcome === 'SHATTERED') {
            console.log('Shattered! Need to find another crate...');
            await supabase.rpc('rpc_extract_v6', { payload: { p_user_id: userId } });
            const { data: profile_retry } = await supabase.from('profiles').select('crate_tray').eq('id', userId).single();
            if (profile_retry && profile_retry.crate_tray && profile_retry.crate_tray.length > 0) {
                await supabase.rpc('rpc_start_sifting', { payload: { p_user_id: userId, p_crate_id: profile_retry.crate_tray[0].id } });
            } else {
                console.error('Could not find another crate.');
                return;
            }
        }
    }

    if (outcome === 'STABILIZED_FAIL' && siftData.salvage_token) {
        console.log('Salvage Token Received:', siftData.salvage_token);
        console.log('Expires at:', siftData.salvage_expires_at);

        // 4. Test In-Time Salvage
        console.log('Testing in-time salvage...');
        const { data: salvageData, error: salvageErr } = await supabase.rpc('rpc_shatter_salvage', {
            p_user_id: userId,
            p_token: siftData.salvage_token
        });

        if (salvageErr) {
            console.error('Salvage Error:', salvageErr);
        } else {
            console.log('Salvage Result:', salvageData.outcome);
            if (salvageData.outcome === 'SALVAGED') {
                console.log('Success! Payout:', { dust: salvageData.dust_gain, fragments: salvageData.fragment_gain });
            }
        }
    } else {
        console.warn('Did not get a salvage token. Outcome might have been SUCCESS or SHATTERED.');
        console.log('Recommendation: Re-run test if outcome was SUCCESS/SHATTERED to hit the fail branch.');
    }

    console.log('--- Verification Done ---');
}

verify();
