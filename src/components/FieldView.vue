<script setup lang="ts">
import { useGameStore } from "@/stores/game";
import { TOOL_CATALOG } from "@/constants/items";
import { computed, ref, onMounted, onUnmounted } from "vue";

const store = useGameStore();

const activeTool = computed(() => {
  return TOOL_CATALOG.find((t) => t.id === store.activeToolId);
});

const hasAutomation = computed(() => {
  return activeTool.value && activeTool.value.automationRate > 0;
});

// Calculate Bonuses for display
const excavationBonus = computed(() => {
  return (Math.floor(store.excavationLevel / 5) * 0.5).toFixed(1);
});

const totalFindChance = computed(() => {
  const base = 15; // 15% base from rpc_extract
  const toolBonus = (activeTool.value?.findRateBonus || 0) * 100;
  const levelBonus = parseFloat(excavationBonus.value);
  return (base + toolBonus + levelBonus).toFixed(1);
});

// Passive Progress Bar (10s Tick)
const passiveProgress = ref(0);
let passiveAnimInterval: any = null;

onMounted(() => {
  window.addEventListener('keydown', handleKeydown);
  passiveAnimInterval = setInterval(() => {
    if (hasAutomation.value) {
      passiveProgress.value += 1;
      if (passiveProgress.value >= 100) {
        passiveProgress.value = 0;
      }
    } else {
      passiveProgress.value = 0;
    }
  }, 100);
});

onUnmounted(() => {
  if (passiveAnimInterval) clearInterval(passiveAnimInterval);
  window.removeEventListener('keydown', handleKeydown);
});

function handleKeydown(e: KeyboardEvent) {
  if (e.code === 'Space') {
    e.preventDefault(); // Prevent scrolling
    handleExtract(); // Trigger same logic as button
  }
}

const isShaking = ref(false);

  async function handleExtract() {
    // If extracting and seismic active, this is a strike
    if (store.isExtracting && store.seismicState.isActive) {
      handleStrike();
      return;
    }

    isShaking.value = true;
    setTimeout(() => (isShaking.value = false), 200);
    if (store.isExtracting || store.isCooldown) return;
    
    console.log('[FieldView] Starting extraction...');
    store.extract();
  }

  function handleStrike() {
    console.log('[FieldView] Strike attempt via UI');
    const grade = store.strike();
    if (grade) {
      console.log('[FieldView] Strike success:', grade);
      isShaking.value = true;
      setTimeout(() => (isShaking.value = false), 100);
    }
  }

  const lastGrade = computed(() => {
     if (store.seismicState.grades.length > 0) {
        return store.seismicState.grades[store.seismicState.grades.length - 1];
     }
     return null;
  });
</script>

