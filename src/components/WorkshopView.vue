<script setup lang="ts">
import { useGameStore } from "@/stores/game";
import { TOOL_CATALOG } from "@/constants/items";
import { computed } from "vue";

const store = useGameStore();

const tools = computed(() => {
  return TOOL_CATALOG.map((tool) => ({
    ...tool,
    isOwned: store.ownedToolIds.includes(tool.id),
    isActive: store.activeToolId === tool.id,
    canAfford: store.scrapBalance >= tool.cost,
  }));
});

const upgrade = (toolId: string, cost: number) => {
  store.upgradeTool(toolId, cost);
};
</script>

<template>
  <div
    class="p-6 flex flex-col gap-6 h-full overflow-y-auto custom-scrollbar bg-black text-white"
  >
    <div class="border-b-4 border-white pb-4 mb-4">
      <h2 class="text-4xl font-black uppercase tracking-tighter italic">
        > THE_WORKSHOP
      </h2>
      <p class="text-xs font-mono text-zinc-500 mt-2 uppercase">
        Convert scrap to efficiency. Automation is the only path to the core.
      </p>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div
        v-for="tool in tools"
        :key="tool.id"
        :class="[
          'p-4 border-4 transition-all flex flex-col gap-2 relative overflow-hidden',
          tool.isActive
            ? 'border-brutalist-green bg-zinc-900'
            : 'border-white bg-black hover:bg-zinc-950',
        ]"
      >
        <!-- Status Badge -->
        <div
          v-if="tool.isActive"
          class="absolute top-0 right-0 bg-brutalist-green text-black px-2 py-0.5 text-[10px] font-black uppercase"
        >
          ACTIVE_UNIT
        </div>
        <div
          v-else-if="tool.isOwned"
          class="absolute top-0 right-0 bg-white text-black px-2 py-0.5 text-[10px] font-black uppercase"
        >
          OWNED
        </div>

        <h3 class="text-xl font-black uppercase">{{ tool.name }}</h3>
        <p class="text-xs text-zinc-400 font-mono leading-tight">
          {{ tool.flavorText }}
        </p>

        <div
          class="grid grid-cols-2 gap-2 mt-4 text-[10px] font-mono border-t border-white/20 pt-2"
        >
          <div>
            <span class="text-zinc-500 uppercase block">Automation:</span>
            <span class="text-brutalist-green"
              >{{ tool.automationRate }} SCRAP/S</span
            >
          </div>
          <div>
            <span class="text-zinc-500 uppercase block">Find_Rate:</span>
            <span class="text-brutalist-yellow"
              >+{{ (tool.findRateBonus * 100).toFixed(0) }}%</span
            >
          </div>
        </div>

        <button
          v-if="!tool.isActive"
          @click="upgrade(tool.id, tool.cost)"
          :disabled="!tool.canAfford && !tool.isOwned"
          :class="[
            'mt-4 py-2 font-black uppercase border-2 transition-all',
            tool.isOwned
              ? 'bg-white text-black border-white hover:bg-zinc-200'
              : tool.canAfford
              ? 'bg-brutalist-yellow text-black border-brutalist-yellow hover:-translate-y-1'
              : 'bg-zinc-800 text-zinc-500 border-zinc-800 cursor-not-allowed',
          ]"
        >
          {{ tool.isOwned ? "ACTIVATE" : `PURCHASE [${tool.cost} SCRAP]` }}
        </button>
        <div
          v-else
          class="mt-4 py-2 text-center text-[10px] font-black text-brutalist-green uppercase border-2 border-brutalist-green/20"
        >
          STATION_ENGAGED
        </div>
      </div>
    </div>
  </div>
</template>
