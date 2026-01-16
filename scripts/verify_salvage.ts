
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
        fine_dust_balance: 100
    }).eq('id', userId);

    console.log('SUCCESS: Profile initialized.');

    console.log('\n2. Testing Shatter Salvage Trigger...');
    let salvageData = null;
    let attempts = 0;

    while (attempts < 50) {
        attempts++;
        await supabase.rpc('rpc_start_sifting', {
            payload: { p_user_id: userId, p_crate_id: 'test' }
        });

        let stage = 0;
        let active = true;
        while (active && stage < 5) {
            const { data, error } = await supabase.rpc('rpc_sift', {
                p_user_id: userId,
                p_tethers_used: 0,
                p_zone: 0
            });

            if (error) {
                console.error(`Attempt ${attempts} Sift Error:`, error);
                active = false;
                break;
            }
            if (data.outcome === 'SUCCESS') {
                console.log(`Attempt ${attempts}: Stage ${stage} -> SUCCESS -> New Stage: ${data.new_stage}`);
                stage = data.new_stage;
            } else if (data.outcome === 'STABILIZED_FAIL') {
                active = false;
                if (data.salvage_token) {
                    salvageData = data;
                    console.log(`Attempt ${attempts}: SUCCESS! STABILIZED_FAIL at stage ${stage} with token.`);
                    break;
                } else {
                    console.log(`Attempt ${attempts}: STABILIZED_FAIL at stage ${stage} (No Token)`);
                    break;
                }
            } else if (data.outcome === 'SHATTERED') {
                active = false;
                console.log(`Attempt ${attempts}: CRITICAL SHATTER at stage ${stage}`);
                break;
            }
        }
        if (salvageData) break;
    }

    if (!salvageData) {
        console.error('ERROR: Could not trigger salvage window after 50 attempts.');
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
    } else {
        console.error('ERROR: Salvage success false', scavengeResult);
    }

    console.log('\nVerification Complete.');
}

runVerification();
