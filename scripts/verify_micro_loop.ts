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
    console.log('=== Micro-Loop Verification v3/v7 ===');
    const { data: users } = await supabase.from('profiles').select('id, excavation_xp, restoration_xp').limit(1);
    if (!users || users.length === 0) { console.error('No users.'); return; }
    const userId = users[0].id;
    console.log(`User: ${userId}`);

    // --- TEST 1: Extract v7 (Seismic) ---
    console.log('\n--- Testing Extract v7 (Seismic Perfect) ---');
    const preXp = users[0].excavation_xp;
    
    // Force cooldown reset
    await supabase.from('profiles').update({ last_extract_at: null }).eq('id', userId);

    const { data: extractData, error: extractError } = await supabase.rpc('rpc_extract_v7', {
        payload: {
            p_user_id: userId,
            p_seismic_grade: 'PERFECT'
        }
    });

    if (extractError) {
        console.error('Extract Error:', extractError);
    } else {
        console.log('Extract Result:', extractData.result);
        console.log('XP Gain:', extractData.new_xp - preXp);
        // Expected: Base 25 + Perfect 15 = 40
        if ((extractData.new_xp - preXp) === 40) console.log('PASS: Correct XP Bonus for Perfect.');
        else console.warn('FAIL: Unexpected XP gain.');
    }

    // --- TEST 2: Sift v3 (Salvage Generation) ---
    console.log('\n--- Testing Sift v3 (Salvage Token) ---');
    
    // Setup Lab
    // Need a valid crate ID in vault_items that is active
    // create fake crate
    const { data: crate } = await supabase.from('vault_items').insert({
        user_id: userId,
        item_id: 'ancient_pot_shard', // assuming exists
        tier: 1,
        source_static_tier: 'LOW'
    }).select('id').single();
    
    // Add to tray just in case
    await supabase.from('profiles').update({ 
        crate_tray: [crate.id],
        tray_count: 1
    }).eq('id', userId);

    await supabase.from('lab_state').upsert({
        user_id: userId,
        is_active: true,
        current_stage: 4, // High stage to fail more likely? Or just rely on luck.
        active_crate: crate.id
    });

    let token = null;
    for(let i=0; i<10; i++) {
         const { data: siftData } = await supabase.rpc('rpc_sift_v3', {
             p_user_id: userId, p_tethers_used: 0, p_zone: 0
         });
         
         if (siftData?.success) {
             if (siftData.outcome === 'SUCCESS') {
                 console.log('Sift Success - Retrying for fail...');
                 continue;
             } else {
                 console.log('Sift Shattered/Failed.');
                 if (siftData.salvage_token) {
                     console.log('PASS: Salvage Token Generated:', siftData.salvage_token);
                     token = siftData.salvage_token;
                     break;
                 } else {
                     console.warn('FAIL: No salvage token on failure.');
                 }
             }
         }
    }

    if (token) {
        console.log('Attempting salvage...');
        const { data: salvage } = await supabase.rpc('rpc_shatter_salvage', {
            p_user_id: userId, p_token: token
        });
        console.log('Salvage Result:', salvage?.outcome || 'Error');
    }
}

verify();
