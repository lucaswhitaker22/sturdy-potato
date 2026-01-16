<script setup lang="ts">
import { useGameStore } from "@/stores/game";
import { computed, ref, onMounted, onUnmounted } from "vue";
import { audio } from "@/services/audio";
const store = useGameStore();

const currentStability = computed(() => {
  const stage = store.labState.currentStage;
  // Visual only - server authority
  let base = 0;
  if (stage === 0) base = 90;
  else if (stage === 1) base = 75;
  else if (stage === 2) base = 50;
  else if (stage === 3) base = 25;
  else if (stage === 4) base = 10;

  const bonus = store.restorationLevel * 0.1 + store.overclockBonus * 100;
  return (base + bonus).toFixed(1) + "%";
});

// Active Stabilization State
const isActiveStabilizing = ref(false);
const needlePos = ref(50); // 0-100
const tetherCount = ref(0);
const isStopped = ref(false);
const swingDirection = ref(1);

// Animation
let animationFrame = 0;
let lastTime = 0;

// Zone Configuration (Danger Zones at edges)
// Safe Zone center, Danger edges? OR Danger specific spots?
// Doc: "Danger Zone: overheated range." Usually implies high swing areas.
// Let's say Danger is 0-20 and 80-100? Or just > 80?
// Simple implementation: Safe 20-80, Danger 0-20 & 80-100.
function getZone(pos: number) {
  if (pos < 20 || pos > 80) return 1; // Danger
  return 0; // Safe
}

const zoneStatus = computed(() => {
  if (getZone(needlePos.value) === 1) return { label: 'DANGER', color: 'text-red-500' };
  return { label: 'SAFE', color: 'text-green-500' };
});

const tetherCost = computed(() => store.getTetherCost(store.labState.currentStage));
const tetherCap = computed(() => store.getTetherCap(store.labState.currentStage));
const canTether = computed(() => {
  return !isStopped.value && 
         store.fineDustBalance >= tetherCost.value && 
         tetherCount.value < tetherCap.value;
});

function startStabilization() {
  if (store.isExtracting) return;
  isActiveStabilizing.value = true;
  isStopped.value = false;
  tetherCount.value = 0;
  needlePos.value = 50;
  swingDirection.value = Math.random() > 0.5 ? 1 : -1;
  lastTime = performance.now();
  animate();
}

function animate() {
  if (!isActiveStabilizing.value || isStopped.value) return;

  const now = performance.now();
  const delta = (now - lastTime) / 1000;
  lastTime = now;

  // Swing Logic
  // Base Speed increases with Stage?
  const stage = store.labState.currentStage;
  let speed = 40 + (stage * 10); // 40-90 units/sec
  
  // Tether Slowdown (20% per tether? Doc says time window?
  // "Slows needle movement for a short window."
  // Simplified: Permanent slow for this sift?
  // Doc 2.6: "Slows needle movement for a short window... Grants cooling buffer."
  // If I implement "short window", I need timers.
  // For simplicity MVP: Tethers apply a slowdown for the duration of the sift (or 2s).
  // Let's apply speed reduction per tether count permanently for the sift action.
  // 10% slow per tether.
  if (tetherCount.value > 0) {
    speed *= Math.pow(0.8, tetherCount.value); 
  }

  // Master Preserver Synergy (Level 99): 10% base reduction
  if (store.restorationLevel >= 99) {
    speed *= 0.9;
  }

  // Update Pos
  needlePos.value += speed * delta * swingDirection.value;

  // Bounce
  if (needlePos.value >= 100) {
    needlePos.value = 100;
    swingDirection.value = -1;
  } else if (needlePos.value <= 0) {
    needlePos.value = 0;
    swingDirection.value = 1;
  }

  animationFrame = requestAnimationFrame(animate);
}

function handleTether() {
  if (!canTether.value) return;
  // Optimistic update
  store.fineDustBalance -= tetherCost.value; 
  tetherCount.value++;
  // Visual effect
  audio.playClick('light');
}

async function handleForceStop() {
  if (isStopped.value) return;
  isStopped.value = true;
  cancelAnimationFrame(animationFrame);
  
  // Determine Zone
  const zone = getZone(needlePos.value);
  
  audio.playClick('heavy');
  await store.sift(tetherCount.value, zone);
  
  // Reset after short delay
  setTimeout(() => {
    isActiveStabilizing.value = false;
    isStopped.value = false;
  }, 1000);
}

