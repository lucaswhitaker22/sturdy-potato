<template>
  <div class="shop-view p-4 text-green-400 font-mono">
    <div class="flex justify-between items-center mb-6">
      <h2 class="text-2xl font-bold">Historical Influence Exchange</h2>
      <div class="text-xl text-yellow-400">
        Influence: {{ historicalInfluence }} HI
      </div>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div
        v-for="item in shopItems"
        :key="item.key"
        class="border border-green-600 p-4 flex flex-col justify-between"
      >
        <div>
          <h3 class="text-xl font-bold text-white mb-2">{{ item.name }}</h3>
          <p class="text-sm text-green-300 mb-4">{{ item.description }}</p>
          <div class="text-xs uppercase tracking-widest text-green-600 mb-2">
            {{ item.type }}
          </div>
        </div>

        <div class="mt-4">
          <div class="text-yellow-400 font-bold mb-2">{{ item.cost }} HI</div>
          <button
            @click="buy(item)"
            :disabled="historicalInfluence < item.cost"
            class="w-full py-2 bg-green-900 border border-green-500 text-green-100 disabled:opacity-50 disabled:cursor-not-allowed hover:bg-green-700 transition"
          >
            {{
              historicalInfluence < item.cost
                ? "Insufficient Influence"
                : "Acquire"
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
