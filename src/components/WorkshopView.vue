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
  <div class="h-full flex flex-col gap-6 p-1">
    <!-- Header -->
    <div class="border-b-2 border-black pb-2 flex justify-between items-end">
      <div>
        <h2
          class="text-2xl font-serif font-black uppercase text-ink-black tracking-tight"
        >
          Equipment Requisition
        </h2>
        <p
          class="text-xs font-mono text-gray-500 uppercase tracking-widest mt-1"
        >
          Department of Efficiency // A-99
        </p>
      </div>
      <div
        class="text-[10px] font-mono border border-gray-400 px-2 py-1 bg-white"
      >
        FORM: REQ-01
      </div>
    </div>

    <!-- Grid of Requisition Forms -->
    <div
      class="grid grid-cols-1 md:grid-cols-2 gap-6 overflow-y-auto pr-2 custom-scrollbar flex-1"
    >
      <div
        v-for="tool in tools"
        :key="tool.id"
        class="border transition-all flex flex-col gap-2 relative bg-white shadow-sm p-4 hover:shadow-md"
        :class="
          tool.isActive
            ? 'border-2 border-black ring-1 ring-black'
            : 'border border-gray-300'
        "
      >
        <!-- Paper punch holes visual -->
        <div
          class="absolute top-2 left-2 w-3 h-3 rounded-full bg-gray-100 border border-gray-300 shadow-inner"
        ></div>

        <!-- Status -->
        <div class="absolute top-4 right-4 transform rotate-6 z-10">
          <span
            v-if="tool.isActive"
            class="stamp-box border-stamp-blue text-stamp-blue border-2"
          >
            DEPLOYED
          </span>
          <span
            v-else-if="tool.isOwned"
            class="stamp-box border-gray-400 text-gray-500 border-2 text-[10px]"
          >
            INVENTORY
          </span>
        </div>

        <div class="pl-6 pt-1">
          <h3
            class="text-lg font-serif font-bold uppercase border-b border-gray-200 inline-block mb-1"
          >
            {{ tool.name }}
          </h3>
          <p
            class="text-xs font-serif italic text-gray-600 leading-relaxed max-w-[85%]"
          >
            "{{ tool.flavorText }}"
          </p>
        </div>

        <div
          class="mt-4 bg-[#F5F5F0] p-3 border border-gray-200 text-xs font-mono w-full"
        >
          <div class="flex justify-between border-b border-gray-300 pb-1 mb-1">
            <span>Specs:</span>
            <span class="font-bold">{{ tool.id }}</span>
          </div>
          <div class="flex justify-between">
            <span>Auto-Rate:</span>
            <span>{{ tool.automationRate }}/s</span>
          </div>
          <div class="flex justify-between">
            <span>Find-Bonus:</span>
            <span>+{{ (tool.findRateBonus * 100).toFixed(0) }}%</span>
          </div>
        </div>

        <div class="mt-auto pt-4 flex gap-2">
          <button
            v-if="!tool.isActive"
            @click="upgrade(tool.id, tool.cost)"
            :disabled="!tool.canAfford && !tool.isOwned"
            class="flex-1 py-2 font-bold uppercase border-2 text-xs transition-all relative overflow-hidden group"
            :class="[
              tool.isOwned
                ? 'bg-white border-black hover:bg-black hover:text-white'
                : tool.canAfford
                ? 'bg-white border-black shadow-[4px_4px_0_0_#999] hover:translate-x-[1px] hover:translate-y-[1px] hover:shadow-[3px_3px_0_0_#999]'
                : 'bg-gray-100 text-gray-500 border-gray-300 cursor-not-allowed',
            ]"
          >
            <div
              v-if="tool.canAfford && !tool.isOwned"
              class="absolute inset-0 bg-yellow-200 opacity-0 group-hover:opacity-30 transition-opacity"
            ></div>
            {{ tool.isOwned ? "Deploy Unit" : `Authorize: ${tool.cost} Scrap` }}
          </button>
          <div
            v-else
            class="flex-1 py-2 text-center text-xs font-bold text-gray-500 border border-gray-300 bg-gray-100 italic"
          >
            Currently Assigned
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
