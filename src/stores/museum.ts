
import { defineStore } from 'pinia';
import { ref } from 'vue';
import { supabase } from '@/lib/supabase';
import { useGameStore } from './game';

export interface MuseumWeek {
  id: string;
  theme_name: string;
  description: string;
  ends_at: string;
}

export interface MuseumSubmission {
  vault_item_id: string;
  score: number;
  item_details: {
    item_id: string;
    mint_number: number;
  };
}

export const useMuseumStore = defineStore('museum', () => {
    const activeWeek = ref<MuseumWeek | null>(null);
    const userSubmissions = ref<MuseumSubmission[]>([]);
    const isLoading = ref(false);

    const totalScore = ref(0);
    const setBonusActive = ref(false);

    async function fetchActiveWeek() {
        isLoading.value = true;
        const { data, error } = await supabase.rpc('rpc_museum_get_current_week');
        isLoading.value = false;

        if (error) {
            console.error('Error fetching museum week:', error);
            return;
        }

        if (data.success) {
            activeWeek.value = data.active_week;
            userSubmissions.value = data.user_submissions || [];
            totalScore.value = data.total_score || 0;
            setBonusActive.value = data.set_bonus_active || false;
        }
    }

    async function submitItem(vaultItemId: string) {
        const gameStore = useGameStore();
        const { data, error } = await supabase.rpc('rpc_museum_submit_item', {
            p_vault_item_id: vaultItemId
        });

        if (error) {
            gameStore.addLog(`Museum Error: ${error.message}`);
            return false;
        }

        if (!data.success) {
            gameStore.addLog(`Submission Failed: ${data.error}`);
            return false;
        }

        gameStore.addLog(`Item submitted to Museum! Score: ${data.score}`);
        await fetchActiveWeek(); // Refresh to show new submission
        return data;
    }

    return {
        activeWeek,
        userSubmissions,
        totalScore,
        setBonusActive,
        isLoading,
        fetchActiveWeek,
        submitItem
    };
});
