
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://ekbetujzkebjekrisksa.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVrYmV0dWp6a2ViamVrcmlza3NhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5ODQwMjksImV4cCI6MjA3ODU2MDAyOX0.PGyxspaFfdYhKa3Z1AdI1_IWHQzepwe39W8shnKKGHg';

const supabase = createClient(supabaseUrl, supabaseKey);

async function verify() {
    const testId = '123e4567-e89b-12d3-a456-426614174000';

    console.log('Testing canonical rpc_extract...');

    const { data, error } = await supabase.rpc('rpc_extract', {
        p_user_id: testId,
        p_seismic_grade: 'HIT'
    });

    if (error) {
        console.error('RPC Error:', error);
    } else {
        console.log('RPC Success:', data);
    }
}

verify();
