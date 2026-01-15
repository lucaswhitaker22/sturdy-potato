<template>
  <div class="shop-view p-4 h-full flex flex-col gap-6 font-serif">
    <!-- Header -->
    <div class="flex justify-between items-end border-b-2 border-black pb-4">
      <div>
        <h2 class="text-3xl font-black text-ink-black uppercase tracking-tight">
          Influence Exchange
        </h2>
        <p class="text-xs font-mono text-gray-500 mt-1 uppercase">
          Acquire Permits, Titles, and Rights
        </p>
      </div>
      <div class="text-right">
        <div
          class="text-[10px] font-mono uppercase bg-yellow-100 px-2 py-0.5 inline-block border border-yellow-200 text-yellow-800 font-bold mb-1"
        >
          Current Standing
        </div>
        <div class="text-2xl font-bold text-ink-black">
          {{ historicalInfluence }}
          <span class="text-sm font-normal text-gray-500">HI</span>
        </div>
      </div>
    </div>

    <!-- Catalogue Grid -->
    <div
      class="grid grid-cols-1 md:grid-cols-3 gap-6 overflow-y-auto pr-2 custom-scrollbar"
    >
      <div
        v-for="item in shopItems"
        :key="item.key"
        class="border-2 border-double border-gray-300 p-6 flex flex-col justify-between bg-[#FDFDFB] shadow-sm hover:shadow-md transition-shadow relative overflow-hidden"
      >
        <!-- Watermark -->
        <div
          class="absolute -right-4 -bottom-4 text-9xl text-gray-100 font-black z-0 pointer-events-none select-none opacity-50 transform -rotate-12"
        >
          §
        </div>

        <div class="relative z-10">
          <div
            class="border-b border-gray-200 pb-2 mb-4 flex justify-between items-start"
          >
            <span
              class="text-[10px] uppercase font-mono tracking-widest text-gray-400 border border-gray-200 px-1"
              >{{ item.type }}</span
            >
          </div>
          <h3 class="text-xl font-bold text-ink-black mb-3 leading-tight">
            {{ item.name }}
          </h3>
          <p class="text-sm text-gray-600 mb-6 italic leading-relaxed">
            "{{ item.description }}"
          </p>
        </div>

        <div
          class="mt-4 relative z-10 border-t border-dashed border-gray-300 pt-4"
        >
          <div class="flex justify-between items-center mb-3">
            <span class="text-[10px] font-mono text-gray-400 uppercase"
              >Requisition Cost</span
            >
            <span class="text-lg font-bold">{{ item.cost }} HI</span>
          </div>

          <button
            @click="buy(item)"
            :disabled="historicalInfluence < item.cost"
            class="w-full py-3 font-bold uppercase text-xs border-2 transition-all relative group overflow-hidden"
            :class="
              historicalInfluence < item.cost
                ? 'bg-gray-100 text-gray-400 border-gray-200 cursor-not-allowed'
                : 'bg-white text-black border-black hover:bg-black hover:text-white'
            "
          >
            {{
              historicalInfluence < item.cost
                ? "Insufficient Standing"
                : "Countersign & Acquire"
            }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useGameStore } from "@/stores/game";
import { storeToRefs } from "pinia";

const gameStore = useGameStore();
const { historicalInfluence } = storeToRefs(gameStore);

const shopItems = [
  {
    key: "zone_permit_suburbs",
    name: "Zone Permit: The Old Suburbs",
    description:
      "Unlocks access to the residential ruins. High yield for household relics.",
    type: "Permit",
    cost: 500,
  },
  {
    key: "title_curator",
    name: 'Title: "Curator"',
    description: 'Awards the "Curator" prefix to your name in global feeds.',
    type: "Cosmetic",
    cost: 200,
  },
];

async function buy(item: any) {
  if (!confirm(`Spend ${item.cost} HI to purchase ${item.name}?`)) return;
  await gameStore.purchaseInfluenceItem(item.key);
}
</script>
