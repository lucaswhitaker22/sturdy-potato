import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { supabase } from '@/lib/supabase';
import { TOOL_CATALOG } from '@/constants/items';
import type { VaultItem, ItemDefinition } from '@/types';
import { useMMOStore } from './mmo';
import {
  type SeismicState,
  type SeismicGrade,
  calculateSweetSpotWidth,
  generateSweetSpotStart,
  gradeStrike
} from '@/lib/seismic';

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
  const catalog = ref<ItemDefinition[]>([]);
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
  const appraisalXP = ref(0);
  const smeltingXP = ref(0);
  const activeToolId = ref('rusty_shovel');
  const ownedTools = ref<Record<string, number>>({ 'rusty_shovel': 1 }); // tool_id -> level
  const completedSetIds = ref<string[]>([]);
  const overclockBonus = ref(0);
  const batteryCapacity = ref(8.0);
  const lastExtractAt = ref<Date | null>(null);

  // Seismic Surge State
  const seismicState = ref<SeismicState>({
    isActive: false,
    config: { sweetSpotWidth: 10, perfectZoneWidth: 30, sweetSpotStart: 50 },
    impactPos: 0,
    grades: [],
    maxStrikes: 1
  });

  // Animation State
  const now = ref(Date.now());
  const surveyProgress = ref(0);
  const passiveProgress = ref(0);

  // Timer for reactivity
  setInterval(() => { now.value = Date.now() }, 100);

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
  const appraisalLevel = computed(() => calculateLevel(appraisalXP.value));
  const smeltingLevel = computed(() => calculateLevel(smeltingXP.value));

  const cooldownMs = computed(() => {
    return completedSetIds.value.includes('morning_ritual') ? 2500 : 3000;
  });

  const isCooldown = computed(() => {
    if (!lastExtractAt.value) return false;
    const elapsed = now.value - lastExtractAt.value.getTime();
    return elapsed < cooldownMs.value;
  });

  const surveyDurationMs = computed(() => {
    // 0.5s to 2s depending on tool? 
    // Simplified: Base 2s, reduced by 10% per tool tier?
    const tiers: Record<string, number> = {
      'rusty_shovel': 2000,
      'pneumatic_pick': 1500,
      'ground_radar': 1000,
      'industrial_drill': 500,
      'seismic_array': 250,
      'satellite_uplink': 100
    };
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
      try {
        const { data, error } = await supabase.rpc('rpc_passive_tick');
        if (error) throw error;
        if (data.success) {
          if (data.crate_dropped) {
            addLog(`PASSIVE: Automated unit found a Crate!`);
            scrapBalance.value = Number(data.new_balance || scrapBalance.value);
            console.log('[Store] Passive Scrap Update:', scrapBalance.value);
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
    console.log('[Store] Initializing system sequence...');
    let { data: { user } } = await supabase.auth.getUser();

    if (!user) {
      console.log('[Store] No active session. Using local identity...');
      // Primary fix: Use localStorage for identity since anonymous auth is disabled on Supabase
      let localId = localStorage.getItem('local_user_id');
      if (!localId) {
        localId = crypto.randomUUID();
        localStorage.setItem('local_user_id', localId);
      }

      // We'll treat this localId as the user.id for our RPC calls
      // Note: We're mimicking the user object for internal logic consistency
      user = { id: localId } as any;
      console.log('[Store] Local identity established:', user?.id);
    }

    if (!user) {
      addLog('CRITICAL: Access Denied. Sector lock active.');
      return;
    }

    userSessionId.value = user.id;
    addLog(`Operator Identified. Welcome back, ${user.id.substring(0, 8)}.`);

    // 1. Fetch Profile
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .single();

    if (profileError && profileError.code !== 'PGRST116') { // PGRST116 is 'no rows'
      console.error('[Store] Profile Fetch Error:', profileError);
    }

    if (profile) {
      console.log('[Store] Profile state recovered:', profile);
      scrapBalance.value = Number(profile.scrap_balance || 0);
      historicalInfluence.value = Number(profile.historical_influence || 0);
      trayCount.value = Number(profile.tray_count || 0);
      excavationXP.value = Number(profile.excavation_xp || 0);
      restorationXP.value = Number(profile.restoration_xp || 0);
      appraisalXP.value = Number(profile.appraisal_xp || 0);
      smeltingXP.value = Number(profile.smelting_xp || 0);
      activeToolId.value = profile.active_tool_id || 'rusty_shovel';
      overclockBonus.value = Number(profile.overclock_bonus || 0);
      lastExtractAt.value = profile.last_extract_at ? new Date(profile.last_extract_at) : null;
    } else {
      console.log('[Store] No existing profile. New ledger created.');
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

    // 3. Fetch Catalog (Definitions)
    const { data: defs } = await supabase.from('item_definitions').select('*');
    if (defs) {
      catalog.value = defs as ItemDefinition[];
    }

    // 4. Fetch Inventory
    const { data: items } = await supabase
      .from('vault_items')
      .select('*')
      .eq('user_id', user.id);

    if (items) {
      inventory.value = items.map((i: any) => {
        const def = catalog.value.find(d => d.id === i.item_id);
        return { ...i, item: def, name: def?.name, tier: def?.tier, flavorText: def?.flavor_text };
      }) as VaultItem[];
    }

    // 4. Fetch Owned Tools & Sets
    const { data: tools } = await supabase.from('owned_tools').select('tool_id, level').eq('user_id', user.id);
    if (tools && tools.length > 0) {
      const toolMap: Record<string, number> = {};
      tools.forEach(t => toolMap[t.tool_id] = t.level);
      ownedTools.value = toolMap;
    }
    // Ensure default is always there
    if (!ownedTools.value['rusty_shovel']) {
      ownedTools.value['rusty_shovel'] = 1;
    }

    const { data: sets } = await supabase.from('completed_sets').select('set_id').eq('user_id', user.id);
    if (sets) completedSetIds.value = sets.map(s => s.set_id);

    // 5. Setup Realtime Subscription
    supabase.channel('game-state')
      .on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'profiles', filter: `id=eq.${user.id}` }, (payload) => {
        const newProfile = payload.new as any;
        console.log('[Store] Profile Update Received:', newProfile);
        scrapBalance.value = Number(newProfile.scrap_balance ?? 0);
        historicalInfluence.value = Number(newProfile.historical_influence ?? 0);
        trayCount.value = Number(newProfile.tray_count ?? 0);
        excavationXP.value = Number(newProfile.excavation_xp ?? 0);
        restorationXP.value = Number(newProfile.restoration_xp ?? 0);
        appraisalXP.value = Number(newProfile.appraisal_xp ?? 0);
        smeltingXP.value = Number(newProfile.smelting_xp ?? 0);
        activeToolId.value = newProfile.active_tool_id;
        overclockBonus.value = Number(newProfile.overclock_bonus ?? 0);
        lastExtractAt.value = newProfile.last_extract_at ? new Date(newProfile.last_extract_at) : lastExtractAt.value;
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'vault_items', filter: `user_id=eq.${user.id}` }, async (payload) => {
        // Refresh inventory on any change to be safe, or handle granularly
        if (payload.eventType === 'INSERT') {
          const newItem = payload.new as any;
          const def = catalog.value.find(d => d.id === newItem.item_id);
          // Manually join properties for UI
          const fullItem = { ...newItem, item: def, name: def?.name, tier: def?.tier, flavorText: def?.flavor_text };
          inventory.value.push(fullItem);
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
    if (isExtracting.value || isCooldown.value) return;
    isExtracting.value = true;
    surveyProgress.value = 0;

    // Initialize Seismic Surge
    const level = excavationLevel.value;
    const width = calculateSweetSpotWidth(level);
    const start = generateSweetSpotStart(width);
    const isMaster = level >= 99;

    seismicState.value = {
      isActive: true,
      config: {
        sweetSpotWidth: width,
        perfectZoneWidth: 30, // 30% of width
        sweetSpotStart: start
      },
      impactPos: 0,
      grades: [],
      maxStrikes: isMaster ? 2 : 1
    };

    addLog('Bio-Scanners initializing...');

    // 1. Survey Phase (Manual interaction) - Animate progress
    const steps = 50; // Higher resolution for smooth UI
    const totalDuration = surveyDurationMs.value;
    const stepDuration = totalDuration / steps;

    // Simulation loop
    let startTime = Date.now();

    // Check for user strikes during the duration
    // We use a polling loop here or just rely on CSS animation?
    // For the logic to be precise, we should track time.
    // However, existing loop sleeps. We can just update seismic state inside the loop.

    for (let i = 0; i <= steps; i++) {
      // Calculate progress 0-100
      const progress = (i / steps) * 100;
      surveyProgress.value = progress;

      // Update seismic impact position (sweep once 0 -> 100)
      seismicState.value.impactPos = progress;

      await new Promise(resolve => setTimeout(resolve, stepDuration));
    }

    // End Seismic Phase
    seismicState.value.isActive = false;

    try {
      // Collect grades
      // If no strike, grade is undefined (server treats as standard)
      // If multiple grades (Mastery), we might send array or just best?
      // RPC should probably handle 'grade' or 'grades'.
      // For simplicity/backward compat, let's determine the "effective" bonus grade or pass list.
      // Let's pass the raw grades array to RPC if multiple, or single if not.
      // The RPC migration plan said p_seismic_grade TEXT. 
      // Maybe we encode it: "HIT", "PERFECT", "HIT,PERFECT"

      const gradesStr = seismicState.value.grades.length > 0
        ? seismicState.value.grades.join(',')
        : null;

      // Note: We use the local userSessionId as a param if auth is NULL on server
      const { data, error } = await supabase.rpc('rpc_extract_v2', {
        p_user_id: userSessionId.value,
        p_seismic_grade: gradesStr
      });
      if (error) throw error;
      if (data.success) {
        if (data.result === 'ANOMALY') {
          addLog('⚠ ANOMALY DETECTED: Temporal instability recorded.');
        } else if (data.crate_dropped) {
          addLog('CRATE FOUND! Return to lab to analyze.');
        } else if (data.result === 'SCRAP_FOUND') {
          addLog(`Extraction complete. +${data.scrap_gain} Scrap.`);
        } else {
          addLog('Nothing found in this sector.');
        }

        if (data.double_loot) {
          addLog('MASTERY PERK: The Endless Vein doubled your yield!');
        }

        // Optimistic / Immediate Update
        console.log('[Store] Extraction Data Received:', data);

        const prevLevel = excavationLevel.value;
        scrapBalance.value = Number(data.new_balance ?? (scrapBalance.value + (data.scrap_gain || 0)));
        excavationXP.value = Number(data.new_xp ?? (excavationXP.value + (data.xp_gain || 0)));

        if (excavationLevel.value > prevLevel) {
          useMMOStore().addLocalNotification(`Excavation Level Up! (Level ${excavationLevel.value})`, 'success');
        }

        trayCount.value = Number(data.new_tray_count ?? (data.crate_dropped ? trayCount.value + 1 : trayCount.value));

        // Use local time for immediate cooldown to avoid server drift issues
        lastExtractAt.value = new Date();
      } else {
        addLog(`Error: ${data.error}`);
      }
    } catch (err: any) {
      addLog(`System Error: ${err.message}`);
    } finally {
      isExtracting.value = false;
      surveyProgress.value = 0;
      seismicState.value.isActive = false;
    }
  }

  function strike() {
    if (!isExtracting.value || !seismicState.value.isActive) return;
    if (seismicState.value.grades.length >= seismicState.value.maxStrikes) return;

    const grade = gradeStrike(seismicState.value.impactPos, seismicState.value.config);
    seismicState.value.grades.push(grade);

    // UI feedback can be handled in component via watching grades or returning result here
    return grade;
  }

  async function sift() {
    if (isExtracting.value || !labState.value.isActive) return;
    isExtracting.value = true;

    try {
      const { data, error } = await supabase.rpc('rpc_sift', { p_user_id: userSessionId.value });
      if (error) throw error;

      if (data.success) {
        if (data.outcome === 'SUCCESS') {
          addLog(`Sequence Success: Layer ${data.new_stage} stabilized.`);
          labState.value.currentStage = data.new_stage ?? (labState.value.currentStage + 1);
        } else if (data.outcome === 'SHATTERED') {
          addLog('⚠ CRITICAL FAILURE: Specimen shattered. Structural integrity lost.');
          labState.value.isActive = false;
          labState.value.currentStage = 0;
          trayCount.value = Number(trayCount.value || 0) - 1;
        } else if (data.outcome === 'ANOMALY') {
          addLog('⚠ TEMPORAL RIFT: Sifting process bypassed dimensional limits.');
        }

        if (data.xp_gain) {
          const prevLevel = restorationLevel.value;
          restorationXP.value = Number(restorationXP.value) + Number(data.xp_gain);
          if (restorationLevel.value > prevLevel) {
            useMMOStore().addLocalNotification(`Restoration Level Up! (Level ${restorationLevel.value})`, 'success');
          }
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
      // Using RPC for start sifting
      supabase.rpc('rpc_start_sifting', { p_user_id: userSessionId.value })
        .then(({ data, error }) => {
          if (error) {
            addLog(`Error activating lab: ${error.message}`);
          } else if (data && data.success) {
            labState.value.isActive = true;
            labState.value.currentStage = 0;
            addLog('Crate moved to Lab. Preparing for analysis.');
          } else {
            addLog(`Error activating lab: ${data?.error || 'Unknown error'}`);
          }
        });
    }
  }

  async function claim() {
    try {
      const { data, error } = await supabase.rpc('rpc_claim', { p_user_id: userSessionId.value });
      if (error) throw error;
      if (data.success) {
        const item = data.item;
        addLog(`ANALYSIS COMPLETE: Identified ${item.tier} item: ${item.name.toUpperCase()} #${item.mint_number}`);
        labState.value.isActive = false;
        labState.value.currentStage = 0;
        return item; // Return full item object
      } else {
        addLog(`Claim Error: ${data.error}`);
        return null;
      }
    } catch (err: any) {
      addLog(`Error: ${err.message}`);
      return null;
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
      p_hours: 24,
      p_user_id: userSessionId.value
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
    const prevLevel = appraisalLevel.value;
    appraisalXP.value += 50; // Optimistic update
    if (appraisalLevel.value > prevLevel) {
      useMMOStore().addLocalNotification(`Appraisal Level Up! (Level ${appraisalLevel.value})`, 'success');
    }
    return true; // Success
  }

  async function placeBid(listingId: string, amount: number) {
    if (scrapBalance.value < amount) return false;

    // Optimistic update
    const previousBalance = scrapBalance.value;
    scrapBalance.value -= amount;

    const { data, error } = await supabase.rpc('rpc_place_bid', {
      p_listing_id: listingId,
      p_amount: amount,
      p_user_id: userSessionId.value
    });

    if (error || !data?.success) {
      addLog(`Bid Error: ${error?.message || data?.error}`);
      scrapBalance.value = previousBalance; // Rollback
      return false;
    }

    addLog(`Bid placed: ${amount} scrap.`);
    const prevLevel = appraisalLevel.value;
    appraisalXP.value += 10; // Optimistic update
    if (appraisalLevel.value > prevLevel) {
      useMMOStore().addLocalNotification(`Appraisal Level Up! (Level ${appraisalLevel.value})`, 'success');
    }
    return true;
  }

  // Smelting Action
  async function smeltItem(vaultItemId: string) {
    const { data, error } = await supabase.rpc('rpc_smelt', {
      p_item_id: vaultItemId,
      p_user_id: userSessionId.value
    });

    if (error) {
      addLog(`Smelt Error: ${error.message}`);
      return;
    }

    if (data.success) {
      addLog(`SMELTING COMPLETE: Recycled item for ${data.scrap_gained} Scrap.`);
      const prevLevel = smeltingLevel.value;
      scrapBalance.value = Number(data.new_balance || (scrapBalance.value + data.scrap_gained));
      smeltingXP.value = Number(smeltingXP.value) + Number(data.xp_gained || 0);
      if (smeltingLevel.value > prevLevel) {
        useMMOStore().addLocalNotification(`Smelting Level Up! (Level ${smeltingLevel.value})`, 'success');
      }
      inventory.value = inventory.value.filter(i => i.id !== vaultItemId);
    } else {
      addLog(`Smelt Failed: ${data.error}`);
    }
  }

  // Other Actions
  async function upgradeTool(toolId: string, cost: number) {
    const { data, error } = await supabase.rpc('rpc_upgrade_tool', {
      p_tool_id: toolId,
      p_cost: cost,
      p_user_id: userSessionId.value
    });
    if (data?.success) {
      const newLevel = data.new_level || (getToolLevel(toolId) + 1);
      addLog(`Tool ${toolId.toUpperCase()} reached Level ${newLevel}`);
      ownedTools.value[toolId] = newLevel;
      activeToolId.value = toolId;

      // Sync balance manually as rpc_upgrade_tool returns success but doesn't return new_balance yet
      scrapBalance.value -= cost;

      startPassiveLoop();
    } else {
      addLog(`Upgrade Interrupted: ${error?.message || data?.error || 'System error'}`);
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
      useMMOStore().addLocalNotification(`Set Complete: '${setId}'${data.reward_scrap > 0 ? ' (+' + data.reward_scrap + ' Scrap)' : ''}`, 'success');
      // Refresh profile via subscription usually, but optimistic update helps UI
    } else {
      addLog(`Claim Failed: ${data.error}`);
    }
  }

  async function purchaseInfluenceItem(itemKey: string) {
    const { data, error } = await supabase.rpc('rpc_purchase_influence_item', {
      p_item_key: itemKey,
      p_user_id: userSessionId.value
    });

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
    const { data, error } = await supabase.rpc('rpc_overclock_tool', {
      p_tool_id: toolId,
      p_cost: cost,
      p_user_id: userSessionId.value
    });
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
    catalog,
    vaultItems, // backward compat
    activeListings,
    labState,
    log,
    isExtracting,
    excavationXP,
    restorationXP,
    appraisalXP,
    smeltingXP,
    activeToolId,
    ownedTools,
    completedSetIds,
    discoveredCount,
    uniqueItemsFound,
    excavationLevel,
    restorationLevel,
    appraisalLevel,
    smeltingLevel,
    cooldownMs,
    getToolLevel,
    getToolCost,
    extract,
    sift,
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
    smeltItem,
    overclockBonus,
    surveyDurationMs,
    surveyProgress,
    isCooldown,
    lastExtractAt,
    batteryCapacity,
    userSessionId,
    seismicState,
    strike
  };
});
