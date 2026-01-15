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
}

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

  // Getters
  const discoveredCount = computed(() => vaultItems.value.length);
  const uniqueItemsFound = computed(() => new Set(vaultItems.value).size);

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
          addLog('CRATE IDENTIFIED. Sector 4-B.');
        } else if (data.result === 'SCRAP_FOUND') {
          scrapBalance.value = data.new_balance;
          addLog(`RECOVERED ${data.scrap_gain} UNITS OF SCRAP.`);
        } else {
          addLog('SECTOR DEPLETED. No materials found.');
        }
      }
    } catch (e) {
      // Fallback for local dev/testing without active Supabase
      console.warn('Supabase RPC failed, using mocked logic', e);
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      const roll = Math.random();
      if (roll < 0.1) { // 10% Crate
        if (trayCount.value < 5) {
          trayCount.value++;
          addLog('CRATE OBTAINED. Signature verified.');
        } else {
          addLog('CRATE DETECTED but Tray is at capacity.');
        }
      } else { // 90% Scrap (+10)
        scrapBalance.value += 10;
        addLog('RECOVERED 10 UNITS OF SCRAP.');
      }
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
        addLog(`SIFT SUCCESSFUL. Stage ${data.new_stage} reached.`);
      } else {
        labState.value.isActive = false;
        labState.value.currentStage = 0;
        trayCount.value--;
        scrapBalance.value += 3; // +3 Scrap on shatter
        addLog('CRITICAL INSTABILITY. Crate shattered. Recovered 3 scrap fragments.');
      }
    } catch (e) {
      console.warn('Supabase RPC failed, using mocked logic', e);
      const successRates = [0.9, 0.75, 0.5, 0.25, 0.1];
      const rate = successRates[labState.value.currentStage] || 0;
      const roll = Math.random();
      if (roll < rate) {
        labState.value.currentStage++;
        addLog(`(MOCK) SIFT SUCCESSFUL. Stage ${labState.value.currentStage} reached.`);
      } else {
        labState.value.isActive = false;
        labState.value.currentStage = 0;
        trayCount.value--;
        scrapBalance.value += 3; // +3 Scrap on shatter
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
      if (roll < 0.1) { // 10% Junk chance
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
    }
  }

  watch([scrapBalance, trayCount, vaultItems], () => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({
      scrapBalance: scrapBalance.value,
      trayCount: trayCount.value,
      vaultItems: vaultItems.value
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
    discoveredCount,
    uniqueItemsFound,
    extract,
    sift,
    claim,
    startSifting,
    addLog
  };
});
