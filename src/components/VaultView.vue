<script setup lang="ts">
import { useGameStore } from "@/stores/game";
import type { VaultItem, ItemDefinition } from "@/types";
import { computed, ref } from "vue";

const store = useGameStore();

const vaultGrid = computed(() => {
  // If catalog is empty (loading), might want to fallback or show nothing
  return store.catalog.map((def) => {
    const ownedInstances = store.inventory.filter((i) => i.item_id === def.id);

    // Find the "Best" instance to display
    // Priority: Prismatic > Mint Condition > Low Mint Number
    const bestInstance = ownedInstances.sort((a, b) => {
      if (a.is_prismatic && !b.is_prismatic) return -1;
      if (!a.is_prismatic && b.is_prismatic) return 1;
      // Then by condition value? (Mint=4, Wrecked=1) - simplified text compare for now
      if (a.condition === "mint" && b.condition !== "mint") return -1;
      if (b.condition === "mint" && a.condition !== "mint") return 1;
      return (a.mint_number || 999999) - (b.mint_number || 999999);
    })[0];

    return {
      ...def,
      found: ownedInstances.length > 0,
      count: ownedInstances.length,
      bestInstance: bestInstance || null, // Contains the specific vault attributes
    };
  });
});

const selectedItem = ref<(typeof vaultGrid.value)[0] | null>(null);

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
          :class="{
            'border-purple-600 text-purple-600': selectedItem.tier === 'epic',
            'border-orange-600 text-orange-600': selectedItem.tier === 'mythic',
          }"
        >
          CLASS: {{ selectedItem.tier }}
        </span>
        <span class="font-mono text-[10px] text-gray-600"
          >REF_ID: {{ selectedItem.id }}</span
        >

        <!-- Mint & Condition -->
        <div v-if="selectedItem.bestInstance" class="flex items-center gap-1">
          <span
            class="font-mono text-[10px] font-bold bg-black text-white px-1"
          >
            #{{ selectedItem.bestInstance.mint_number }}
          </span>
          <span
            v-if="selectedItem.bestInstance.condition === 'mint'"
            class="text-[9px] font-bold text-green-600 uppercase tracking-widest border border-green-600 px-1"
            >MINT</span
          >
          <span
            v-else-if="selectedItem.bestInstance.condition === 'wrecked'"
            class="text-[9px] font-bold text-red-800 uppercase tracking-widest border border-red-800 px-1 decoration-line-through"
            >WRECKED</span
          >
          <span
            v-if="selectedItem.bestInstance.is_prismatic"
            class="text-[9px] font-bold text-transparent bg-clip-text bg-gradient-to-r from-red-500 via-yellow-500 to-blue-500 uppercase tracking-widest border border-blue-400 px-1 animate-pulse"
            >PRISMATIC</span
          >
        </div>
      </div>

      <p class="font-serif italic text-gray-800 leading-[24px] mt-2 flex-1">
        "{{ selectedItem.flavor_text }}"
      </p>

      <div
        class="mt-auto pt-4 border-t border-gray-300 text-[10px] font-mono text-gray-500 uppercase flex justify-between"
      >
        <span>Verified by: AGENT_A</span>
        <span
          >Value:
          {{ selectedItem.bestInstance?.historical_value || "??" }} HV</span
        >
        <span
          >Date:
          {{
            selectedItem.bestInstance
              ? new Date(
                  selectedItem.bestInstance.discovered_at
                ).toLocaleDateString()
              : "UNKNOWN"
          }}</span
        >
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
            class="absolute inset-0 bg-white border shadow-sm p-1 flex flex-col items-center overflow-hidden"
            :class="[
              item.found
                ? 'border-gray-400'
                : 'border-gray-200 border-dashed bg-transparent',
              item.bestInstance?.is_prismatic
                ? 'ring-2 ring-offset-1 ring-purple-500 prismatic-border'
                : '',
              item.tier === 'mythic' ? 'border-orange-400 border-2' : '',
            ]"
          >
            <!-- Prismatic Background Effect -->
            <div
              v-if="item.bestInstance?.is_prismatic"
              class="absolute inset-0 bg-gradient-to-tr from-pink-200 via-purple-200 to-blue-200 opacity-50 z-0"
            ></div>

            <div
              class="flex-1 w-full flex items-center justify-center bg-gray-100 overflow-hidden relative z-10"
              :class="
                item.found ? 'grayscale contrast-125 sepia-[.3]' : 'opacity-40'
              "
            >
              <span class="text-2xl drop-shadow-sm">{{
                item.found
                  ? item.tier === "mythic"
                    ? "👑"
                    : item.tier === "unique"
                    ? "🏺"
                    : item.tier === "epic"
                    ? "🏛️"
                    : item.tier === "rare"
                    ? "💎"
                    : "📦"
                  : ""
              }}</span>

              <!-- Condition Scratch Overlay -->
              <div
                v-if="item.bestInstance?.condition === 'wrecked'"
                class="absolute inset-0 bg-black/20"
                style="
                  background-image: url('data:image/svg+xml;base64,...');
                  opacity: 0.5;
                "
              ></div>
            </div>

            <!-- Label Area -->
            <div
              v-if="item.found"
              class="h-4 w-full mt-1 border-t border-gray-100 flex items-center justify-center relative z-10"
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

            <!-- Badges -->
            <div
              class="absolute top-0 right-0 p-[2px] z-20 flex flex-col items-end gap-[1px]"
            >
              <div
                v-if="item.bestInstance?.mint_number <= 10"
                class="w-2 h-2 bg-yellow-400 rounded-full border border-black"
                title="Low Mint"
              ></div>
              <div
                v-if="item.bestInstance?.condition === 'mint'"
                class="w-2 h-2 bg-green-500 rounded-full border border-black"
                title="Mint Condition"
              ></div>
            </div>
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
