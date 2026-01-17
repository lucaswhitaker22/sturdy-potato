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
    console.log('--- Shatter Salvage Verification (Fragment Alchemist) ---');

    // 1. Get a test user
    const { data: users } = await supabase.from('profiles').select('id').limit(1);
    if (!users || users.length === 0) {
        console.error('No users found.');
        return;
    }
    const userId = users[0].id;
    console.log(`User: ${userId}`);

    // 2. Setup Profile & Lab State
    console.log('Setting smelting_branch = fragment_alchemist and seeding crate...');
    await supabase.from('profiles').update({
        smelting_branch: 'fragment_alchemist',
        crate_tray: [{ id: 'test-crate-' + Date.now(), tier: 'rare', appraised: true, appraisal_success: true }]
    }).eq('id', userId);

    const { data: profile } = await supabase.from('profiles').select('crate_tray').eq('id', userId).single();

    console.log('Forcing Lab State (Stage 3)...');
    await supabase.from('lab_state').upsert({
        user_id: userId,
        is_active: true,
        current_stage: 3,
        active_crate: profile.crate_tray[0],
        last_action_at: new Date().toISOString()
    });

    const { data: verifyState } = await supabase.from('lab_state').select('*').eq('user_id', userId).single();
    console.log('Verified Lab State Stage:', verifyState?.current_stage);

    // 3. Loop Sift until STABILIZED_FAIL
    let outcome = '';
    let siftData: any = null;
    let attempts = 0;
    while (outcome !== 'STABILIZED_FAIL' && attempts < 20) {
        attempts++;
        console.log(`Triggering Sift (Attempt ${attempts})...`);
        const { data, error } = await supabase.rpc('rpc_sift_v2', {
            p_user_id: userId,
            p_tethers_used: 0,
            p_zone: 0
        });

        if (error || !data?.success) {
            console.warn('Sift Error:', error || data?.error);
            // Re-setup if needed
            await supabase.from('lab_state').upsert({
                user_id: userId,
                is_active: true,
                current_stage: 3,
                active_crate: profile.crate_tray[0],
                last_action_at: new Date().toISOString()
            });
            continue;
        }

        siftData = data;
        outcome = data.outcome;
        console.log('Sift Outcome:', outcome, 'Pending Dust:', data.pending_dust, 'Pending Fragment:', data.pending_fragment);

        if (outcome === 'SUCCESS') continue;
        if (outcome === 'SHATTERED') {
            // Reset to stage 3
            await supabase.from('lab_state').upsert({
                user_id: userId,
                is_active: true,
                current_stage: 3,
                active_crate: profile.crate_tray[0],
                last_action_at: new Date().toISOString()
            });
        }
    }

    if (outcome === 'STABILIZED_FAIL' && siftData.salvage_token) {
        console.log('Salvage Token Received:', siftData.salvage_token);
        console.log('Testing salvage...');
        const { data: salvageData } = await supabase.rpc('rpc_shatter_salvage', {
            p_user_id: userId,
            p_token: siftData.salvage_token
        });

        console.log('Salvage Result:', salvageData.outcome);
        console.log('Payout:', { dust: salvageData.dust_gain, fragments: salvageData.fragment_gain });

        if (salvageData.fragment_gain > 0) {
            console.log('SUCCESS: Cursed Fragment recovered!');
        } else {
            console.log('No fragment this time (random chance).');
        }
    }

    console.log('--- Verification Done ---');
}

verify();
