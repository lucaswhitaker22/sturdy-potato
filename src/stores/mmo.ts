import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { supabase } from '@/lib/supabase';

export interface GlobalEvent {
    id: string;
    event_type: 'find' | 'listing' | 'sale' | 'gamble' | 'anomaly' | 'counter_listing' | 'static_shift';
    user_id: string;
    details: any;
    created_at: string;
}

export interface Notification {
    id: string;
    user_id: string;
    message: string;
    type: 'info' | 'success' | 'warning' | 'error';
    is_read: boolean;
    created_at: string;
}

export const useMMOStore = defineStore('mmo', () => {
    const feed = ref<GlobalEvent[]>([]);
    const notifications = ref<Notification[]>([]);
    const unreadCount = computed(() => notifications.value.filter(n => !n.is_read).length);

    async function init() {
        try {
            let skipAuth = false;
            try { skipAuth = localStorage.getItem('skip_auth_check') === 'true'; } catch { }
            if (skipAuth) return;

            const { data, error } = await supabase.auth.getSession(); // getSession is faster & less likely to trigger security blocks than getUser
            if (error) throw error;
            const user = data?.session?.user;
            if (!user) return;

            // Fetch initial feed (last 50)
            const { data: feedData } = await supabase
                .from('global_events')
                .select('*')
                .order('created_at', { ascending: false })
                .limit(50);

            if (feedData) {
                // We want latest at the "end" of the list if we append, or beginning if we prepend.
                // Let's store newest last (chronological order) so we can auto-scroll or just show list.
                feed.value = (feedData as GlobalEvent[]).reverse();
            }

            // Fetch Notifications
            const { data: notifData } = await supabase
                .from('notifications')
                .select('*')
                .eq('user_id', user.id)
                .order('created_at', { ascending: false })
                .limit(20);

            if (notifData) notifications.value = notifData as Notification[];

            // Subscriptions
            supabase.channel('mmo-channels')
                .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'global_events' }, (payload) => {
                    const newEvent = payload.new as GlobalEvent;
                    feed.value.push(newEvent);
                    if (feed.value.length > 50) feed.value.shift();
                })
                .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'notifications', filter: `user_id=eq.${user.id}` }, (payload) => {
                    notifications.value.unshift(payload.new as Notification);
                })
                .subscribe();
        } catch (err) {
            console.warn('[MMOStore] Init failed (Security/Network):', err);
        }
    }

    async function markRead(id: string) {
        const n = notifications.value.find(x => x.id === id);
        if (n) n.is_read = true;

        await supabase.from('notifications').update({ is_read: true }).eq('id', id);
    }

    async function settleListing(listingId: string) {
        const { data, error } = await supabase.rpc('rpc_settle_listing', { p_listing_id: listingId });
        if (error) console.error("Settlement error:", error);
        return data;
    }

    // Call init immediately? Or wait for App mount?
    // Better to call it from App.vue or main layout

    function addLocalNotification(message: string, type: 'info' | 'success' | 'warning' | 'error' = 'info') {
        const notif: Notification = {
            id: crypto.randomUUID(),
            user_id: 'local',
            message,
            type,
            is_read: false,
            created_at: new Date().toISOString()
        };
        notifications.value.unshift(notif);
    }

    return {
        feed,
        notifications,
        unreadCount,
        init,
        markRead,
        settleListing,
        addLocalNotification
    };
});
