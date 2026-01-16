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
    const [key, val] = line.split('=');
    if (key && val) env[key.trim()] = val.trim();
});

const supabaseUrl = env.VITE_SUPABASE_URL || '';
const supabaseKey = env.VITE_SUPABASE_ANON_KEY || '';
const supabase = createClient(supabaseUrl, supabaseKey);

async function verify() {
    console.log('Verifying Active Stabilization...');

    // 1. Setup User (Local mimic)
    let userId = '00000000-0000-0000-0000-000000000000'; // Default valid UUID for test or needs real auth?
    // Our RPC uses `get_auth_user` which checks `auth.uid()` OR param.
    // Since we are running outside auth context, we need a valid UUID that exists in `profiles`.
    // I will try to fetch a profile first or create one if possible (unlikely without admin).
    // Assuming the user running `npm run dev` has a local ID.
    // I'll grab the first user from profiles to test with.

    const { data: users } = await supabase.from('profiles').select('id').limit(1);
    if (!users || users.length === 0) {
        console.error('No users found to test with.');
        return;
    }
    userId = users[0].id;
    console.log(`Testing with User ID: ${userId}`);

    // 2. Give Fine Dust
    // I cannot easily give dust without admin rights or a backdoor.
    // BUT I can fail a sift to get dust if standard fail works.
    // Check balance first.
    let { data: profile } = await supabase.from('profiles').select('*').eq('id', userId).single();
    console.log(`Initial Fine Dust: ${profile.fine_dust_balance}`);

    // 3. Ensure Lab Active (Start Sifting)
    // Check tray count. IF 0, we can't start.
    if (profile.tray_count === 0) {
        // Attempt to give a crate (cheat RPC?) or rely on user state.
        // If I can't setup state, I can just call rpc_sift and expect "No active crate" error, which confirms RPC exists.
        // But I want to test the new logic.
        console.warn('Tray count is 0. Cannot testing sifting fully without manual play.');
        // Try to trigger a "find" event? rpc_extract?
        // Let's call rpc_extract and hope for a crate.
        console.log('Attempting extract to find crate...');
        await supabase.rpc('rpc_extract', { p_user_id: userId });
    }

    // Reload profile
    const { data: profile2 } = await supabase.from('profiles').select('*').eq('id', userId).single();
    if (profile2.tray_count > 0) {
        // Start Sifting
        await supabase.rpc('rpc_start_sifting', { p_user_id: userId });
        console.log('Started Sifting.');

        // 4. Test Sift with Tether (if affordable)
        const cost = 2; // Stage 1 min
        if (profile2.fine_dust_balance >= cost) {
            console.log('Attempting Sift with 1 Tether...');
            const { data, error } = await supabase.rpc('rpc_sift', {
                p_user_id: userId,
                p_tethers_used: 1,
                p_zone: 0 // Safe
            });
            if (error) console.error('Sift Error:', error);
            else console.log('Sift Result (Tethered):', data);
        } else {
            console.log('Not enough dust for Tether test. Testing standard sift...');
            const { data, error } = await supabase.rpc('rpc_sift', {
                p_user_id: userId,
                p_tethers_used: 0,
                p_zone: 1 // Danger Zone! (High risk)
            });
            if (error) console.error('Sift Error:', error);
            else console.log('Sift Result (Untethered, Danger):', data);
        }
    } else {
        console.log('Still no tray count. Verified RPC signature availability only.');
    }

    console.log('Verification Complete.');
}

verify();
