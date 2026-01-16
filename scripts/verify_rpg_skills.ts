
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = process.env.VITE_SUPABASE_URL || 'http://127.0.0.1:54321';
const SUPABASE_KEY = process.env.VITE_SUPABASE_ANON_KEY || 'your-anon-key-here'; // User might need to provide this

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function runVerification() {
    console.log('Starting RPG Skills Verification...');
    
    const userId = crypto.randomUUID();
    console.log(`Test User ID: ${userId}`);

    // 1. Initial State
    console.log('1. Verifying Initial Profile...');
    // Trigger auto-create via rpc_extract
    const { data: extractData, error: extractError } = await supabase.rpc('rpc_extract', { p_user_id: userId });
    
    if (extractError) {
        console.error('ERROR: Failed to init profile via extrat', extractError);
        // If unauthenticated or bad URL, we stop
        return;
    }

    const { data: profile } = await supabase.from('profiles').select('*').eq('id', userId).single();
    if (!profile) {
        console.error('ERROR: Profile not found after extract.');
        return;
    }

    console.log('Profile created:', profile);
    if (profile.appraisal_xp !== 0 || profile.smelting_xp !== 0) {
        console.error('ERROR: New XP columns not initialized to 0.');
    } else {
        console.log('SUCCESS: New XP columns exist and are 0.');
    }

    // 2. Smelting Test
    console.log('\n2. Testing Smelting...');
    // Create an item via claim
    // Need to activate lab first?
    await supabase.rpc('rpc_start_sifting', { p_user_id: userId });
    // Need to complete stages to claim? 
    // Cheat: Update lab state directly if RLS allows? or just loop sift?
    // Start sift -> stage 0. Sift -> stage 1.
    // We need 5 stages for Mythic, 0 for Common?
    // rpc_claim determines tier based on stage.
    // If we claim immediately at stage 0, we get Common (Junk in our tiers?).
    // rpc_claim: CASE ... ELSE 'common'.
    // Item definitions has 'junk' and 'common'.
    // rpc_claim fallback to 'common' if junk not found?
    // Let's claim at stage 0.
    
    const { data: claimData, error: claimError } = await supabase.rpc('rpc_claim', { p_user_id: userId });
    if (claimError) {
        console.error('ERROR: Claim failed', claimError);
        return;
    }
    
    const item = claimData.item;
    console.log(`Claimed Item: ${item.name} (${item.tier})`);
    
    // Smelt it
    const { data: smeltData, error: smeltError } = await supabase.rpc('rpc_smelt', { p_item_id: item.id, p_user_id: userId });
    
    if (smeltError) {
        console.error('ERROR: Smelt failed', smeltError);
    } else {
        console.log('Smelt Result:', smeltData);
        if (smeltData.success && smeltData.xp_gained > 0) {
            console.log('SUCCESS: Smelt worked, XP gained.');
        } else {
            console.error('ERROR: Smelt success false or no XP.');
        }
    }
    
    // Verify Profile Update
    const { data: profileAfter } = await supabase.from('profiles').select('*').eq('id', userId).single();
    console.log(`Smelting XP: ${profileAfter.smelting_xp}`);
    if (profileAfter.smelting_xp > 0) {
        console.log('SUCCESS: Smelting XP updated.');
    } else {
         console.error('ERROR: Smelting XP not updated.');
    }

    // 3. Appraisal Test (Listing)
    console.log('\n3. Testing Appraisal (Listing)...');
    // Need another item
    await supabase.rpc('rpc_start_sifting', { p_user_id: userId });
    const { data: claimData2 } = await supabase.rpc('rpc_claim', { p_user_id: userId });
    const item2 = claimData2.item;
    
    const { data: listData, error: listError } = await supabase.rpc('rpc_list_item', { 
        p_vault_item_id: item2.id, 
        p_price: 100, 
        p_hours: 24, 
        p_user_id: userId 
    });

    if (listError) {
        console.error('ERROR: List failed', listError);
    } else {
        console.log('List Result:', listData);
        // Check XP
        const { data: profileAfterList } = await supabase.from('profiles').select('appraisal_xp').eq('id', userId).single();
        console.log(`Appraisal XP: ${profileAfterList.appraisal_xp}`);
        if (profileAfterList.appraisal_xp > 0) {
            console.log('SUCCESS: Appraisal XP updated.');
        } else {
             console.error('ERROR: Appraisal XP not updated.');
        }
    }

    console.log('\nVerification Complete.');
}

runVerification();
