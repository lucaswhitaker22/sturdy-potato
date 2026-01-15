<script setup lang="ts">
import { useGameStore } from "@/stores/game";
const store = useGameStore();
</script>

<template>
  <header
    class="border-4 border-white p-6 bg-black flex flex-col md:flex-row justify-between items-center shadow-[8px_8px_0px_0px_rgba(255,190,0,1)] gap-4"
  >
    <div class="flex items-center gap-4">
      <div
        class="w-12 h-12 bg-brutalist-yellow border-2 border-white flex items-center justify-center"
      >
        <span class="text-black font-black text-2xl">RV</span>
      </div>
      <h1
        class="text-3xl md:text-5xl font-black italic uppercase tracking-tighter text-white"
      >
        Relic Vault
        <span class="text-xs not-italic border border-white px-1 align-top"
          >V1.0-MVP</span
        >
      </h1>
    </div>

    <div class="flex flex-col md:flex-row gap-4 text-xl w-full md:w-auto">
      <div class="flex flex-1 border-2 border-white overflow-hidden">
        <div class="bg-white text-black px-3 font-black flex items-center">
          SCRAP
        </div>
        <div class="bg-black text-white px-4 py-1 font-mono flex-1 text-right">
          {{ store.scrapBalance.toLocaleString() }}
        </div>
      </div>
      <div class="flex border-2 border-white overflow-hidden">
        <div
          class="bg-brutalist-yellow text-black px-3 font-black flex items-center uppercase"
        >
          Tray
        </div>
        <div
          class="bg-black text-white px-4 py-1 font-mono min-w-[80px] text-center"
        >
          {{ store.trayCount }}/5
        </div>
      </div>
    </div>
  </header>
</template>
