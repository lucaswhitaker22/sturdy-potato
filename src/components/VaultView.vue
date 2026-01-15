<script setup lang="ts">
import { useGameStore } from "@/stores/game";
import { ITEM_CATALOG, type Item } from "@/constants/items";
import { computed, ref } from "vue";

const store = useGameStore();

const vaultGrid = computed(() => {
  return ITEM_CATALOG.map((item) => {
    const ownedInstances = store.inventory.filter((i) => i.item_id === item.id);
    const bestMint =
      ownedInstances.length > 0
        ? Math.min(...ownedInstances.map((i) => i.mint_number || 999999))
        : null;

    return {
      ...item,
      found: ownedInstances.length > 0,
      count: ownedInstances.length,
      bestMint,
    };
  });
});

const selectedItem = ref<Item | null>(null);

const selectItem = (item: (typeof vaultGrid.value)[0]) => {
  if (item.found) {
    selectedItem.value = item;
  }
};
</script>

<template>
  <div class="h-full flex flex-col gap-4 relative">
    <!-- Header -->
    <div
      class="flex justify-between items-center border-b border-gray-400 pb-2 border-dashed"
    >
      <h3 class="uppercase font-serif font-bold text-sm tracking-wider">
        Archive Log 2026
      </h3>
      <div
        class="text-[10px] font-mono bg-gray-200 px-2 rounded-full border border-gray-300"
      >
        {{ store.discoveredCount }}/20 CATALOGUED
      </div>
    </div>

    <!-- Index Card Details Overlay -->
    <div
      v-if="selectedItem"
      class="absolute inset-2 z-20 bg-[#FDFDFB] p-6 flex flex-col shadow-[0_10px_40px_rgba(0,0,0,0.2)] border border-gray-300 transform rotate-1"
      style="
        background-image: linear-gradient(#e5e5e5 1px, transparent 1px);
        background-size: 100% 24px;
        line-height: 24px;
      "
    >
      <!-- Paper Clip or Pin -->
      <div
        class="absolute -top-3 left-1/2 w-4 h-4 rounded-full bg-red-800 shadow-sm border border-white/50 z-30"
      ></div>

      <div class="flex justify-between items-start mb-6">
        <h4
          class="text-2xl font-serif font-black uppercase text-ink-black bg-white px-2 inline-block transform -rotate-1 border border-black shadow-[2px_2px_0_0_rgba(0,0,0,0.2)]"
        >
          {{ selectedItem.name }}
        </h4>
        <button
          @click="selectedItem = null"
          class="w-6 h-6 flex items-center justify-center border border-black hover:bg-black hover:text-white transition-colors font-mono text-xs"
        >
          ✕
        </button>
      </div>

      <div class="flex items-center gap-2 mb-4">
        <span
          class="stamp-box text-[10px] scale-75 border-2 border-ink-black text-ink-black rotate-0 opacity-100"
        >
          CLASS: {{ selectedItem.tier }}
        </span>
        <span class="font-mono text-[10px] text-gray-600"
          >REF_ID: {{ selectedItem.id }}</span
        >
        <div
          v-if="(selectedItem as any).bestMint"
          class="flex items-center gap-1"
        >
          <span
            class="font-mono text-[10px] font-bold bg-black text-white px-1"
          >
            #{{ (selectedItem as any).bestMint }}
          </span>
          <span
            v-if="(selectedItem as any).bestMint <= 10"
            class="text-[9px] font-bold text-yellow-600 uppercase tracking-widest border border-yellow-600 px-1"
          >
            PRESTIGE
          </span>
        </div>
      </div>

      <p class="font-serif italic text-gray-800 leading-[24px mt-2 flex-1">
        "{{ selectedItem.flavorText }}"
      </p>

      <div
        class="mt-auto pt-4 border-t border-gray-300 text-[10px] font-mono text-gray-500 uppercase flex justify-between"
      >
        <span>Verified by: AGENT_A</span>
        <span>Date: {{ new Date().toLocaleDateString() }}</span>
      </div>
    </div>

    <!-- Grid Layout -->
    <div class="flex-1 overflow-y-auto pr-1">
      <div class="grid grid-cols-4 gap-3 p-1">
        <div
          v-for="item in vaultGrid"
          :key="item.id"
          @click="selectItem(item)"
          :title="item.found ? item.name : 'Missing Entry'"
          class="aspect-square relative group cursor-pointer transition-transform hover:-translate-y-1"
        >
          <!-- The Polaroid/Stamp Frame -->
          <div
            class="absolute inset-0 bg-white border shadow-sm p-1 flex flex-col items-center"
            :class="
              item.found
                ? 'border-gray-400'
                : 'border-gray-200 border-dashed bg-transparent'
            "
          >
            <div
              class="flex-1 w-full flex items-center justify-center bg-gray-100 overflow-hidden relative"
              :class="
                item.found ? 'grayscale contrast-125 sepia-[.3]' : 'opacity-40'
              "
            >
              <span class="text-2xl">{{
                item.found ? (item.tier === "rare" ? "🏆" : "📦") : ""
              }}</span>
              <!-- Grain Overlay -->
              <div
                v-if="item.found"
                class="absolute inset-0 bg-black/10 mix-blend-overlay pointer-events-none"
              ></div>
            </div>

            <!-- Label Area -->
            <div
              v-if="item.found"
              class="h-4 w-full mt-1 border-t border-gray-100 flex items-center justify-center"
            >
              <span
                class="font-mono text-[8px] uppercase tracking-tighter truncate w-full text-center text-gray-600 block"
                >{{ item.name }}</span
              >
            </div>
            <div
              v-else
              class="h-4 w-full mt-1 flex items-center justify-center"
            >
              <span class="text-[8px] text-gray-600 font-bold">MISSING</span>
            </div>

            <!-- Mint Badge on Thumbnail -->
            <div
              v-if="item.found && item.bestMint && item.bestMint <= 10"
              class="absolute top-[2px] right-[2px] w-2 h-2 bg-yellow-500 rounded-full border border-black z-10"
              title="Prestige Mint"
            ></div>
          </div>

          <!-- Rare Sticker -->
          <div
            v-if="item.found && item.tier === 'rare'"
            class="absolute -top-1 -right-1 w-3 h-3 bg-yellow-400 rounded-full border border-white shadow-sm z-10"
            title="Rare Find"
          ></div>
        </div>
      </div>
    </div>
  </div>
</template>
