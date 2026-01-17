
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';
import { useQuestStore } from '../quests';
import { useGameStore } from '../game';

// Mock Supabase with hoisting-safe pattern
vi.mock('@/lib/supabase', () => ({
  supabase: {
    rpc: vi.fn().mockResolvedValue({ data: { success: false }, error: null })
  }
}));

// Define shared spy
const syncProfileMock = vi.fn();

// Mock Game Store
vi.mock('../game', () => ({
  useGameStore: vi.fn(() => ({
    syncProfile: syncProfileMock
  }))
}));

// Import after mock
import { supabase } from '@/lib/supabase';

describe('Quest Store', () => {
    beforeEach(() => {
        setActivePinia(createPinia());
        vi.clearAllMocks();
    });

    it('initializes with empty state', () => {
        const store = useQuestStore();
        expect(store.quests).toEqual([]);
        expect(store.loading).toBe(false);
    });

    it('fetches quests successfully', async () => {
        const store = useQuestStore();
        const mockQuests = [
            { id: '1', quest_id: 'q1', status: 'AVAILABLE', title: 'Test Quest' }
        ];

        (supabase.rpc as any).mockResolvedValueOnce({ 
            data: { success: true, quests: mockQuests }, 
            error: null 
        });

        await store.fetchQuests();

        expect(store.quests).toEqual(mockQuests);
        expect(store.quests[0].title).toBe('Test Quest');
        expect(supabase.rpc).toHaveBeenCalledWith('rpc_get_quests');
    });

    it('optimistically accepts quest', async () => {
        const store = useQuestStore();
        // Setup initial available quest
        store.quests = [
            { id: '1', quest_id: 'q1', status: 'AVAILABLE', title: 'Test Quest' } as any
        ];

        // Mock RPC success
        (supabase.rpc as any).mockResolvedValueOnce({ data: { success: true }, error: null });

        await store.acceptQuest('q1');

        // Should be accepted immediately
        expect(store.quests[0].status).toBe('ACCEPTED');
        expect(supabase.rpc).toHaveBeenCalledWith('rpc_accept_quest', { p_quest_id: 'q1' });
    });

    it('reverts optimistic accept on failure', async () => {
        const store = useQuestStore();
        store.quests = [
            { id: '1', quest_id: 'q1', status: 'AVAILABLE', title: 'Test Quest' } as any
        ];

        // Mock RPC error
        (supabase.rpc as any).mockResolvedValueOnce({ data: null, error: { message: 'Failed' } });
        
        // Mock Refetch Quests (revert)
        (supabase.rpc as any).mockResolvedValueOnce({ 
            data: { success: true, quests: [
                { id: '1', quest_id: 'q1', status: 'AVAILABLE', title: 'Test Quest' }
            ] }, 
            error: null 
        });

        await store.acceptQuest('q1');

        // Should revert to AVAILABLE
        expect(store.quests[0].status).toBe('AVAILABLE');
    });

    it('claims reward and syncs profile', async () => {
        const store = useQuestStore();
        store.quests = [
            { id: 'db-id-1', quest_id: 'q1', status: 'COMPLETED', title: 'Done Quest' } as any
        ];

        // Mock Claim RPC success
        (supabase.rpc as any).mockResolvedValueOnce({ data: { success: true }, error: null });
        
        // Mock Refetch Quests (syncQuests called after claim)
        (supabase.rpc as any).mockResolvedValueOnce({ 
            data: { success: true, quests: [] }, 
            error: null 
        });

        await store.claimReward('db-id-1');

        expect(supabase.rpc).toHaveBeenCalledWith('rpc_claim_quest_reward', { p_quest_db_id: 'db-id-1' });
        // Should sync profile
        expect(syncProfileMock).toHaveBeenCalled();
    });

    it('getters filter correctly', () => {
        const store = useQuestStore();
        store.quests = [
            { id: '1', quest_id: 'q1', status: 'AVAILABLE' } as any,
            { id: '2', quest_id: 'q2', status: 'ACCEPTED' } as any,
            { id: '3', quest_id: 'q3', status: 'COMPLETED' } as any,
        ];

        expect(store.availableQuests).toHaveLength(1);
        expect(store.activeQuests).toHaveLength(2); // Accepted + Completed
        expect(store.completedQuests).toHaveLength(1);
        expect(store.trackedQuests).toHaveLength(2); // Active (Accepted + Completed) sliced
    });
});
