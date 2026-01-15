import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { ITEM_CATALOG } from '@/constants/items';

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
    
    // Simulate Supabase RPC call for MVP (since we don't have a real Supabase URL yet)
    // In production, this would be: await supabase.rpc('rpc_extract')
    await new Promise(resolve => setTimeout(resolve, 3000));

    const roll = Math.random();
    if (roll < 0.2 && trayCount.value < 5) {
      trayCount.value++;
      addLog('CRATE IDENTIFIED. Sector 4-B.');
    } else if (roll < 0.9) {
      const gain = Math.floor(Math.random() * 11) + 5;
      scrapBalance.value += gain;
      addLog(`RECOVERED ${gain} UNITS OF SCRAP.`);
    } else {
      addLog('SECTOR DEPLETED. No materials found.');
    }

    isExtracting.value = false;
  }

  async function sift() {
    if (!labState.value.isActive) return;

    const successRates = [0.9, 0.75, 0.5, 0.25, 0.1];
    const rate = successRates[labState.value.currentStage] || 0;
    
    addLog('Sifting crate... stabilizing signal...');
    
    const roll = Math.random();
    if (roll < rate) {
      labState.value.currentStage++;
      addLog(`SIFT SUCCESSFUL. Stage ${labState.value.currentStage} reached.`);
    } else {
      labState.value.isActive = false;
      labState.value.currentStage = 0;
      trayCount.value--;
      addLog('CRITICAL INSTABILITY. Crate shattered.');
    }
  }

  async function claim() {
    if (!labState.value.isActive) return;

    const tier = labState.value.currentStage >= 3 ? 'rare' : 'common';
    const items = ITEM_CATALOG.filter(i => i.tier === tier);
    const item = items[Math.floor(Math.random() * items.length)];

    vaultItems.value.push(item.id);
    trayCount.value--;
    labState.value.isActive = false;
    labState.value.currentStage = 0;

    addLog(`ITEM RECOVERED: [${item.name.toUpperCase()}]`);
  }

  function startSifting() {
    if (trayCount.value > 0 && !labState.value.isActive) {
      labState.value.isActive = true;
      labState.value.currentStage = 0;
      addLog('Crate moved to Lab. Preparing for analysis.');
    }
  }

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
