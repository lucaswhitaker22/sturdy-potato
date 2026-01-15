<script setup lang="ts">
import { useGameStore } from "@/stores/game";
import { TOOL_CATALOG } from "@/constants/items";
import { computed, ref, onMounted, onUnmounted } from "vue";

const store = useGameStore();

const hasAutomation = computed(() => {
  const tool = TOOL_CATALOG.find((t) => t.id === store.activeToolId);
  return tool && tool.automationRate > 0;
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
  }, 100); // Update every 100ms for smooth-ish 10s bar
});

onUnmounted(() => {
  if (passiveAnimInterval) clearInterval(passiveAnimInterval);
});

// Local survey state
const inSurvey = ref(false);
const surveyComplete = ref(false);

async function handleExtract() {
  if (store.isExtracting || store.isCooldown || inSurvey.value) return;

  inSurvey.value = true;
  surveyComplete.value = false;

  // Animate survey bar
  setTimeout(() => {
    inSurvey.value = false;
    surveyComplete.value = true;
    store.extract();
  }, store.surveyDurationMs);
}
</script>

<template>
  <div
    class="flex-1 flex flex-col items-center justify-center min-h-[400px] gap-8 relative p-8"
  >
    <!-- Background: subtle graph paper grid handled by parent, but maybe a local border -->
    <div
      class="absolute inset-4 border-2 border-black opacity-10 pointer-events-none transform rotate-[0.5deg]"
    ></div>

    <!-- Status Header -->
    <div
      class="text-center z-10 relative bg-white px-6 py-4 shadow-sm border border-gray-200 transform -rotate-1 rotate-hover outline outline-2 outline-offset-2 outline-gray-100"
    >
      <h2
        class="text-xl mb-1 font-serif font-black tracking-widest text-ink-black uppercase border-b-2 border-black inline-block"
      >
        Field Report: SEC-07
      </h2>
      <p class="text-xs font-mono text-gray-600 mt-2">
        SURFACE STATUS:
        <span
          :class="
            store.isExtracting
              ? 'text-stamp-blue animate-pulse font-bold'
              : 'text-black'
          "
          >{{ store.isExtracting ? "SCANNING..." : "STABLE" }}</span
        >
      </p>
    </div>

    <!-- The Main Action Stamp -->
    <div class="relative z-10 my-8">
      <button
        @click="handleExtract"
        :disabled="
          store.isExtracting ||
          store.isCooldown ||
          inSurvey ||
          store.trayCount >= 5
        "
        class="group relative inline-flex items-center justify-center focus:outline-none disabled:opacity-50 disabled:cursor-not-allowed transition-transform active:scale-95"
      >
        <!-- Button Body (The Stamp Handle) -->
        <div
          class="relative w-64 h-24 bg-[#EBEBE0] border-4 border-ink-black shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] hover:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] hover:translate-x-1 hover:translate-y-1 transition-all flex items-center justify-center overflow-hidden"
          :class="
            store.isExtracting || inSurvey || store.isCooldown
              ? 'bg-gray-100'
              : 'bg-[#FFFFF0]'
          "
        >
          <!-- Highlighter Hover Effect -->
          <div
            class="absolute inset-0 bg-[#FFFF00] opacity-0 group-hover:opacity-20 transition-opacity mix-blend-multiply"
          ></div>

          <!-- Stamp Text -->
          <span
            class="font-black text-4xl tracking-widest text-ink-black uppercase transform group-hover:-rotate-2 transition-transform select-none font-serif"
          >
            {{
              inSurvey
                ? "SURVEYING"
                : store.isExtracting || store.isCooldown
                ? "COOLDOWN"
                : "[ EXTRACT ]"
            }}
          </span>
        </div>
      </button>
    </div>

    <!-- Progress Readout (Typed Style) -->
    <div
      class="w-full max-w-lg z-10 font-mono text-xs border-t border-b border-gray-300 py-4 bg-[#white]/50 flex flex-col gap-4"
    >
      <!-- Manual Gauge -->
      <div>
        <div class="flex justify-between mb-2 px-2">
          <span class="uppercase font-bold text-gray-600"
            >Bio-Scan Frequency:</span
          >
          <span class="bg-black text-white px-2">
            {{
              inSurvey
                ? "SURVEYING..."
                : store.isExtracting || store.isCooldown
                ? "COOLDOWN"
                : "STANDBY"
            }}
          </span>
        </div>

        <!-- Progress Bar (Ink Fill) -->
        <div class="w-full h-4 border-2 border-black bg-white relative">
          <!-- Ticks -->
          <div class="absolute inset-0 flex justify-between px-1">
            <div class="w-px h-full bg-gray-200"></div>
            <div class="w-px h-full bg-gray-200"></div>
            <div class="w-px h-full bg-gray-200"></div>
            <div class="w-px h-full bg-gray-200"></div>
          </div>
          <!-- Fill -->
          <div
            class="h-full bg-ink-black transition-all ease-linear relative"
            :style="{
              width: inSurvey
                ? '100%'
                : store.isExtracting || store.isCooldown
                ? '100%'
                : '0%',
              transitionDuration: inSurvey
                ? `${store.surveyDurationMs}ms`
                : store.isExtracting || store.isCooldown
                ? `${store.cooldownMs}ms`
                : '0ms',
            }"
          >
            <div
              class="absolute inset-0 opacity-50 bg-[url('https://www.transparenttextures.com/patterns/stardust.png')]"
            ></div>
          </div>
        </div>
      </div>

      <!-- Passive Gauge (Only if tool has automation) -->
      <div v-if="hasAutomation" class="opacity-80">
        <div class="flex justify-between mb-2 px-2">
          <span class="uppercase font-bold text-gray-500"
            >Auto-Digger Cycle:</span
          >
          <span class="text-gray-600 px-2 font-bold">{{
            passiveProgress === 0 ? "IDLE" : "ACTIVE"
          }}</span>
        </div>
        <div class="w-full h-2 border-2 border-gray-400 bg-white relative">
          <div
            class="h-full bg-gray-400 transition-all ease-linear relative"
            :style="{
              width: `${passiveProgress}%`,
              transitionDuration: '100ms',
            }"
          ></div>
        </div>
      </div>

      <div class="mt-2 text-center text-gray-700 italic">
        {{
          inSurvey
            ? ">> Calibrating tools..."
            : store.isExtracting || store.isCooldown
            ? ">> Writing data to disk..."
            : ">> System ready for input."
        }}
      </div>
    </div>

    <!-- Warning Note -->
    <div
      v-if="store.trayCount >= 5"
      class="mt-4 p-4 bg-[#FFEEEE] border-2 border-stamp-red text-stamp-red font-bold font-serif shadow-md transform rotate-1 absolute bottom-4 right-4 max-w-xs"
    >
      <div
        class="border-2 border-stamp-red rounded-full px-2 py-1 inline-block mb-1 text-xs transform -rotate-6"
      >
        URGENT
      </div>
      <p class="uppercase text-sm">
        Tray Capacity Reached. Return to Lab for Processing.
      </p>
    </div>
  </div>
</template>

<style scoped>
.rotate-hover:hover {
  transform: rotate(0deg);
  transition: transform 0.2s ease;
}
</style>
