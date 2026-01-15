<script setup lang="ts">
import { useGameStore } from "@/stores/game";
const store = useGameStore();
</script>

<template>
  <div
    class="panel-brutalist flex-1 flex flex-col items-center justify-center min-h-[400px] gap-8 relative overflow-hidden group"
  >
    <!-- Background Grid Effect -->
    <div
      class="absolute inset-0 opacity-10 pointer-events-none"
      style="
        background-image: radial-gradient(#fff 1px, transparent 1px);
        background-size: 20px 20px;
      "
    ></div>

    <div class="text-center z-10">
      <h2
        class="text-2xl mb-2 uppercase font-black text-brutalist-yellow animate-pulse"
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
        :disabled="store.isExtracting"
        class="group relative inline-flex items-center justify-center p-0.5 mb-2 mr-2 overflow-hidden text-sm font-medium text-gray-900 rounded-lg group bg-gradient-to-br from-yellow-400 to-orange-600 hover:text-white dark:text-white focus:ring-4 focus:outline-none focus:ring-yellow-800 disabled:opacity-50 disabled:cursor-not-allowed"
      >
        <!-- Custom Brutalist Button Overload -->
        <div
          :class="[
            'relative px-16 py-12 transition-all ease-in duration-75 bg-black text-white border-4 border-white text-7xl font-black uppercase tracking-widest',
            store.isExtracting
              ? 'opacity-50'
              : 'hover:bg-brutalist-yellow hover:text-black hover:translate-x-1 hover:-translate-y-1 hover:shadow-[-8px_8px_0px_0px_rgba(255,255,255,1)]',
          ]"
        >
          {{ store.isExtracting ? "SCANNING" : "EXTRACT" }}
        </div>
      </button>
    </div>

    <!-- Extraction Progress Bar -->
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
          {{ store.isExtracting ? "SAMPLING CRUST LAYERS..." : "READY" }}
        </div>
      </div>
    </div>

    <!-- Tray Warning -->
    <div
      v-if="store.trayCount >= 5"
      class="mt-4 p-2 bg-brutalist-red text-black font-black uppercase text-sm animate-bounce"
    >
      !! TRAY FULL - PROCEED TO LAB !!
    </div>
  </div>
</template>
