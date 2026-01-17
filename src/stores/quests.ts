import { defineStore } from 'pinia';
import { supabase } from '@/lib/supabase';
import { useGameStore } from './game';

export interface QuestReward {
  kind: 'scrap' | 'fine_dust' | 'dust' | 'hi' | 'title' | 'cosmetic' | 'item';
  amount?: number;
  id?: string;
}

export interface QuestObjective {
  kind: string;
  target: number;
  stage_at_least?: number;
}

export interface Quest {
  id: string; // database player_quest id
  quest_id: string; // definition id (e.g. archive_onboard_01)
  type: string; // onboarding, daily, etc
  status: 'AVAILABLE' | 'ACCEPTED' | 'COMPLETED' | 'CLAIMED';
  progress: Record<string, number>;
  title: string;
  context: string;
  objectives: QuestObjective[];
  rewards: QuestReward[];
}

export const useQuestStore = defineStore('quests', {
  state: () => ({
    quests: [] as Quest[],
    loading: false,
    initialized: false,
  }),

  getters: {
    availableQuests: (state) => state.quests.filter((q) => q.status === 'AVAILABLE'),
    activeQuests: (state) => state.quests.filter((q) => q.status === 'ACCEPTED' || q.status === 'COMPLETED'),
    completedQuests: (state) => state.quests.filter((q) => q.status === 'COMPLETED'),
    trackedQuests: (state) => state.quests.filter((q) => q.status === 'ACCEPTED' || q.status === 'COMPLETED').slice(0, 3),
    
    // Grouping
    onboardingQuests: (state) => state.quests.filter((q) => q.quest_id.startsWith('archive_onboard')),
  },

  actions: {
    async fetchQuests() {
      if (this.loading) return;
      this.loading = true;
      console.log('Fetching quests...');

      const { data, error } = await supabase.rpc('rpc_get_quests');

      if (error) {
        console.error('Failed to fetch quests:', error);
      } else if (data && data.success) {
        this.quests = data.quests;
        this.initialized = true;
      }

      this.loading = false;
    },

    async acceptQuest(questId: string) {
      console.log('Accepting quest:', questId);
      // Optimistic update
      const questIndex = this.quests.findIndex((q) => q.quest_id === questId && q.status === 'AVAILABLE');
      if (questIndex !== -1) {
        this.quests[questIndex].status = 'ACCEPTED';
      }

      const { data, error } = await supabase.rpc('rpc_accept_quest', { p_quest_id: questId });

      if (error || !data.success) {
        console.error('Failed to accept quest:', error || data.error);
        // Revert or Refetch
        await this.fetchQuests();
      }
    },

    async claimReward(questDbId: string) {
      console.log('Claiming quest reward:', questDbId);
      
      const { data, error } = await supabase.rpc('rpc_claim_quest_reward', { p_quest_db_id: questDbId });

      if (error || !data.success) {
        console.error('Failed to claim reward:', error || data.error);
        return;
      }

      // Refresh quests to see next in chain or status update
      await this.fetchQuests();
      
      // Also refresh game store stats (Scrap, Dust, etc changed)
      const gameStore = useGameStore();
      await gameStore.syncProfile();
    }
  }
});
