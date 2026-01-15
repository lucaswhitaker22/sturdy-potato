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
});

async function handleExtract() {
  if (store.isExtracting || store.isCooldown) return;
  store.extract();
}
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
      <div class="absolute top-6 left-6 z-20">
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

      <!-- Depth Flavor Display -->
      <div
        class="absolute top-6 right-6 text-right font-mono text-[10px] text-gray-400"
      >
        EST. DEPTH: 14.{{ Math.floor(store.excavationXP / 100) }}m<br />
        DENSITY: 87.2%
      </div>

      <!-- The Main Action Stamp -->
      <div class="relative z-10 my-12">
        <button
          @click="handleExtract"
          :disabled="
            store.isExtracting || store.isCooldown || store.trayCount >= 5
          "
          class="group relative inline-flex items-center justify-center focus:outline-none disabled:opacity-50 disabled:cursor-not-allowed transition-transform active:scale-95"
        >
          <!-- Red Ink Stamp Effect -->
          <div
            class="relative w-72 h-32 bg-[#FDFDF5] border-4 border-ink-black shadow-[12px_12px_0px_0px_rgba(0,0,0,1)] hover:shadow-[6px_6px_0px_0px_rgba(0,0,0,1)] hover:translate-x-1 hover:translate-y-1 transition-all flex flex-col items-center justify-center overflow-hidden"
            :class="
              store.isExtracting || store.isCooldown
                ? 'bg-gray-50 opacity-90'
                : 'bg-[#FFFFF0]'
            "
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
                store.isExtracting
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
                store.isExtracting
                  ? "ACCESSING SUB-LAYERS"
                  : store.isCooldown
                  ? "MECHANICAL RESET"
                  : "INITIATE BIO-SCAN"
              }}
            </span>

            <!-- Scanning Line Visual -->
            <div
              v-if="store.isExtracting"
              class="absolute top-0 left-0 w-full h-1 bg-stamp-blue/50 shadow-[0_0_10px_2px_rgba(43,76,126,0.3)] z-20"
              :style="{ top: `${store.surveyProgress}%` }"
            ></div>
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
            class="h-1.5 w-full bg-gray-100 border border-gray-200 overflow-hidden"
          >
            <div
              class="h-full bg-stamp-blue transition-all ease-linear"
              :style="{
                width: store.isExtracting
                  ? `${store.surveyProgress}%`
                  : store.isCooldown
                  ? '100%'
                  : '0%',
                opacity: store.isCooldown ? 0.3 : 1,
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

        <div class="mt-auto border-t border-gray-100 pt-4">
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
</style>