<template>
  <div
    class="flex-1 flex flex-col md:flex-row h-full gap-4 overflow-hidden p-2"
  >
    <!-- Left Panel: The Dig Site -->
    <div
      class="flex-1 flex flex-col items-center justify-center p-8 relative rounded-sm border-2 border-black bg-white/50 sketch-bg"
    >
      <!-- Background Grid -->
      <div
        class="absolute inset-0 opacity-10 pointer-events-none grid-pattern"
      ></div>

      <!-- Surface Status Tag -->
      <div class="absolute top-6 left-6 z-20 flex gap-4 items-start">
        <div>
          <div
            class="bg-ink-black text-white px-3 py-1 font-mono text-[10px] tracking-tighter uppercase"
          >
            Sector Status: {{ store.isExtracting ? "SCANNING" : "IDLE" }}
          </div>
          <div class="mt-1 flex gap-1">
            <div
              v-for="i in 3"
              :key="i"
              class="w-1.5 h-1.5 rounded-full border border-black"
              :class="
                store.isExtracting && Date.now() % 1000 > i * 200
                  ? 'bg-stamp-blue'
                  : 'bg-transparent'
              "
            ></div>
          </div>
        </div>

        <!-- ZONE SELECTOR -->
        <div class="flex flex-col gap-1">
           <div class="flex gap-2 items-center">
             <select 
               v-model="store.activeZoneId" 
               @change="store.setZone(store.activeZoneId)"
               class="bg-white border-2 border-black text-[9px] font-mono px-2 py-1 uppercase outline-none focus:ring-2 focus:ring-stamp-blue"
             >
               <option value="industrial_zone">Industrial Zone</option>
               <option value="suburbs">Residential Suburbs</option>
               <option value="mall">Sunken Mall</option>
               <option value="sovereign_vault">Sovereign Vault</option>
             </select>

             <!-- Heatmap Chip -->
             <div 
               v-if="store.vaultHeatmaps[store.activeZoneId]"
               class="px-2 py-1 border border-black font-mono text-[8px] font-bold group relative cursor-help"
               :class="{
                 'bg-cyan-100 text-cyan-800': store.vaultHeatmaps[store.activeZoneId].tier === 'LOW',
                 'bg-orange-100 text-orange-800': store.vaultHeatmaps[store.activeZoneId].tier === 'MED',
                 'bg-red-500 text-white animate-pulse': store.vaultHeatmaps[store.activeZoneId].tier === 'HIGH'
               }"
             >
               STATIC: {{ store.vaultHeatmaps[store.activeZoneId].tier }}
               
               <!-- Tooltip -->
               <div class="hidden group-hover:block absolute left-0 top-full mt-2 w-48 bg-black text-white p-2 z-50 shadow-xl border border-white/20">
                 <p class="font-bold border-b border-white/20 mb-1">INTENSITY MODIFIERS:</p>
                 <div v-if="store.vaultHeatmaps[store.activeZoneId].tier === 'LOW'" class="text-[7px]">
                   • FIND RATE: +0%<br/>
                   • LAB STABILITY: BASE
                 </div>
                 <div v-else-if="store.vaultHeatmaps[store.activeZoneId].tier === 'MED'" class="text-[7px]">
                   • FIND RATE: +1% (STATIC)<br/>
                   • LAB STABILITY: -2.5% PENALTY
                 </div>
                 <div v-else-if="store.vaultHeatmaps[store.activeZoneId].tier === 'HIGH'" class="text-[7px]">
                   • FIND RATE: +2% (STATIC)<br/>
                   • LAB STABILITY: -5% PENALTY
                 </div>
               </div>
             </div>
           </div>

           <!-- Oracle Forecast -->
           <div v-if="store.appraisalLevel >= 99" class="mt-2 paper-card bg-black/5 border border-black/10 p-2 max-w-[150px]">
             <span class="block text-[7px] font-black uppercase text-black/40 mb-1 tracking-tighter">[ ORACLE FORECAST ]</span>
             <div class="flex flex-wrap gap-1">
               <span v-for="trend in (store.vaultHeatmaps[store.activeZoneId]?.trending || [])" 
                     :key="trend" 
                     class="text-[7px] font-mono bg-white px-1 border border-black/10">
                 {{ trend }}
               </span>
               <span v-if="!(store.vaultHeatmaps[store.activeZoneId]?.trending?.length)" class="text-[7px] italic text-black/30">Scanning trends...</span>
             </div>
           </div>
        </div>
      </div>

      <!-- Depth Flavor Display -->
      <div
        class="absolute top-6 right-6 text-right font-mono text-[10px] text-gray-400"
      >
        ACTIVE ZONE: {{ store.activeZoneId.replace('_', ' ').toUpperCase() }}<br />
        STATIC TIER: {{ store.vaultHeatmaps[store.activeZoneId]?.tier || '---' }}<br />
        DENSITY: 87.2%
      </div>

      <!-- The Main Action Stamp -->
      <div class="relative z-10 my-12">
        <button
          @click="handleExtract"
          :disabled="
            store.trayCount >= 5 || 
            (store.isExtracting ? !store.seismicState.isActive : store.isCooldown)
          "
          class="group relative inline-flex items-center justify-center focus:outline-none disabled:opacity-50 disabled:cursor-not-allowed transition-transform active:scale-95"
        >
          <!-- Red Ink Stamp Effect -->
          <div
            class="relative w-72 h-32 bg-[#FDFDF5] border-4 border-ink-black shadow-[12px_12px_0px_0px_rgba(0,0,0,1)] hover:shadow-[6px_6px_0px_0px_rgba(0,0,0,1)] hover:translate-x-1 hover:translate-y-1 transition-all flex flex-col items-center justify-center overflow-hidden"
            :class="[
              store.isExtracting || store.isCooldown
                ? 'bg-gray-50'
                : 'bg-[#FFFFF0]',
              isShaking && !store.reducedMotion ? 'animate-shake-mild' : '',
            ]"
          >
            <!-- Texture Layers -->
            <div
              class="absolute inset-0 opacity-10 bg-[url('https://www.transparenttextures.com/patterns/natural-paper.png')]"
            ></div>

            <div
              class="absolute inset-0 bg-[#FFFF00] opacity-0 group-hover:opacity-10 transition-opacity mix-blend-multiply"
            ></div>

            <!-- Main Label -->
            <span
              class="font-serif font-black text-5xl tracking-tighter text-ink-black uppercase transform group-hover:-rotate-1 transition-transform select-none"
            >
              {{
                store.isExtracting && store.seismicState.isActive
                   ? "STRIKE!" 
                   : store.isExtracting
                   ? "SURVEYING"
                   : store.isCooldown
                   ? "COOLDOWN"
                   : "[ EXTRACT ]"
              }}
            </span>

            <!-- Sub-label -->
            <span
              class="text-[10px] font-mono mt-2 tracking-widest text-gray-500 uppercase"
            >
              {{
                store.isExtracting && store.seismicState.isActive
                  ? "LOCK SIGNAL NOW"
                  : store.isExtracting
                  ? "ACCESSING SUB-LAYERS"
                  : store.isCooldown
                  ? "MECHANICAL RESET"
                  : "INITIATE BIO-SCAN"
              }}
            </span>

            <!-- Seismic Result Feedback Overlay -->
            <div v-if="store.isExtracting && lastGrade" class="absolute inset-0 flex items-center justify-center z-30 pointer-events-none">
                <span class="text-4xl font-black text-red-600 bg-white px-2 border-2 border-red-600 transform -rotate-12 shadow-xl">
                    {{ lastGrade === 'PERFECT' ? 'PERFECT SURVEY!' : lastGrade === 'HIT' ? 'SIGNAL LOCKED' : 'MISS' }}
                </span>
            </div>

            <!-- Scanning Line Visual -->
            <div
              v-if="store.isExtracting"
              class="absolute top-0 left-0 w-full h-1 bg-stamp-blue/50 shadow-[0_0_10px_2px_rgba(43,76,126,0.3)] z-20"
              :class="{ 'transition-none': store.reducedMotion }"
              :style="{ top: `${store.surveyProgress}%` }"
            ></div>

            <!-- Focused Survey Overlay -->
            <div v-if="!!store.isFocusedSurveyActive" class="absolute inset-0 pointer-events-none z-0 overflow-hidden">
                <div class="absolute inset-0 bg-blue-400/5 animate-pulse"></div>
                <div class="scanner-sweep"></div>
            </div>
          </div>
        </button>
      </div>

      <!-- Gauges & Progress -->
      <div class="w-full max-w-sm z-10 flex flex-col gap-6">
        <!-- Manual Gauge -->
        <div class="paper-section p-4 bg-white/80 border border-gray-200">
          <div class="flex justify-between items-end mb-2">
            <span
              class="uppercase font-bold text-[10px] text-gray-600 tracking-widest font-mono"
              >Field Scanner Freq.</span
            >
            <span class="text-[10px] font-mono text-gray-400">{{
              store.isExtracting
                ? store.surveyProgress.toFixed(0) + "%"
                : "READY"
            }}</span>
          </div>
          <div
            class="h-6 w-full bg-gray-100 border border-gray-200 overflow-hidden relative cursor-pointer"
            @click="store.strike()"
          >
            <!-- Seismic Overlay -->
            <template v-if="store.seismicState.isActive">
               <!-- Sweet Spots -->
               <div v-for="(spot, index) in store.seismicState.config.sweetSpots" :key="index"
                    class="absolute top-0 bottom-0 bg-yellow-200/50 border-x border-yellow-400"
                    :style="{ left: `${spot.start}%`, width: `${spot.width}%` }">
                   
                   <!-- Perfect Core (Center 30%) -->
                   <div class="absolute top-0 bottom-0 left-[35%] w-[30%] bg-green-200/60 border-x border-green-400">
                       <div class="absolute inset-0 flex items-center justify-center opacity-30 text-[6px] font-bold text-green-800">CORE</div>
                   </div>
               </div>
               
               <!-- Impact Line -->
               <div class="absolute top-0 bottom-0 w-0.5 bg-red-600 z-10"
                    :class="{ 'transition-none': store.reducedMotion }"
                    :style="{ left: `${store.seismicState.impactPos}%` }">
               </div>
            </template>

            <!-- Original Progress Bar (Background) -->
            <div
              class="h-full bg-stamp-blue transition-all ease-linear opacity-20"
              :style="{
                width: store.isExtracting
                  ? `${store.surveyProgress}%`
                  : store.isCooldown
                  ? '100%'
                  : '0%'
              }"
            ></div>
          </div>
          <div class="mt-2 text-[9px] font-mono text-gray-500 italic">
            {{
              store.isExtracting
                ? "> Detecting signal variance..."
                : store.isCooldown
                ? "> Cooling unit core..."
                : "> Input expected for sector 07."
            }}
          </div>
        </div>

        <!-- Passive Gauge -->
        <div
          v-if="hasAutomation"
          class="paper-section p-4 bg-white/80 border border-gray-200 border-dashed"
        >
          <div class="flex justify-between items-end mb-2">
            <span
              class="uppercase font-bold text-[10px] text-gray-500 tracking-widest font-mono"
              >Auto-Digger Cycle</span
            >
            <span class="text-[10px] font-mono text-gray-400">AUTONOMOUS</span>
          </div>
          <div
            class="h-1 w-full bg-gray-50 border border-gray-200 overflow-hidden"
          >
            <div
              class="h-full bg-gray-400 transition-all ease-linear"
              :style="{
                width: `${passiveProgress}%`,
                transitionDuration: '100ms',
              }"
            ></div>
          </div>
        </div>
      </div>

      <!-- Warning Note (Stuck on with tape) -->
      <transition name="fade">
        <div
          v-if="store.trayCount >= 5"
          class="absolute bottom-8 right-8 z-30 p-4 bg-yellow-100 border-2 border-yellow-300 shadow-lg transform rotate-2 max-w-[200px]"
        >
          <!-- Tape Visual -->
          <div
            class="absolute -top-3 left-1/2 -translate-x-1/2 w-10 h-6 bg-yellow-200/60 transform rotate-45 border-l border-r border-white/50"
          ></div>

          <div class="flex flex-col gap-1 items-center text-center">
            <span class="text-xl">⚠️</span>
            <span
              class="text-[10px] font-bold text-yellow-800 uppercase leading-none"
              >Tray Overload</span
            >
            <p class="text-[9px] text-yellow-700 mt-2 font-serif italic">
              System cannot store further specimens. Transfer to Laboratory
              immediately.
            </p>
          </div>
        </div>
      </transition>
    </div>

    <!-- Right Panel: Data Readout -->
    <div class="w-full md:w-64 flex flex-col gap-4">
      <!-- Equipment Specs Card -->
      <div
        class="flex-1 paper-card bg-white border-2 border-black p-4 flex flex-col gap-4 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
      >
        <div class="border-b border-black pb-1 mb-2">
          <span class="text-[10px] font-mono font-bold uppercase text-gray-400"
            >Spec Sheet</span
          >
          <h3 class="font-serif font-black text-sm uppercase">
            {{ activeTool?.name || "Manual Hands" }}
          </h3>
        </div>

        <div class="flex flex-col gap-3">
          <div class="spec-row">
            <span class="label">Efficiency</span>
            <span class="value">{{
              activeTool?.id === "rusty_shovel" ? "BASE" : "HIGH"
            }}</span>
          </div>
          <div class="spec-row">
            <span class="label">Sync Rate</span>
            <span class="value"
              >+{{
                (1000 / (store.surveyDurationMs / 1000)).toFixed(0)
              }}hz</span
            >
          </div>
          <div class="spec-row">
            <span class="label">Survey Gain</span>
            <span class="value">+{{ excavationBonus }}%</span>
          </div>
          <div class="spec-row highlight">
            <span class="label">Discovery Rate</span>
            <span class="value">{{ totalFindChance }}%</span>
          </div>
        </div>

        <div class="mt-auto border-t border-gray-100 pt-4 flex flex-col gap-2">
          <!-- TACTILE COMMANDS -->
          <div v-if="store.excavationLevel >= 60" class="flex flex-col gap-2">
            <button 
              @click="store.toggleFocusedSurvey()"
              class="w-full text-left px-3 py-2 border-2 border-black font-mono text-[9px] flex justify-between items-center transition-all"
              :class="store.isFocusedSurveyActive ? 'bg-blue-600 text-white shadow-none translate-x-1 translate-y-1' : 'bg-white text-black shadow-[3px_3px_0px_0px_rgba(0,0,0,1)] hover:shadow-none hover:translate-x-1 hover:translate-y-1'"
            >
              <span>[ FOCUSED SURVEY ]</span>
              <span>10S/s</span>
            </button>
            <button 
              v-if="store.excavationLevel >= 70"
              @click="store.performSurvey()"
              :disabled="!!(store.lastSurveyAt && (Date.now() - store.lastSurveyAt < 300000))"
              class="w-full text-left px-3 py-2 border-2 border-black font-mono text-[9px] flex justify-between items-center transition-all bg-white text-black shadow-[3px_3px_0px_0px_rgba(0,0,0,1)] hover:shadow-none hover:translate-x-1 hover:translate-y-1 disabled:opacity-50"
            >
              <span>[ PERFORM SURVEY ]</span>
              <span>100S</span>
            </button>
          </div>

          <p class="text-[10px] font-serif italic text-gray-500 leading-tight">
            "{{ activeTool?.flavorText }}"
          </p>
        </div>
      </div>

      <!-- Quick Tips / Lore Sticker -->
      <div
        class="bg-blue-50 border border-blue-200 p-3 text-[9px] text-blue-800 leading-tight font-mono"
      >
        <span class="font-bold block mb-1">PRO-TIP:</span>
        Leveling your Excavation skill increases the probability of finding
        crates. Every 5 levels grants a static +0.5% boost.
      </div>

      <!-- Settings Panel -->
      <div class="mt-4 p-3 bg-gray-50 border border-gray-200 font-mono text-[9px] flex flex-col gap-2">
        <div class="flex justify-between items-center">
          <span>SEISMIC SURGE</span>
          <button @click="store.seismicEnabled = !store.seismicEnabled" 
                  class="px-2 py-0.5 border border-black"
                  :class="store.seismicEnabled ? 'bg-green-100' : 'bg-red-100'">
            {{ store.seismicEnabled ? 'ENABLED' : 'DISABLED' }}
          </button>
        </div>
        <div class="flex justify-between items-center">
          <span>REDUCED MOTION</span>
          <button @click="store.reducedMotion = !store.reducedMotion" 
                  class="px-2 py-0.5 border border-black"
                  :class="store.reducedMotion ? 'bg-blue-100' : 'bg-gray-100'">
            {{ store.reducedMotion ? 'ON' : 'OFF' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.sketch-bg {
  background-color: #fdfdfb;
}

.grid-pattern {
  background-image: linear-gradient(#000 0.5px, transparent 0.5px),
    linear-gradient(90deg, #000 0.5px, transparent 0.5px);
  background-size: 20px 20px;
}

.spec-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-family: monospace;
}

.spec-row .label {
  text-transform: uppercase;
  font-size: 9px;
  font-weight: bold;
  color: #666;
}

.spec-row .value {
  font-weight: bold;
  font-size: 10px;
}

.spec-row.highlight .value {
  color: #2b4c7e;
  text-decoration: underline;
  text-decoration-thickness: 1.5px;
}

.rotate-hover:hover {
  transform: rotate(0deg);
  transition: transform 0.2s ease;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease, transform 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(10px) rotate(2deg);
}

.scanner-sweep {
  width: 100%;
  height: 2px;
  background: rgba(43, 76, 126, 0.4);
  position: absolute;
  top: 0;
  animation: sweep 2s linear infinite;
  box-shadow: 0 0 15px rgba(43, 76, 126, 0.6);
}

@keyframes sweep {
  0% { top: 0% }
  100% { top: 100% }
}
</style>
