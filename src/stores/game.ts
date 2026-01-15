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
  const ownedTools = ref<Record<string, number>>({ 'rusty_shovel': 1 }); // tool_id -> level
  const completedSetIds = ref<string[]>([]);
  const overclockBonus = ref(0);
  const lastExtractAt = ref<Date | null>(null);

  // Animation State
  const surveyProgress = ref(0);
  const passiveProgress = ref(0);

  // Getters
  // Backward compatibility for components expecting string[]
  const vaultItems = computed(() => inventory.value.map(i => i.item_id));
  
  const discoveredCount = computed(() => inventory.value.length);
  const uniqueItemsFound = computed(() => new Set(inventory.value.map(i => i.item_id)).size);
  
  // Sync with SQL Public.get_level
  function calculateLevel(xp: number) {
    let threshold = 0;
    for (let i = 1; i <= 98; i++) {
      threshold += Math.floor(i + 300 * Math.pow(2, i / 7));
      if (xp < threshold) return i;
    }
    return 99;
  }

  const excavationLevel = computed(() => calculateLevel(excavationXP.value));
  const restorationLevel = computed(() => calculateLevel(restorationXP.value));

  const cooldownMs = computed(() => {
    return completedSetIds.value.includes('morning_ritual') ? 2500 : 3000;
  });

  const isCooldown = computed(() => {
    if (!lastExtractAt.value) return false;
    const elapsed = Date.now() - lastExtractAt.value.getTime();
    return elapsed < cooldownMs.value;
  });

  const surveyDurationMs = computed(() => {
    // 0.5s to 2s depending on tool? 
    // Simplified: Base 2s, reduced by 10% per tool tier?
    const tiers: Record<string, number> = { 'rusty_shovel': 2000, 'pneumatic_pick': 1500, 'ground_radar': 1000, 'industrial_drill': 500 };
    return tiers[activeToolId.value] || 2000;
  });

  function getToolLevel(toolId: string) {
    return ownedTools.value[toolId] || 0;
  }

  function getToolCost(toolId: string) {
    const tool = TOOL_CATALOG.find(t => t.id === toolId);
    if (!tool) return 0;
    const level = getToolLevel(toolId);
    if (level === 0) return tool.cost; // Base cost for purchase
    // Exponential: Cost = Base * 1.5^Level
    return Math.floor(tool.cost * Math.pow(1.5, level));
  }

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
      // Animation progress handled by component or store?
      // For now, component will handle visual.
      try {
        const { data, error } = await supabase.rpc('rpc_passive_tick');
        if (error) throw error;
        if (data.success) {
           if (data.crate_dropped) {
             addLog(`PASSIVE: Automated unit found a Crate!`);
             scrapBalance.value = data.new_balance; 
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
      overclockBonus.value = profile.overclock_bonus || 0;
      lastExtractAt.value = profile.last_extract_at ? new Date(profile.last_extract_at) : null;
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
    const { data: tools } = await supabase.from('owned_tools').select('tool_id, level').eq('user_id', user.id);
    if (tools) {
        const toolMap: Record<string, number> = {};
        tools.forEach(t => toolMap[t.tool_id] = t.level);
        ownedTools.value = toolMap;
    }
    // Ensure default is always there
    if (!ownedTools.value['rusty_shovel']) ownedTools.value['rusty_shovel'] = 1;

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
        overclockBonus.value = newProfile.overclock_bonus || 0;
        lastExtractAt.value = newProfile.last_extract_at ? new Date(newProfile.last_extract_at) : lastExtractAt.value;
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
    
    // 1. Survey Phase (Manual interaction)
    addLog('Surveying the field...');
    
    // Wait for survey duration
    await new Promise(resolve => setTimeout(resolve, surveyDurationMs.value));

    try {
      const { data, error } = await supabase.rpc('rpc_extract');
      if (error) throw error;
      if (data.success) {
        if (data.result === 'ANOMALY') {
          addLog('⚠ ANOMALY DETECTED: Temporal instability recorded. Rare energy surge synchronized.');
        } else if (data.crate_dropped) {
          addLog('CRATE FOUND! Return to lab to analyze.');
        } else if (data.result === 'SCRAP_FOUND') {
          addLog(`Extraction complete. +${data.scrap_gain} Scrap.`);
        } else {
          addLog('Nothing found in this sector.');
        }
        lastExtractAt.value = new Date(); // Local sync
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
    if (isExtracting.value || !labState.value.isActive) return;
    isExtracting.value = true;
    
    try {
      const { data, error } = await supabase.rpc('rpc_sift');
      if (error) throw error;
      
      if (data.success) {
        if (data.outcome === 'SUCCESS') {
          addLog(`Sequence Success: Layer ${data.new_stage} stabilized.`);
          labState.value.currentStage = data.new_stage;
          restorationXP.value += 10; // Basic assumption if not in RPC
        } else if (data.outcome === 'SHATTERED') {
          addLog('⚠ CRITICAL FAILURE: Specimen shattered. Structural integrity lost.');
          labState.value.isActive = false;
          labState.value.currentStage = 0;
          trayCount.value -= 1;
        } else if (data.outcome === 'ANOMALY') {
           addLog('⚠ TEMPORAL RIFT: Sifting process bypassed dimensional limits.');
        }
      } else {
        addLog(`Sift Error: ${data.error}`);
      }
    } catch (err: any) {
      addLog(`System Error: ${err.message}`);
    } finally {
      isExtracting.value = false;
    }
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
        addLog(`Tool ${toolId} reached Level ${data.new_level}`);
        ownedTools.value[toolId] = data.new_level; 
        activeToolId.value = toolId;
        startPassiveLoop(); 
      }
  }

  async function setActiveTool(toolId: string) {
      const { error } = await supabase.from('profiles').update({ active_tool_id: toolId }).eq('id', userSessionId.value);
      if (error) {
          addLog(`Deployment Error: ${error.message}`);
      } else {
          activeToolId.value = toolId;
          addLog(`EQUIPMENT DEPLOYED: ${toolId.toUpperCase()}`);
          startPassiveLoop();
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

  async function overclockTool(toolId: string, cost: number) {
     const { data, error } = await supabase.rpc('rpc_overclock_tool', { p_tool_id: toolId, p_cost: cost });
     if (data?.success) {
        addLog(`TECH PRESTIGE: Tool overclocked! Sift stability increased by 5%.`);
        overclockBonus.value = data.new_bonus;
     } else {
        addLog(`Overclock Failed: ${error?.message || data?.error}`);
     }
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
    ownedTools,
    completedSetIds,
    discoveredCount,
    uniqueItemsFound,
    excavationLevel,
    restorationLevel,
    cooldownMs,
    getToolLevel,
    getToolCost,
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
    setActiveTool,
    claimSet,
    purchaseInfluenceItem,
    overclockTool,
    overclockBonus,
    surveyDurationMs,
    isCooldown,
    lastExtractAt
  };
});
