import { defineStore } from 'pinia';
import { ref, computed, watch } from 'vue';
import { ITEM_CATALOG } from '@/constants/items';
import { supabase } from '@/lib/supabase';

export interface GameState {
  scrapBalance: number;
  trayCount: number;
  vaultItems: string[]; // List of item IDs
  labState: {
    isActive: boolean;
    currentStage: number;
  };
  log: string[];
  excavationXP: number;
  restorationXP: number;
  activeToolId: string;
  ownedToolIds: string[];
  completedSetIds: string[];
}

// Level calculation: Each level requires 100 * level XP
const getLevel = (xp: number) => Math.floor(xp / 100) + 1;

export const useGameStore = defineStore('game', () => {
  // State
  const scrapBalance = ref(0);
  const trayCount = ref(0);
  const vaultItems = ref<string[]>([]);
  const labState = ref({
    isActive: false,
    currentStage: 0,
  });
  const log = ref<string[]>(['> Connection established.', '> Initializing bio-scanner...']);
  const isExtracting = ref(false);
  const excavationXP = ref(0);
  const restorationXP = ref(0);
  const activeToolId = ref('rusty_shovel');
  const ownedToolIds = ref<string[]>(['rusty_shovel']);
  const completedSetIds = ref<string[]>([]);

  // Getters
  const discoveredCount = computed(() => vaultItems.value.length);
  const uniqueItemsFound = computed(() => new Set(vaultItems.value).size);
  const excavationLevel = computed(() => getLevel(excavationXP.value));
  const restorationLevel = computed(() => getLevel(restorationXP.value));

  // Actions
  function addLog(message: string) {
    log.value.unshift(`> ${message}`);
    if (log.value.length > 50) log.value.pop();
  }

  async function extract() {
    if (isExtracting.value) return;
    isExtracting.value = true;
    
    addLog('Extracting...');
    
    try {
      const { data, error } = await supabase.rpc('rpc_extract');
      
      if (error) throw error;

      if (data.success) {
        if (data.crate_dropped) {
          trayCount.value = data.new_tray_count;
          excavationXP.value = data.new_xp;
          addLog('CRATE IDENTIFIED. Sector 4-B.');
        } else if (data.result === 'SCRAP_FOUND') {
          scrapBalance.value = data.new_balance;
          excavationXP.value = data.new_xp;
          addLog(`RECOVERED ${data.scrap_gain} UNITS OF SCRAP.`);
        } else {
          excavationXP.value = data.new_xp;
          addLog('SECTOR DEPLETED. No materials found.');
        }
      }
    } catch (e) {
      console.warn('Supabase RPC failed, using mocked logic', e);
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      const roll = Math.random();
      if (roll < 0.1) {
        if (trayCount.value < 5) {
          trayCount.value++;
          addLog('CRATE OBTAINED. Signature verified.');
        } else {
          addLog('CRATE DETECTED but Tray is at capacity.');
        }
      } else {
        scrapBalance.value += 10;
        addLog('RECOVERED 10 UNITS OF SCRAP.');
      }
      excavationXP.value += 5;
    }

    isExtracting.value = false;
  }

  async function sift() {
    if (!labState.value.isActive) return;
    addLog('Sifting crate... stabilizing signal...');

    try {
      const { data, error } = await supabase.rpc('rpc_sift');
      if (error) throw error;

      if (data.outcome === 'SUCCESS') {
        labState.value.currentStage = data.new_stage;
        restorationXP.value = data.new_restoration_xp || restorationXP.value;
        addLog(`SIFT SUCCESSFUL. Stage ${data.new_stage} reached.`);
      } else {
        labState.value.isActive = false;
        labState.value.currentStage = 0;
        trayCount.value--;
        scrapBalance.value += 3;
        addLog('CRITICAL INSTABILITY. Crate shattered. Recovered 3 scrap fragments.');
      }
    } catch (e) {
      console.warn('Supabase RPC failed, using mocked logic', e);
      const successRates = [0.9, 0.75, 0.5, 0.25, 0.1];
      const rate = successRates[labState.value.currentStage] || 0;
      const roll = Math.random();
      if (roll < rate) {
        labState.value.currentStage++;
        restorationXP.value += 10;
        addLog(`(MOCK) SIFT SUCCESSFUL. Stage ${labState.value.currentStage} reached.`);
      } else {
        labState.value.isActive = false;
        labState.value.currentStage = 0;
        trayCount.value--;
        scrapBalance.value += 3;
        addLog('(MOCK) CRITICAL INSTABILITY. Crate shattered. Recovered 3 scrap fragments.');
      }
    }
  }

  async function claim() {
    if (!labState.value.isActive) return;

    try {
      const { data, error } = await supabase.rpc('rpc_claim');
      if (error) throw error;

      if (data.success) {
        vaultItems.value.push(data.item_id);
        const item = ITEM_CATALOG.find(i => i.id === data.item_id);
        trayCount.value--;
        labState.value.isActive = false;
        labState.value.currentStage = 0;
        addLog(`ITEM RECOVERED: [${item?.name.toUpperCase() || 'UNKNOWN'}]`);
      }
    } catch (e) {
      console.warn('Supabase RPC failed, using mocked logic', e);
      const roll = Math.random();
      if (roll < 0.1) {
        trayCount.value--;
        labState.value.isActive = false;
        labState.value.currentStage = 0;
        addLog('ANALYSIS COMPLETE: Content identified as [UNALIGNED JUNK]. Discarded.');
      } else {
        const tier = labState.value.currentStage >= 3 ? 'rare' : 'common';
        const items = ITEM_CATALOG.filter(i => i.tier === tier);
        const item = items[Math.floor(Math.random() * items.length)];

        vaultItems.value.push(item.id);
        trayCount.value--;
        labState.value.isActive = false;
        labState.value.currentStage = 0;
        addLog(`ITEM RECOVERED: [${item.name.toUpperCase()}]`);
      }
    }
  }

  async function upgradeTool(toolId: string, cost: number) {
    try {
      const { data, error } = await supabase.rpc('rpc_upgrade_tool', { p_tool_id: toolId, p_cost: cost });
      if (error) throw error;
      if (data.success) {
        scrapBalance.value -= cost;
        activeToolId.value = toolId;
        if (!ownedToolIds.value.includes(toolId)) {
          ownedToolIds.value.push(toolId);
        }
        addLog(`TOOL UPGRADED: ${toolId.toUpperCase()}. Efficiency increased.`);
      }
    } catch (e) {
      console.warn('Upgrade RPC failed, using mock', e);
      if (scrapBalance.value >= cost) {
        scrapBalance.value -= cost;
        activeToolId.value = toolId;
        if (!ownedToolIds.value.includes(toolId)) {
          ownedToolIds.value.push(toolId);
        }
        addLog(`(MOCK) TOOL UPGRADED: ${toolId.toUpperCase()}.`);
      }
    }
  }

  async function claimSet(setId: string, reward: number) {
    if (completedSetIds.value.includes(setId)) return;
    completedSetIds.value.push(setId);
    scrapBalance.value += reward;
    addLog(`COLLECTION COMPLETE: Reward ${reward} units.`);
  }

  function startSifting() {
    if (trayCount.value > 0 && !labState.value.isActive) {
      labState.value.isActive = true;
      labState.value.currentStage = 0;
      addLog('Crate moved to Lab. Preparing for analysis.');
    }
  }

  // Persistence
  const STORAGE_KEY = 'relic_vault_state';
  function loadPersistedState() {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved) {
      const parsed = JSON.parse(saved);
      scrapBalance.value = parsed.scrapBalance || 0;
      trayCount.value = parsed.trayCount || 0;
      vaultItems.value = parsed.vaultItems || [];
      excavationXP.value = parsed.excavationXP || 0;
      restorationXP.value = parsed.restorationXP || 0;
      activeToolId.value = parsed.activeToolId || 'rusty_shovel';
      ownedToolIds.value = parsed.ownedToolIds || ['rusty_shovel'];
      completedSetIds.value = parsed.completedSetIds || [];
    }
  }

  watch([scrapBalance, trayCount, vaultItems, excavationXP, restorationXP, activeToolId, ownedToolIds, completedSetIds], () => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({
      scrapBalance: scrapBalance.value,
      trayCount: trayCount.value,
      vaultItems: vaultItems.value,
      excavationXP: excavationXP.value,
      restorationXP: restorationXP.value,
      activeToolId: activeToolId.value,
      ownedToolIds: ownedToolIds.value,
      completedSetIds: completedSetIds.value
    }));
  }, { deep: true });

  loadPersistedState();

  return {
    scrapBalance,
    trayCount,
    vaultItems,
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
    extract,
    sift,
    claim,
    upgradeTool,
    claimSet,
    startSifting,
    addLog
  };
});
