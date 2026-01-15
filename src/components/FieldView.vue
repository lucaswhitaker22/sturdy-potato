<script setup lang="ts">
import { useGameStore } from "@/stores/game";
const store = useGameStore();
</script>

<template>
  <div
    class="panel-brutalist flex-1 flex flex-col items-center justify-center min-h-[400px] gap-8 relative overflow-hidden group"
  >
    <!-- Flickering CRT Overlay -->
    <div
      class="absolute inset-0 pointer-events-none opacity-[0.03] bg-[url('https://www.transparenttextures.com/patterns/carbon-fibre.png')] z-20"
    ></div>
    <div
      class="absolute inset-0 pointer-events-none z-20 animate-[pulse_4s_infinite] bg-gradient-to-b from-transparent via-white/5 to-transparent h-1 opacity-20"
    ></div>

    <div
      class="absolute inset-0 opacity-10 pointer-events-none"
      style="
        background-image: radial-gradient(#fff 1px, transparent 1px);
        background-size: 20px 20px;
      "
    ></div>

    <div class="text-center z-10">
      <h2
        class="text-2xl mb-2 uppercase font-black text-brutalist-yellow animate-[flicker_3s_infinite]"
      >
        > FIELD_STATUS: OPERATIONAL
      </h2>
      <p class="text-xs text-gray-500 font-mono">
        SCANNING SECTOR 7-G FOR ANCIENT SIGNALS...
      </p>
    </div>

    <div class="relative z-10">
      <button
        @click="store.extract()"
        :disabled="store.isExtracting || store.trayCount >= 5"
        class="group relative inline-flex items-center justify-center p-0.5 mb-2 mr-2 overflow-hidden text-sm font-medium text-gray-900 rounded-lg group bg-gradient-to-br from-yellow-400 to-orange-600 hover:text-white dark:text-white focus:ring-3 focus:outline-none focus:ring-yellow-800 disabled:opacity-50 disabled:cursor-not-allowed"
      >
        <div
          :class="[
            'relative px-16 py-12 transition-all ease-in duration-75 bg-black text-white border-4 border-white text-7xl font-black uppercase tracking-widest',
            !store.isExtracting &&
              'hover:bg-brutalist-yellow hover:text-black hover:translate-x-1 hover:-translate-y-1 hover:shadow-[-8px_8px_0px_0px_rgba(255,255,255,1)]',
          ]"
        >
          <span :class="store.isExtracting && 'animate-pulse'">{{
            store.isExtracting ? "SCANNING" : "EXTRACT"
          }}</span>
        </div>
      </button>
    </div>

    <div class="w-full max-w-xl px-8 z-10">
      <div class="flex justify-between mb-1">
        <span class="text-xs font-bold text-white uppercase tracking-tighter"
          >Bio-Scanner Frequency</span
        >
        <span class="text-xs font-bold text-white">{{
          store.isExtracting ? "SYNCING..." : "IDLE"
        }}</span>
      </div>
      <div class="w-full bg-zinc-900 border-2 border-white h-10 relative">
        <div
          class="bg-brutalist-yellow h-full transition-all ease-linear"
          :style="{
            width: store.isExtracting ? '100%' : '0%',
            transitionDuration: store.isExtracting ? '3000ms' : '0ms',
          }"
        ></div>
        <div
          class="absolute inset-0 flex items-center justify-center font-mono text-xs font-black mix-blend-difference"
        >
          {{
            store.isExtracting
              ? "SAMPLING CRUST LAYERS..."
              : "READY for analysis"
          }}
        </div>
      </div>
    </div>

    <div
      v-if="store.trayCount >= 5"
      class="mt-4 p-2 bg-brutalist-red text-black font-black uppercase text-sm animate-bounce border-2 border-white shadow-[4px_4px_0px_0px_rgba(255,255,255,1)]"
    >
      !! TRAY FULL - PROCEED TO LAB !!
    </div>
  </div>
</template>

<style scoped>
@keyframes flicker {
  0% {
    opacity: 1;
  }
  5% {
    opacity: 0.8;
  }
  10% {
    opacity: 1;
  }
  15% {
    opacity: 0.9;
  }
  20% {
    opacity: 1;
  }
  100% {
    opacity: 1;
  }
}
</style>
