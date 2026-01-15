import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { supabase } from '@/lib/supabase';
import { TOOL_CATALOG } from '@/constants/items';

export interface VaultItem {
  id: string; // UUID
  item_id: string; // Catalog ID
  mint_number: number | null;
  created_at: string;
}

export interface MarketListing {
  id: string;
  seller_id: string;
  vault_item_id: string;
  item_id: string; // denormalized or joined
  reserve_price: number;
  highest_bid: number;
  ends_at: string;
  mint_number?: number; // client-side join
}

export const useGameStore = defineStore('game', () => {
  // State
  const userSessionId = ref<string | null>(null);
  const scrapBalance = ref(0);
  const historicalInfluence = ref(0); // [NEW]
  const trayCount = ref(0);
  const inventory = ref<VaultItem[]>([]);
  const activeListings = ref<MarketListing[]>([]);
  
  const labState = ref({
    isActive: false,
    currentStage: 0,
  });
  
  const log = ref<string[]>(['> Connection established.', '> Initializing bio-scanner...']);
  const isExtracting = ref(false);
  
  // Progression
  const excavationXP = ref(0);
  const restorationXP = ref(0);
  const activeToolId = ref('rusty_shovel');
  const ownedToolIds = ref<string[]>(['rusty_shovel']);
  const completedSetIds = ref<string[]>([]);

  // Getters
  // Backward compatibility for components expecting string[]
  const vaultItems = computed(() => inventory.value.map(i => i.item_id));
  
  const discoveredCount = computed(() => inventory.value.length);
  const uniqueItemsFound = computed(() => new Set(inventory.value.map(i => i.item_id)).size);
  const excavationLevel = computed(() => Math.floor(excavationXP.value / 100) + 1);
  const restorationLevel = computed(() => Math.floor(restorationXP.value / 100) + 1);
  const cooldownMs = computed(() => {
    return completedSetIds.value.includes('morning_ritual') ? 2500 : 3000;
  });

  // Actions
  function addLog(message: string) {
    log.value.unshift(`> ${message}`);
    if (log.value.length > 50) log.value.pop();
  }

  // Phase 2: Passive Loop
  let passiveInterval: any = null;

  function startPassiveLoop() {
    if (passiveInterval) clearInterval(passiveInterval);
    
    // Check if we have a passive tool
    const tool = TOOL_CATALOG.find(t => t.id === activeToolId.value);
    if (!tool || tool.automationRate <= 0) return;

    // 10s Tick (aligns with mechanics)
    passiveInterval = setInterval(async () => {
      // Optimistic or Real check? R19 says server authority.
      // logic is in rpc_passive_tick
      try {
        const { data, error } = await supabase.rpc('rpc_passive_tick');
        if (error) throw error;
        if (data.success) {
           // Silent update usually, or maybe small log?
           // Only log crates?
           if (data.crate_dropped) {
             addLog(`PASSIVE: Automated unit found a Crate!`);
             // State updated via subscription usually, but we can patch local given the payload return
             scrapBalance.value = data.new_balance; // Ensure sync
           }
        }
      } catch (err) {
        console.error('Passive tick error', err);
      }
    }, 10000);
  }

  // Phase 2: Offline Gains
  async function checkOfflineGains() {
    try {
      const { data, error } = await supabase.rpc('rpc_handle_offline_gains');
      if (error) throw error;
      if (data.success && data.scrap_gain > 0) {
        addLog(`OFFLINE REPORT: Systems active for ${data.seconds_offline}s. Yield: +${data.scrap_gain} Scrap.`);
        // State updated via subscription potentially
      }
    } catch (err) {
      console.error('Offline gains error', err);
    }
  }

  // Initial Data Fetch & Subscription
  async function init() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;
    userSessionId.value = user.id;

    // 1. Fetch Profile
    const { data: profile } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .single();
      
    if (profile) {
      scrapBalance.value = profile.scrap_balance;
      historicalInfluence.value = profile.historical_influence || 0; // [NEW]
      trayCount.value = profile.tray_count;
      excavationXP.value = profile.excavation_xp || 0;
      restorationXP.value = profile.restoration_xp || 0;
      activeToolId.value = profile.active_tool_id || 'rusty_shovel';
    }

    // 2. Fetch Lab State
    const { data: lab } = await supabase
      .from('lab_state')
      .select('*')
      .eq('user_id', user.id)
      .single();

    if (lab) {
      labState.value = {
        isActive: lab.is_active,
        currentStage: lab.current_stage
      };
    }

    // 3. Fetch Inventory
    const { data: items } = await supabase
      .from('vault_items')
      .select('*')
      .eq('user_id', user.id);
      
    if (items) {
      inventory.value = items as VaultItem[];
    }
    
    // 4. Fetch Owned Tools & Sets
    const { data: tools } = await supabase.from('owned_tools').select('tool_id').eq('user_id', user.id);
    if (tools) ownedToolIds.value = tools.map(t => t.tool_id);
    // Ensure default is always there
    if (!ownedToolIds.value.includes('rusty_shovel')) ownedToolIds.value.push('rusty_shovel');

    const { data: sets } = await supabase.from('completed_sets').select('set_id').eq('user_id', user.id);
    if (sets) completedSetIds.value = sets.map(s => s.set_id);

    // 5. Setup Realtime Subscription
    supabase.channel('game-state')
      .on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'profiles', filter: `id=eq.${user.id}` }, (payload) => {
        const newProfile = payload.new as any;
        scrapBalance.value = newProfile.scrap_balance;
        historicalInfluence.value = newProfile.historical_influence || 0; // [NEW]
        trayCount.value = newProfile.tray_count;
        excavationXP.value = newProfile.excavation_xp;
        restorationXP.value = newProfile.restoration_xp;
        activeToolId.value = newProfile.active_tool_id;
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'vault_items', filter: `user_id=eq.${user.id}` }, async (payload) => {
        // Refresh inventory on any change to be safe, or handle granularly
        if (payload.eventType === 'INSERT') {
          inventory.value.push(payload.new as VaultItem);
          addLog(`Server synced: Item received.`);
        } else if (payload.eventType === 'DELETE') {
           inventory.value = inventory.value.filter(i => i.id !== payload.old.id);
        }
      })
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'global_events' }, (payload) => {
         const evt = payload.new;
         // Handle global events (e.g. notifications)
         if (evt.event_type === 'find') {
            // Optional: Show toast
         }
      })
      .subscribe();

    // Phase 2 Startup
    await checkOfflineGains();
    startPassiveLoop();
    
    // Watch active tool to restart loop if it changes
    // But we are outside setup(), so we need to validly watch?
    // Pinia stores don't have implicit watchers unless we use storeToRefs inside components?
    // Actually we can use `activeToolId` ref directly here or subscribe?
    // Pinia stores can just subscribe to themselves? 
    // Simplified: Just restart loop on `upgradeTool` action success and `init`.
  }

  // Core Loop
  async function extract() {
    if (isExtracting.value) return;
    isExtracting.value = true;
    // differentiate log based on context if possible, but for now we assume extract is the intent
    addLog('Extracting...');
    
    try {
      const { data, error } = await supabase.rpc('rpc_extract');
      if (error) throw error;
      if (data.success) {
        if (data.outcome === 'SUCCESS') {
           // This indicates a Sift success from the backend
          addLog(`SUCCESS: +${data.xp_gain} XP. Lab stage advanced.`);
          labState.value.currentStage = data.new_stage;
        } else if (data.outcome === 'SHATTERED') {
           // This indicates a Sift failure
          addLog('FAILURE: Sample shattered during extraction.');
          labState.value.isActive = false;
          labState.value.currentStage = 0;
        } else if (data.outcome === 'ANOMALY' || data.anomaly) {
          addLog('⚠ ANOMALY DETECTED: Temporal instability recorded. No yield.');
        } else if (data.crate_dropped) {
          addLog('CRATE FOUND! Return to lab to analyze.');
        } else {
          addLog(`Extraction complete. +${data.scrap_gain} Scrap.`);
        }
      } else {
        addLog(`Error: ${data.error}`);
      }
    } catch (err: any) {
      addLog(`System Error: ${err.message}`);
    } finally {
      isExtracting.value = false;
    }
  }

  async function sift() {
      // Sift is logically distinct but currently shares the RPC. 
      // We wrap it to ensure UI consistency if we want to add specific 'sifting' loading state later.
      return extract();
  }

  function startSifting() {
    // Optimistic update
    if (trayCount.value > 0 && !labState.value.isActive) {
      labState.value.isActive = true;
      labState.value.currentStage = 0;
      addLog('Crate moved to Lab. Preparing for analysis.');
      // In a real app we might want to sync this state to DB if we want "Lab is Busy" persistence
      // But currently lab_state is updated via rpc_extract or similar? 
      // Wait, startSifting just moves state. The DB `lab_state` table exists.
      // We should probably have an RPC to "activate" the crate to be safe, 
      // but for now client-side optimistic is okay if the next action (extract) verifies it.
      // Actually, let's just update the local state. DB is updated when we CLAIM or SHATTER. 
      // But `rpc_extract` checks `is_active` in DB.
      // So checking the migration `rpc_extract`: It checks `v_lab.is_active`.
      // So we DO need to tell the server we started sifting.
      // Phase 1 migration didn't have `rpc_start_sift`.
      // It seems users just "have" a crate? 
      // Let's check `rpc_extract`: 
      // `IF v_lab IS NULL OR NOT v_lab.is_active THEN ...`
      // So we need to activate it. 
      // We need a helper RPC or direct update.
      supabase.from('lab_state').update({ is_active: true, current_stage: 0 }).eq('user_id', userSessionId.value).then(({ error }) => {
        if (error) addLog(`Error activating lab: ${error.message}`);
      });
    }
  }

  async function claim() {
    try {
      const { data, error } = await supabase.rpc('rpc_claim');
      if (error) throw error;
      if (data.success) {
        addLog(`ANALYSIS COMPLETE: Identified ${data.tier} item: ${data.item_id.toUpperCase()} #${data.mint_number}`);
        labState.value.isActive = false;
        labState.value.currentStage = 0;
        // Inventory update handled by subscription
      } else {
        addLog(`Claim Error: ${data.error}`);
      }
    } catch (err: any) {
      addLog(`Error: ${err.message}`);
    }
  }

  // Bazaar Actions
  async function fetchMarket() {
    // Join with vault_items to get mint number is tricky if RLS blocks reading others' items?
    // Wait, my RLS allows reading vault_items? "Users can view own vault". 
    // Sellers need to allow others to see the item? 
    // Actually, `market_listings` should probably store the item details or we need RLS to allow reading claimed items if they are listed.
    // Use a view or a join function?
    // For now, I'll fetch listings and maybe I can't see the mint number if I cannot read the vault item.
    // FIX: I will add `mint_number` to `market_listings` denormalized OR rely on `rpc_list_item` to snapshot it?
    // No, I added `mint_number` to `vault_items`. 
    // I need to start exposing `mint_number` in `market_listings` view?
    // I'll fetch `market_listings` and I might need to fetch the related item details.
    // If I can't join, I'll just show the listing.
    
    const { data, error } = await supabase
      .from('market_listings')
      .select('*, vault_items(item_id, mint_number)') // Query foreign key
      .eq('status', 'active')
      .order('created_at', { ascending: false });

    if (error) {
      console.error(error);
      return;
    }
    
    activeListings.value = data.map((l: any) => ({
      ...l,
      item_id: l.vault_items?.item_id || 'unknown',
      mint_number: l.vault_items?.mint_number
    }));
  }

  async function listItem(vaultItemId: string, price: number) {
    const { data, error } = await supabase.rpc('rpc_list_item', {
      p_vault_item_id: vaultItemId,
      p_price: price,
      p_hours: 24
    });
    
    if (error) {
      addLog(`Listing Error: ${error.message}`);
      return false;
    }
    if (!data.success) {
      addLog(`Listing Failed: ${data.error}`);
      return false;
    }
    addLog('Item listed on Bazaar.');
    return true; // Success
  }

  async function placeBid(listingId: string, amount: number) {
    const { data, error } = await supabase.rpc('rpc_place_bid', {
      p_listing_id: listingId,
      p_amount: amount
    });
    
    if (error) {
      addLog(`Bid Error: ${error.message}`);
      return false;
    }
    if (!data.success) {
       addLog(`Bid Failed: ${data.error}`);
       return false;
    }
    addLog(`Bid placed: ${amount} scrap.`);
    return true;
  }
  
  // Other Actions
  async function upgradeTool(toolId: string, cost: number) {
     const { data, error } = await supabase.rpc('rpc_upgrade_tool', { p_tool_id: toolId, p_cost: cost });
     if (data?.success) {
        addLog(`Tool upgraded to ${toolId}`);
        ownedToolIds.value.push(toolId); // optimistic
        activeToolId.value = toolId; // optimistic
        startPassiveLoop(); // Restart loop with new tool speed (or capability)
        // Subscriptions update state
      }
  }

  async function claimSet(setId: string, reward: number) {
      // Use RPC
      const { data, error } = await supabase.rpc('rpc_claim_set', { p_set_id: setId });
      
      if (error) {
        addLog(`Claim Error: ${error.message}`);
        return;
      }

      if (data.success) {
        addLog(`SET COMPLETED: ${setId}. Reward: ${data.reward_scrap > 0 ? '+' + data.reward_scrap + ' Scrap' : 'BUFF APPLIED'}`);
        completedSetIds.value.push(setId);
        // Refresh profile via subscription usually, but optimistic update helps UI
      } else {
        addLog(`Claim Failed: ${data.error}`);
      }
  }

  async function purchaseInfluenceItem(itemKey: string) {
      const { data, error } = await supabase.rpc('rpc_purchase_influence_item', { p_item_key: itemKey });

      if (error) {
          addLog(`Purchase Error: ${error.message}`);
          return false;
      }

      if (!data.success) {
          addLog(`Purchase Failed: ${data.error}`);
          return false;
      }

      addLog(`Purchased ${itemKey} from Influence Shop!`);
      return true;
  }

  // Initialize
  init();

  return {
    scrapBalance,
    historicalInfluence,
    trayCount,
    inventory,
    vaultItems, // backward compat
    activeListings,
    labState,
    log,
    isExtracting,
    excavationXP,
    restorationXP,
    activeToolId,
    ownedToolIds,
    completedSetIds,
    discoveredCount,
    uniqueItemsFound,
    excavationLevel,
    restorationLevel,
    cooldownMs,
    extract,
    sift: extract, // Alias if needed
    claim,
    startSifting,
    addLog,
    init,
    fetchMarket,
    listItem,
    placeBid,
    upgradeTool,
    claimSet,
    purchaseInfluenceItem
  };
});
