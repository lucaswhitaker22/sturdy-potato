
import { createClient } from '@supabase/supabase-js';

// Hardcode from .env read previously to avoid parsing issues
const supabaseUrl = 'https://ekbetujzkebjekrisksa.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVrYmV0dWp6a2ViamVrcmlza3NhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5ODQwMjksImV4cCI6MjA3ODU2MDAyOX0.PGyxspaFfdYhKa3Z1AdI1_IWHQzepwe39W8shnKKGHg';

const supabase = createClient(supabaseUrl, supabaseKey);

async function verify() {
    const testId = '123e4567-e89b-12d3-a456-426614174000';

    console.log('Testing rpc_extract...');

    // Test with explicit null
    const { data, error } = await supabase.rpc('rpc_extract_seismic', {
        p_user_id: testId,
        p_seismic_grade: null
    });

    if (error) {
        console.error('RPC Error:', error);
    } else {
        console.log('RPC Success:', data);
    }
}

verify();
