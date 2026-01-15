<script setup lang="ts">
import { useGameStore } from "@/stores/game";
const store = useGameStore();
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
        @click="store.extract()"
        :disabled="store.isExtracting || store.trayCount >= 5"
        class="group relative inline-flex items-center justify-center focus:outline-none disabled:opacity-50 disabled:cursor-not-allowed transition-transform active:scale-95"
      >
        <!-- Button Body (The Stamp Handle) -->
        <div
          class="relative w-64 h-24 bg-[#EBEBE0] border-4 border-ink-black shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] hover:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] hover:translate-x-1 hover:translate-y-1 transition-all flex items-center justify-center overflow-hidden"
          :class="store.isExtracting ? 'bg-gray-100' : 'bg-[#FFFFF0]'"
        >
          <!-- Highlighter Hover Effect -->
          <div
            class="absolute inset-0 bg-[#FFFF00] opacity-0 group-hover:opacity-20 transition-opacity mix-blend-multiply"
          ></div>

          <!-- Stamp Text -->
          <span
            class="font-black text-4xl tracking-widest text-ink-black uppercase transform group-hover:-rotate-2 transition-transform select-none font-serif"
          >
            {{ store.isExtracting ? "SCANNING" : "[ EXTRACT ]" }}
          </span>
        </div>
      </button>
    </div>

    <!-- Progress Readout (Typed Style) -->
    <div
      class="w-full max-w-lg z-10 font-mono text-xs border-t border-b border-gray-300 py-4 bg-[#white]/50"
    >
      <div class="flex justify-between mb-2 px-2">
        <span class="uppercase font-bold text-gray-600"
          >Bio-Scan Frequency:</span
        >
        <span class="bg-black text-white px-2">{{
          store.isExtracting ? "ACQUIRING..." : "STANDBY"
        }}</span>
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
            width: store.isExtracting ? '100%' : '0%',
            transitionDuration: store.isExtracting
              ? `${store.cooldownMs}ms`
              : '0ms',
          }"
        >
          <!-- Texture on the ink -->
          <div
            class="absolute inset-0 opacity-50 bg-[url('https://www.transparenttextures.com/patterns/stardust.png')]"
          ></div>
        </div>
      </div>

      <div class="mt-2 text-center text-gray-700 italic">
        {{
          store.isExtracting
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