// Keyboard Support
function handleKeyDown(e: KeyboardEvent) {
  if (!isActiveStabilizing.value || isStopped.value) return;
  
  const key = e.key.toLowerCase();
  if (key === ' ' || key === 't') {
    e.preventDefault();
    handleTether();
  } else if (key === 'enter' || key === 's') {
    e.preventDefault();
    handleForceStop();
  }
}

onMounted(() => {
  window.addEventListener('keydown', handleKeyDown);
});

onUnmounted(() => {
  cancelAnimationFrame(animationFrame);
  window.removeEventListener('keydown', handleKeyDown);
});

const revealedItem = ref<any>(null); // Legacy support

async function handleClaim() {
  if (store.isExtracting) return;
  const result = await store.claim();
  if (result) {
    audio.playCompletion((result.tier?.toLowerCase() || "common") as any);
    revealedItem.value = result;
  }
}
</script>

<template>
  <div class="flex-1 flex flex-col min-h-[400px] gap-6 p-4">
    <!-- Results Overlay -->
    <div 
      v-if="revealedItem"
      class="absolute inset-0 z-50 flex items-center justify-center p-8 bg-black/80 backdrop-blur-sm"
    >
      <div class="bg-white border-4 border-black p-6 shadow-[8px_8px_0_0_rgba(0,0,0,1)] max-w-sm w-full">
         <div class="text-xs font-mono text-gray-400 mb-2 uppercase tracking-widest">Analysis Result</div>
         <h3 class="text-3xl font-serif font-black mb-1 uppercase">{{ revealedItem.name }}</h3>
         <div class="inline-block px-2 py-0.5 bg-black text-white text-[10px] font-mono mb-4 uppercase">
            {{ revealedItem.tier }}
         </div>
         <p class="text-sm font-serif italic text-gray-600 mb-6">"{{ revealedItem.flavor_text }}"</p>
         
         <button 
           @click="revealedItem = null"
           class="w-full py-3 bg-black text-white font-mono font-bold hover:bg-gray-800 transition-all"
         >
           [ACKNOWLEDGE]
         </button>
      </div>
    </div>

    <!-- Header -->
    <div
      class="flex justify-between items-center border-b-2 border-black pb-2 form-line"
    >
      <div class="flex flex-col">
        <h2 class="text-2xl font-serif font-black text-ink-black uppercase tracking-tight">
          Analysis Lab
        </h2>
         <div class="text-xs font-mono text-gray-600 flex gap-2">
            <span>FINE DUST: {{ store.fineDustBalance }}mg</span>
         </div>
      </div>
     
      <div
        v-if="store.labState.isActive"
        class="px-2 py-1 font-mono text-xs border border-black bg-white shadow-[2px_2px_0_0_rgba(0,0,0,1)]"
      >
        SEQUENCE: {{ store.labState.currentStage }}/5
      </div>
    </div>

    <!-- Empty State -->
    <div
      v-if="!store.labState.isActive"
      class="flex-1 flex flex-col items-center justify-center p-8 border-2 border-dashed border-gray-300 rounded-lg bg-gray-50"
    >
      <div class="text-4xl mb-4 opacity-20">🔬</div>
      <p class="text-gray-500 font-serif italic mb-4">No active specimen.</p>
      
      <div v-if="store.trayCount > 0">
         <button
          @click="store.startSifting()"
          class="px-6 py-2 bg-black text-white font-mono hover:bg-gray-800 transition-all shadow-[4px_4px_0_0_rgba(0,0,0,0.2)] active:translate-y-1 active:shadow-none"
        >
          [INITIATE_SCAN]
        </button>
      </div>
       <div v-else class="text-sm font-mono text-red-500">
          [CRATE_REQUIRED]
      </div>
    </div>

    <!-- Active State -->
    <div v-else class="flex-1 flex flex-col items-center justify-between py-4">
      
      <!-- Stability Core Info -->
      <div class="w-full flex justify-between items-end px-4 mb-4">
         <div class="flex flex-col">
            <span class="text-xs font-mono text-gray-500 uppercase">Structural Integrity</span>
            <span class="text-3xl font-black font-mono tracking-tighter">{{ currentStability }}</span>
         </div>
         <div class="flex flex-col items-end">
             <span class="text-xs font-mono text-gray-500 uppercase">Risk Assessment</span>
             <span :class="['text-sm font-black font-mono', zoneStatus.color]">
                {{ isActiveStabilizing ? zoneStatus.label : 'WAITING' }}
             </span>
         </div>
      </div>

      <!-- Stability Gauge -->
      <div class="relative w-full h-16 bg-gray-200 border-2 border-black mb-6 overflow-hidden">
         <!-- Zones -->
         <div class="absolute inset-0 flex h-full w-full">
            <div class="h-full w-[20%] bg-red-100 border-r border-red-200 opacity-50 relative">
                 <div class="absolute bottom-1 left-1 text-[10px] font-mono text-red-500 font-bold">DANGER</div>
            </div>
            <div class="h-full w-[60%] bg-green-50 opacity-50 relative flex justify-center">
                 <div class="absolute bottom-1 text-[10px] font-mono text-green-600 font-bold">SAFE</div>
            </div>
            <div class="h-full w-[20%] bg-red-100 border-l border-red-200 opacity-50 relative">
                  <div class="absolute bottom-1 right-1 text-[10px] font-mono text-red-500 font-bold">DANGER</div>
            </div>
         </div>

         <!-- Needle -->
         <div 
            class="absolute top-0 bottom-0 w-1 bg-black z-10 transition-transform duration-75"
            :style="{ left: `${needlePos}%` }"
         >
            <div class="absolute -top-1 -left-1.5 w-4 h-4 bg-black rounded-full"></div>
         </div>
      </div>

      <!-- Controls -->
      <div class="w-full grid grid-cols-2 gap-4" v-if="isActiveStabilizing">
          <!-- Tether -->
          <button
            @click="handleTether"
            :disabled="!canTether"
            class="flex flex-col items-center justify-center p-4 border-2 border-dashed border-gray-400 font-mono transition-all hover:bg-blue-50 active:bg-blue-100 disabled:opacity-50 disabled:cursor-not-allowed group"
          >
             <span class="text-lg font-bold group-hover:scale-105 transition-transform">[TETHER]</span>
             <span class="text-xs text-blue-600 font-bold mt-1">-{{ tetherCost }}mg Dust</span>
             <span class="text-[10px] text-gray-400 mt-1">{{ tetherCount }} / {{ tetherCap }} Active</span>
          </button>
          
          <!-- Force Stop -->
            <button
            @click="handleForceStop"
            class="flex flex-col items-center justify-center p-4 border-2 border-black bg-red-50 font-mono hover:bg-red-100 active:bg-red-200 shadow-[4px_4px_0_0_rgba(0,0,0,1)] active:translate-y-1 active:shadow-none transition-all"
          >
             <span class="text-xl font-black text-red-600 animate-pulse">[FORCE STOP]</span>
             <span class="text-xs font-bold mt-1">COMMIT STAGE</span>
          </button>
      </div>

      <!-- Initial Start Button & Claim -->
      <div class="w-full px-8 flex flex-col gap-4" v-else>
         <button
            v-if="store.labState.currentStage < 5"
            @click="startStabilization"
            class="w-full py-6 bg-black text-white font-mono text-xl font-bold hover:bg-gray-800 shadow-[4px_4px_0_0_rgba(0,0,0,0.2)] active:translate-y-1 active:shadow-none transition-all"
         >
            [BEGIN STABILIZATION]
         </button>

         <button
           @click="handleClaim"
           class="w-full py-3 border-2 border-black font-mono text-sm font-bold hover:bg-gray-100 transition-all shadow-[2px_2px_0_0_rgba(0,0,0,1)] active:translate-y-1 active:shadow-none bg-white"
         >
           [CLAIM SPECIMEN @ STAGE {{ store.labState.currentStage }}]
         </button>
      </div>
      
      <!-- Info Footer -->
      <div class="mt-4 text-[10px] font-mono text-gray-400 text-center max-w-[80%]">
         Secure the needle in the SAFE ZONE to minimize failure risk. Use TETHERS to slow fluctuations.
      </div>
      
    </div>
  </div>
</template>
