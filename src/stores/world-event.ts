
import { defineStore } from 'pinia';
import { ref } from 'vue';
import { supabase } from '@/lib/supabase';

export interface WorldEvent {
    id: string;
    name: string;
    description: string;
    starts_at: string;
    ends_at: string;
    status: 'upcoming' | 'active' | 'ended';
    modifiers: Record<string, any>;
    global_goal_target: number;
    global_goal_progress: number;
}

export const useWorldEventStore = defineStore('worldEvent', () => {
    const activeEvent = ref<WorldEvent | null>(null);

    async function fetchActiveEvent() {
        try {
            const { data, error } = await supabase.rpc('rpc_world_event_get_active');
            if (error) {
                if (error.message?.includes('SecurityError')) {
                    // Silent fail for security restrictions
                    return;
                }
                console.error('Failed to fetch active world event', error);
                return;
            }
            if (data?.success && data.active_event) {
                activeEvent.value = data.active_event;
            } else {
                activeEvent.value = null;
            }
        } catch (err) {
            console.warn('[WorldEvent] Fetch error (Security/Network):', err);
        }
    }

    // Subscribe to realtime updates for global progress
    function subscribe() {
        supabase.channel('world-events')
            .on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'world_events' }, (payload) => {
                if (activeEvent.value && payload.new.id === activeEvent.value.id) {
                    activeEvent.value = { ...activeEvent.value, ...payload.new } as WorldEvent;
                } else if (payload.new.status === 'active') {
                    // New event started
                    activeEvent.value = payload.new as WorldEvent;
                }
            })
            .subscribe();
    }

    async function contribute(amount: number, currency: 'scrap' | 'dust') {
        const { data, error } = await supabase.rpc('rpc_world_event_contribute', {
            p_amount: amount,
            p_currency: currency
        });
        if (data?.success) {
            if (activeEvent.value) {
                activeEvent.value.global_goal_progress = data.new_progress;
            }
            return true;
        }
        return false;
    }

    return {
        activeEvent,
        fetchActiveEvent,
        subscribe,
        contribute
    };
});

