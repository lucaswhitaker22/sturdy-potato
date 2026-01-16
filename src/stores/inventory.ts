import { defineStore } from 'pinia';
import { ref } from 'vue';
import { supabase } from '@/lib/supabase';
import { TOOL_CATALOG } from '@/constants/items';
import type { VaultItem, ItemDefinition } from '@/types';
import { useGameStore } from './game'; // Circular ref handled by function scoping usually, but let's see. 
// Actually, better to pass dependencies or have a root store. 
// For now, we will duplicate some logic or rely on getters if needed, but Inventory is mostly leaf.

export interface MarketListing {
    id: string;
    seller_id: string;
    vault_item_id: string;
    item_id: string;
    reserve_price: number;
    highest_bid: number;
    ends_at: string;
    mint_number?: number;
}

export const useInventoryStore = defineStore('inventory', () => {
    // State
    const inventory = ref<VaultItem[]>([]);
    const catalog = ref<ItemDefinition[]>([]);
    const activeListings = ref<MarketListing[]>([]);
    const completedSetIds = ref<string[]>([]);
    // ownedTools could be here or skills? Let's put it here as it represents assets.
    const ownedTools = ref<Record<string, number>>({ 'rusty_shovel': 1 });
    const activeToolId = ref('rusty_shovel');

    // Actions
    async function fetchMarket() {
        const { data, error } = await supabase.rpc('rpc_get_active_listings');
        if (!error && data) {
            activeListings.value = data;
        }
    }

    async function listItem(vaultItemId: string, price: number, durationHours: number) {
        const { data, error } = await supabase.rpc('rpc_list_item', {
            p_vault_item_id: vaultItemId,
            p_price: price,
            p_duration_hours: durationHours
        });
        return { data, error };
    }

    async function placeBid(listingId: string, amount: number) {
        const { data, error } = await supabase.rpc('rpc_place_bid', {
            p_listing_id: listingId,
            p_bid_amount: amount
        });
        return { data, error };
    }

    // Helper Action to facilitate the extraction/sifting adding items
    // In a pure world, this might just update local state after RPC confirms.

    return {
        inventory,
        catalog,
        activeListings,
        completedSetIds,
        ownedTools,
        activeToolId,
        fetchMarket,
        listItem,
        placeBid
    };
});
