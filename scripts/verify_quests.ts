
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function verify() {
    // Load env from root
    const envPath = path.resolve(__dirname, '../.env');
    const envConfig = dotenv.parse(fs.readFileSync(envPath));
    const supabase = createClient(envConfig.VITE_SUPABASE_URL, envConfig.VITE_SUPABASE_ANON_KEY);

    const testUserId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
    console.log(`Test User ID: ${testUserId}`);

    console.log('\n--- 1. RESET ---');
    // Clear quests
    const { error: delErr } = await supabase.from('player_quests').delete().eq('user_id', testUserId);
    if (delErr) console.error('Reset Error:', delErr);
    else console.log('Reset complete.');

    console.log('\n--- 2. INITIALIZE (rpc_get_quests) ---');
    const { data: qData, error: qError } = await supabase.rpc('rpc_get_quests', { p_user_id: testUserId });
    
    if (qError) {
        console.error('RPC Error:', qError);
        return;
    }

    console.log('Quests returned:', qData.quests?.length);
    const quest01 = qData.quests?.find((q) => q.quest_id === 'archive_onboard_01');
    
    if (!quest01) {
        console.error('FAIL: archive_onboard_01 not found.');
        return;
    }
    console.log(`Quest 01 Status: ${quest01.status}`);
    console.log(`Quest 01 Progress:`, quest01.progress);

    // Accept if needed (logic usually auto-accepts or sets available)
    if (quest01.status === 'AVAILABLE') {
        console.log('Accepting quest...');
        await supabase.rpc('rpc_accept_quest', { p_quest_id: 'archive_onboard_01', p_user_id: testUserId });
    }

    console.log('\n--- 3. PROGRESS (rpc_extract_v7) ---');
    // Call extract multiple times to trigger progress
    for (let i = 0; i < 3; i++) {
        const { data: exData, error: exError } = await supabase.rpc('rpc_extract_v7', {
            payload: {
                p_user_id: testUserId,
                p_seismic_grade: 'HIT'
            }
        });
        if (exError) console.error(`Extract ${i+1} Fail:`, exError);
        else console.log(`Extract ${i+1}: Success`);
    }

    // Check Progress
    const { data: qData2 } = await supabase.rpc('rpc_get_quests', { p_user_id: testUserId });
    const quest01_updated = qData2.quests?.find((q) => q.quest_id === 'archive_onboard_01');
    console.log(`Quest 01 Progress After Extracts:`, quest01_updated.progress);

    // Force finish (simulated for speed, or loop 10 times)
    // Let's loop 7 more times
    console.log('Completing remaining extracts...');
    for (let i = 0; i < 7; i++) {
        await supabase.rpc('rpc_extract_v7', { payload: { p_user_id: testUserId, p_seismic_grade: 'HIT' } });
    }

    const { data: qData3 } = await supabase.rpc('rpc_get_quests', { p_user_id: testUserId });
    const quest01_final = qData3.quests?.find((q) => q.quest_id === 'archive_onboard_01');
    console.log(`Quest 01 Status After 10 Extracts: ${quest01_final.status}`);

    if (quest01_final.status === 'COMPLETED') {
        console.log('\n--- 4. CLAIM REWARD ---');
        const { data: claimData, error: claimError } = await supabase.rpc('rpc_claim_quest_reward', {
            p_quest_db_id: quest01_final.id,
            p_user_id: testUserId
        });

        if (claimError) console.error('Claim Fail:', claimError);
        else console.log('Claim Success:', claimData);

        // Verify Next Quest
        const { data: qData4 } = await supabase.rpc('rpc_get_quests', { p_user_id: testUserId });
        const quest02 = qData4.quests?.find((q) => q.quest_id === 'archive_onboard_02');
        if (quest02) {
            console.log('SUCCESS: Onboarding 02 assigned:', quest02.title);
        } else {
            console.error('FAIL: Onboarding 02 not found.');
        }
    } else {
        console.log('Quest not completed yet. Current progress:', quest01_final.progress);
    }
}

verify();
