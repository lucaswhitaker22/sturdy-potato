<script setup lang="ts">
import { useGameStore } from "@/stores/game";
import { TOOL_CATALOG } from "@/constants/items";
import { computed } from "vue";

const store = useGameStore();

const tools = computed(() => {
  return TOOL_CATALOG.map((tool) => {
    const level = store.ownedTools[tool.id] || 0;
    const cost = store.getToolCost(tool.id);
    return {
      ...tool,
      level,
      cost,
      isOwned: level > 0,
      isActive: store.activeToolId === tool.id,
      canAfford: store.scrapBalance >= cost,
    };
  });
});

const upgrade = (toolId: string, cost: number) => {
  store.upgradeTool(toolId, cost);
};

const deploy = (toolId: string) => {
  store.setActiveTool(toolId);
};

const overclockCost = computed(() => {
  // Arbitrary cost for now: 100k + 50k per current bonus (5% steps)
  return 100000 + (store.overclockBonus / 0.05) * 50000;
});

const canOverclock = computed(() => {
  const currentLevel = store.ownedTools[store.activeToolId] || 0;
  return (
    store.scrapBalance >= overclockCost.value &&
    store.activeToolId !== "rusty_shovel" &&
    currentLevel >= 10
  );
});

const overclock = () => {
  if (
    confirm(`Overclocking will cost ${overclockCost.value} Scrap. Proceed?`)
  ) {
    store.overclockTool(store.activeToolId, overclockCost.value);
  }
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
          class="text-xs font-mono text-gray-600 uppercase tracking-widest mt-1"
        >
          Department of Efficiency // A-99
        </p>
      </div>
      <div
        class="text-[10px] font-mono border border-gray-400 px-2 py-1 bg-white flex flex-col items-end"
      >
        <span>FORM: REQ-01</span>
        <span v-if="store.overclockBonus > 0" class="text-stamp-blue font-bold"
          >OVERCLOCKED x{{ (store.overclockBonus / 0.05).toFixed(0) }}</span
        >
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
            <span>Current Status:</span>
            <span class="font-bold uppercase">{{
              tool.level > 0 ? `Level ${tool.level}` : "Not Requisitioned"
            }}</span>
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
          <!-- Main Action Button -->
          <button
            @click="
              tool.isActive
                ? upgrade(tool.id, tool.cost)
                : tool.isOwned
                ? deploy(tool.id)
                : upgrade(tool.id, tool.cost)
            "
            :disabled="
              (!tool.isOwned && !tool.canAfford) ||
              (tool.isActive && !tool.canAfford)
            "
            class="flex-[2] py-2 font-bold uppercase border-2 text-xs transition-all relative overflow-hidden group"
            :class="[
              tool.isActive || tool.isOwned
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
            {{
              tool.isActive
                ? `Upgrade: ${tool.cost} Scrap`
                : tool.isOwned
                ? "Deploy Unit"
                : `Authorize: ${tool.cost} Scrap`
            }}
          </button>

          <!-- Secondary Upgrade Button (if owned but not active) -->
          <button
            v-if="tool.isOwned && !tool.isActive"
            @click="upgrade(tool.id, tool.cost)"
            :disabled="!tool.canAfford"
            class="flex-1 py-2 text-[10px] font-bold uppercase border border-gray-400 hover:bg-gray-100 transition-colors disabled:opacity-30"
          >
            Lvl Up ({{ tool.cost }})
          </button>
        </div>
      </div>
    </div>

    <!-- Overclocking Prestige Section -->
    <div class="mt-8 border-t-2 border-dashed border-gray-300 pt-6">
      <div class="bg-black text-white p-4 font-mono">
        <h3 class="text-lg font-bold uppercase tracking-tighter">
          PRESTIGE: OVERCLOCKING
        </h3>
        <p class="text-[10px] text-gray-400 mb-4 uppercase">
          Enhance hardware limits for permanent lab stability. Grants +5% Sift
          Success Rate per iteration.
        </p>

        <div
          class="flex flex-col md:flex-row gap-4 items-center justify-between border border-gray-800 p-4"
        >
          <div class="text-xs">
            <div class="flex gap-2">
              <span class="text-gray-500">Active Unit:</span>
              <span class="text-yellow-400 uppercase font-bold">{{
                store.activeToolId
              }}</span>
            </div>
            <div class="flex gap-2">
              <span class="text-gray-500">Current Bonus:</span>
              <span class="text-stamp-blue font-bold"
                >+{{ (store.overclockBonus * 100).toFixed(0) }}% SIFT
                STABILITY</span
              >
            </div>
          </div>

          <button
            @click="overclock"
            :disabled="!canOverclock"
            class="px-6 py-2 bg-white text-black font-bold uppercase hover:bg-yellow-400 transition-colors disabled:opacity-20 disabled:cursor-not-allowed text-xs"
          >
            INITIALIZE OVERCLOCK: {{ overclockCost }} SCRAP
          </button>
        </div>
        <p
          v-if="store.activeToolId === 'rusty_shovel'"
          class="text-[10px] text-red-500 mt-2 italic uppercase"
        >
          ERROR: Manual shovel units cannot be overclocked. Requisition
          industrial hardware.
        </p>
        <p
          v-else-if="(store.ownedTools[store.activeToolId] || 0) < 10"
          class="text-[10px] text-orange-400 mt-2 italic uppercase"
        >
          SYSTEM NOTE: Active unit must reach Level 10 (Max Efficiency) before
          Overclocking is possible.
        </p>
      </div>
    </div>
  </div>
</template>
