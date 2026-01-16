<script setup lang="ts">
import { ref } from 'vue';
import { useGameStore } from '@/stores/game';
import { supabase } from '@/lib/supabase';

const store = useGameStore();
const isOpen = ref(false);
const isDev = import.meta.env.DEV;

// Only show in dev mode by default, or if force enabled
// const showDevTools = ref(isDev); 
const showDevTools = ref(true); // Always show for now as requested

async function addScrap(amount: number) {
  if (!store.userSessionId) return;
  const newBalance = store.scrapBalance + amount;
  
  // Optimistic update
  store.scrapBalance = newBalance;
  
  const { error } = await supabase
    .from('profiles')
    .update({ scrap_balance: newBalance })
    .eq('id', store.userSessionId);
    
  if (error) {
    console.error('DevTools: Failed to update scrap', error);
    store.addLog(`DEV ERROR: ${error.message}`);
  } else {
    store.addLog(`DEV: Added ${amount} Scrap`);
  }
}

async function addFineDust(amount: number) {
  if (!store.userSessionId) return;
  const newBalance = store.fineDustBalance + amount;
  
  store.fineDustBalance = newBalance;
  
  const { error } = await supabase
    .from('profiles')
    .update({ fine_dust_balance: newBalance })
    .eq('id', store.userSessionId);

  if (error) {
    console.error('DevTools: Failed to update dust', error);
  } else {
    store.addLog(`DEV: Added ${amount} Fine Dust`);
  }
}

async function addFragments(amount: number) {
  if (!store.userSessionId) return;
  const newBalance = store.cursedFragmentBalance + amount;
  
  store.cursedFragmentBalance = newBalance;
  
  const { error } = await supabase
    .from('profiles')
    .update({ cursed_fragment_balance: newBalance })
    .eq('id', store.userSessionId);

  if (error) {
    console.error('DevTools: Failed to update fragments', error);
  } else {
    store.addLog(`DEV: Added ${amount} Cursed Fragments`);
  }
}

async function addXP(amount: number) {
  if (!store.userSessionId) return;
  
  store.excavationXP += amount;
  store.restorationXP += amount;
  store.appraisalXP += amount;
  store.smeltingXP += amount;
  
  const { error } = await supabase
    .from('profiles')
    .update({
      excavation_xp: store.excavationXP,
      restoration_xp: store.restorationXP,
      appraisal_xp: store.appraisalXP,
      smelting_xp: store.smeltingXP
    })
    .eq('id', store.userSessionId);

  if (error) {
    console.error('DevTools: Failed to update XP', error);
  } else {
    store.addLog(`DEV: Added ${amount} XP to all skills`);
  }
}

function hardReset() {
  if (confirm('HARD RESET: This will clear your local identity and reload the page. You will generate a new user ID. Continue?')) {
    localStorage.clear();
    location.reload();
  }
}

function clearCrates() {
  store.crateTray = [];
  // Also try to update DB if possible, but crate_tray is complex jsonb, 
  // simplified update:
  if (store.userSessionId) {
     supabase.from('profiles').update({ crate_tray: [] }).eq('id', store.userSessionId).then(() => {
       store.addLog('DEV: Crate Tray Cleared');
     });
  }
}

async function forceSave() {
    // Just a dummy action to visually confirm
    store.addLog('DEV: Force Save initiated (Simulated)');
    await store.checkOfflineGains(); // Re-trigger offline gains check as a pseudo-sync
}

</script>

<template>
  <div v-if="showDevTools" class="fixed bottom-4 right-4 z-[9999] font-mono text-xs">
    
    <!-- Toggle Button -->
    <button 
      @click="isOpen = !isOpen"
      class="bg-red-600 text-white px-3 py-2 rounded shadow-lg hover:bg-red-700 transition-colors flex items-center gap-2 border-2 border-white"
    >
      <span>{{ isOpen ? 'CLOSE DEV' : 'DEV TOOLS' }}</span>
    </button>

    <!-- Panel -->
    <div v-if="isOpen" class="absolute bottom-12 right-0 w-64 bg-slate-900 text-slate-200 p-4 rounded-lg shadow-xl border border-slate-700 flex flex-col gap-4">
      
      <div class="border-b border-slate-700 pb-2">
        <h3 class="font-bold text-yellow-400">DEVELOPER OVERRIDE</h3>
        <p class="text-[10px] text-slate-400">ID: {{ store.userSessionId?.substring(0,8) }}...</p>
      </div>

      <div class="space-y-2">
        <div class="flex flex-col gap-1">
          <label class="text-[10px] uppercase text-slate-500">Resources</label>
          <button @click="addScrap(1000)" class="dev-btn">+1k Scrap</button>
          <button @click="addScrap(100000)" class="dev-btn">+100k Scrap</button>
          <button @click="addFineDust(1000)" class="dev-btn text-cyan-300 border-cyan-800 hover:bg-cyan-900">+1k Fine Dust</button>
          <button @click="addFragments(100)" class="dev-btn text-purple-300 border-purple-800 hover:bg-purple-900">+100 Fragments</button>
        </div>

        <div class="flex flex-col gap-1">
          <label class="text-[10px] uppercase text-slate-500">Progression</label>
          <button @click="addXP(1000)" class="dev-btn">+1k XP (All)</button>
          <button @click="addXP(50000)" class="dev-btn">+50k XP (All)</button>
        </div>

        <div class="flex flex-col gap-1">
          <label class="text-[10px] uppercase text-slate-500">State</label>
          <button @click="clearCrates()" class="dev-btn">Clear Crates</button>
          <button @click="forceSave()" class="dev-btn">Force Sync</button>
           <button @click="hardReset()" class="dev-btn bg-red-900/50 hover:bg-red-800 text-red-200 border-red-800">HARD RESET (New User)</button>
        </div>
      </div>

    </div>
  </div>
</template>

<style scoped>
.dev-btn {
  @apply w-full px-2 py-1 bg-slate-800 border border-slate-600 rounded text-left hover:bg-slate-700 transition-colors text-[10px];
}
</style>
