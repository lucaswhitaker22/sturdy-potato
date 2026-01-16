import { supabase } from './src/lib/supabase';

async function verify() {
    const { data, error } = await supabase.rpc('rpc_get_profile', { p_user_id: '00000000-0000-0000-0000-000000000000' });
    console.log('Profile Fetch:', data, error);
}

verify();
