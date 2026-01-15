<script setup lang="ts">
import { useGameStore } from "@/stores/game";
const store = useGameStore();

const stabilityRates = ["90%", "75%", "50%", "25%", "10%"];
</script>

<template>
  <div class="panel-brutalist flex-1 flex flex-col min-h-[400px] gap-6">
    <div class="flex justify-between items-center border-b-2 border-white pb-4">
      <h2 class="text-2xl uppercase font-black text-brutalist-white">
        > THE LAB
      </h2>
      <div
        v-if="store.labState.isActive"
        class="px-3 py-1 bg-white text-black font-black uppercase text-sm"
      >
        Stage {{ store.labState.currentStage }}/5
      </div>
    </div>

    <div
      v-if="!store.labState.isActive"
      class="flex-1 flex flex-col items-center justify-center gap-6"
    >
      <div
        class="w-32 h-32 border-4 border-dashed border-gray-600 flex items-center justify-center text-gray-600"
      >
        <span class="text-center font-bold text-xs"
          >NO CRATE<br />DETECTED</span
        >
      </div>
      <button
        @click="store.startSifting()"
        :disabled="store.trayCount === 0"
        class="btn-brutalist text-xl px-12 py-4 disabled:border-gray-700 disabled:text-gray-700 disabled:bg-transparent"
      >
        LOAD CRATE FROM TRAY
      </button>
      <p class="text-xs text-gray-500 font-mono uppercase">
        Tray status: {{ store.trayCount }}/5 units stored
      </p>
    </div>

    <div v-else class="flex-1 flex flex-col gap-8">
      <!-- Crate Visualization -->
      <div class="flex-1 flex items-center justify-center gap-8">
        <div class="relative">
          <div
            class="w-48 h-48 border-4 border-white bg-zinc-900 flex items-center justify-center relative overflow-hidden"
          >
            <div
              class="absolute inset-0 opacity-20 bg-[url('https://www.transparenttextures.com/patterns/carbon-fibre.png')]"
            ></div>
            <div class="z-10 text-6xl">📦</div>
            <!-- Scanlines -->
            <div
              class="absolute inset-0 pointer-events-none bg-gradient-to-b from-transparent via-white/5 to-transparent h-2 w-full animate-[scan_2s_linear_infinite]"
            ></div>
          </div>
          <!-- Stability Badge -->
          <div
            class="absolute -top-4 -right-4 bg-brutalist-yellow text-black p-2 font-black border-2 border-white text-xs uppercase shadow-[4px_4px_0px_0px_rgba(255,255,255,1)]"
          >
            Stability: {{ stabilityRates[store.labState.currentStage] || "0%" }}
          </div>
        </div>

        <div class="flex flex-col gap-4 max-w-xs">
          <div class="p-4 bg-zinc-900 border-2 border-white text-xs font-mono">
            <p class="text-brutalist-green mb-2">
              SIGNAL_ANALYSIS: IN PROGRESS
            </p>
            <p
              v-if="store.labState.currentStage >= 3"
              class="text-brutalist-yellow font-bold"
            >
              WARNING: RARE SIGNATURE DETECTED
            </p>
            <p v-else>Current Tier Potential: COMMON</p>
          </div>
          <div class="flex flex-col gap-2">
            <button
              @click="store.sift()"
              class="btn-brutalist text-black bg-white hover:bg-brutalist-yellow"
            >
              SIFT (Stage {{ store.labState.currentStage + 1 }})
            </button>
            <button
              @click="store.claim()"
              class="btn-brutalist border-brutalist-green text-brutalist-green hover:bg-brutalist-green hover:text-black"
            >
              CLAIM CURRENT
            </button>
          </div>
        </div>
      </div>

      <!-- Warning Message -->
      <div
        class="p-4 bg-zinc-900 border border-white text-xs italic text-gray-400"
      >
        // Sifting increases rarity potential but risks complete structural
        failure. Failure will result in crate loss.
      </div>
    </div>
  </div>
</template>

<style scoped>
@keyframes scan {
  from {
    transform: translateY(-100%);
  }
  to {
    transform: translateY(500%);
  }
}
</style>
