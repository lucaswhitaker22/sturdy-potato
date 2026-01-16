
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://qzspfutrvcfxpwgqohgn.supabase.co';
const SUPABASE_KEY = 'sb_publishable_8YqJf5Fz94z2w3RKEoEYLw_H0Rm-1Bc';

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function runVerification() {
    console.log('Starting Shatter Salvage Verification...');

    const userId = '00000000-0000-4000-a000-' + Math.floor(Math.random() * 1000000000000).toString(16).padStart(12, '0');
    console.log(`Test User ID: ${userId}`);

    console.log('1. Initializing Profile...');
    await supabase.rpc('rpc_get_profile', { p_user_id: userId });

    await supabase.from('profiles').update({
        tray_count: 5,
        fine_dust_balance: 1000
    }).eq('id', userId);

    console.log('SUCCESS: Profile initialized.');

    console.log('\n2. Testing Shatter Salvage Trigger...');
    let salvageData = null;
    let attempts = 0;

    const testCrate = { id: crypto.randomUUID(), appraised: false, contents: {} };

    while (attempts < 100) {
        attempts++;
        console.log(`\nAttempt ${attempts}: Activating lab...`);
        const { error: upsertErr } = await supabase.from('lab_state').upsert({
            user_id: userId,
            is_active: true,
            current_stage: 0,
            last_action_at: new Date().toISOString(),
            active_crate: testCrate
        });

        if (upsertErr) {
            console.error('Lab Upsert Error:', upsertErr);
            break;
        }

        let stage = 0;
        let active = true;
        while (active && stage < 5) {
            console.log(`- Stage ${stage}: Sifting...`);
            const { data, error } = await supabase.rpc('rpc_sift_v2', {
                p_user_id: userId,
                p_tethers_used: 0,
                p_zone: 0
            });

            if (error) {
                console.error(`  ERROR:`, error);
                active = false;
                break;
            }
            if (data.outcome === 'SUCCESS') {
                console.log(`  SUCCESS -> Stage ${data.new_stage}`);
                stage = data.new_stage;
            } else if (data.outcome === 'STABILIZED_FAIL') {
                active = false;
                if (data.salvage_token) {
                    salvageData = data;
                    console.log(`  FAIL (Stabilized) -> Token: ${data.salvage_token}`);
                    break;
                } else {
                    console.log(`  FAIL (Stabilized) -> No Token`);
                    break;
                }
            } else if (data.outcome === 'SHATTERED') {
                active = false;
                console.log(`  CRITICAL FAIL (Shattered)`);
                break;
            }
        }
        if (salvageData) break;
    }

    if (!salvageData) {
        console.error('ERROR: Could not trigger salvage window after 100 attempts.');
        return;
    }

    console.log('\n3. Testing rpc_shatter_salvage (Valid)...');
    const { data: scavengeResult, error: scavengeError } = await supabase.rpc('rpc_shatter_salvage', {
        p_user_id: userId,
        p_token: salvageData.salvage_token
    });

    if (scavengeError) {
        console.error('ERROR: Salvage RPC failed', scavengeError);
    } else if (scavengeResult.success) {
        console.log('Salvage Result:', scavengeResult);
        console.log('SUCCESS: Salvage worked!');
    } else {
        console.error('ERROR: Salvage success false', scavengeResult);
    }

    console.log('\nVerification Complete.');
}

runVerification();
