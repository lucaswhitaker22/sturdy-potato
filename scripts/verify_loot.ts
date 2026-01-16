
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

// Load env
dotenv.config({ path: path.resolve(process.cwd(), '.env') });

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('Missing VITE_SUPABASE_URL or VITE_SUPABASE_ANON_KEY');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function runVerification() {
    console.log('--- Verifying Loot & Collection Schema (Phase 3) ---');
    
    // 1. Check Schema Exists
    const { error: schemaError } = await supabase.from('item_definitions').select('count', { count: 'exact', head: true });
    if (schemaError) {
        console.error('FAIL: Schema check failed. Did you apply the migration?');
        console.error(schemaError.message);
        return;
    }
    console.log('PASS: Schema tables found (item_definitions).');

    // 2. Simulate User
    const testUserId = '00000000-0000-0000-0000-000000000000'; // Mock or create one
    // We can't easily create a user via anon key unless we use a real signup?
    // We'll trust the dev environment might have a user or we use a known one.
    // Actually, let's just use a random UUID and fail if rpc checks auth strictly (it does check auth.uid()).
    // To test properly, we might need a service role key or just disable RLS on the RPC for testing?
    // My RPC `rpc_claim` takes `p_user_id` specifically to allow this "local identity" simulation!
    
    const simUserId = '55555555-5555-5555-5555-555555555555';
    console.log(`Simulating claims for user ${simUserId}...`);

    // Reset Lab State for simulation
    await supabase.from('lab_state').upsert({ user_id: simUserId, is_active: true, current_stage: 3 }); // Stage 3 = Rare
    await supabase.from('profiles').upsert({ id: simUserId, tray_count: 5 });

    let prismaticCount = 0;
    let iterations = 100;
    
    for (let i = 0; i < iterations; i++) {
        // Reset lab to active for every claim
        await supabase.from('lab_state').upsert({ user_id: simUserId, is_active: true, current_stage: Math.floor(Math.random() * 5) });

        const { data, error } = await supabase.rpc('rpc_claim', { p_user_id: simUserId });
        
        if (error) {
            console.error('Claim error:', error.message);
            continue;
        }

        if (data.success && data.item) {
            const item = data.item;
            if (item.is_prismatic) {
                console.log(`[!] PRISMATIC FOUND: ${item.name} (#${item.mint_number})`);
                prismaticCount++;
            }
            // Basic validation
            if (!item.condition || !item.historical_value) {
                 console.error('FAIL: Missing rich attributes on item:', item);
            }
        }
    }

    console.log(`--- Simulation Results ---`);
    console.log(`Claims: ${iterations}`);
    console.log(`Prismatic Rate: ${prismaticCount}/${iterations} (${(prismaticCount/iterations)*100}%) - Expected ~1%`);
    
    if (prismaticCount > 0) {
        console.log('PASS: Prismatic mechanic verified.');
    } else {
        console.warn('WARN: No prismatics found (statistically possible but check logic if consistently 0).');
    }
}

runVerification();
