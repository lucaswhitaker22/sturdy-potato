<script setup lang="ts">
import { useGameStore } from "@/stores/game";
const store = useGameStore();
</script>

<template>
  <header
    class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 bg-white text-black p-4 border-b-8 border-black shadow-[8px_8px_0px_0px_rgba(255,255,255,1)]"
  >
    <div class="flex flex-col">
      <h1
        class="text-5xl font-black uppercase italic tracking-tighter leading-none"
      >
        RELIC_VAULT
      </h1>
      <div class="flex gap-4 mt-2">
        <div class="flex items-center gap-2">
          <span class="text-[10px] font-black bg-black text-white px-1"
            >EXCAV_LVL</span
          >
          <span class="text-xl font-black italic">{{
            store.excavationLevel
          }}</span>
          <div
            class="w-24 h-2 bg-zinc-200 border border-black relative overflow-hidden"
          >
            <div
              class="absolute inset-0 bg-brutalist-yellow transition-all duration-500"
              :style="{ width: `${excavationProgress}%` }"
            ></div>
          </div>
        </div>
        <div class="flex items-center gap-2">
          <span class="text-[10px] font-black bg-black text-white px-1"
            >RESTOR_LVL</span
          >
          <span class="text-xl font-black italic">{{
            store.restorationLevel
          }}</span>
          <div
            class="w-24 h-2 bg-zinc-200 border border-black relative overflow-hidden"
          >
            <div
              class="absolute inset-0 bg-brutalist-green transition-all duration-500"
              :style="{ width: `${restorationProgress}%` }"
            ></div>
          </div>
        </div>
      </div>
    </div>

    <!-- Right Side Stats -->
    <div class="flex flex-col items-end gap-1">
      <div class="flex gap-4 items-center">
        <div class="text-right">
          <div class="text-[10px] font-black uppercase text-zinc-500">
            Active_Equipment
          </div>
          <div class="text-lg font-black uppercase tracking-tight">
            {{ activeTool?.name }}
          </div>
        </div>
        <div class="flex flex-col items-end">
          <div class="text-[10px] font-black uppercase text-zinc-500 italic">
            Global_Scrap
          </div>
          <div class="text-4xl font-black leading-none text-brutalist-yellow">
            {{ store.scrapBalance.toLocaleString() }}
          </div>
        </div>
      </div>
    </div>
  </header>
</template>
