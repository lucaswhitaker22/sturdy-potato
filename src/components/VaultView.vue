<script setup lang="ts">
import { useGameStore } from "@/stores/game";
import { ITEM_CATALOG, type Item } from "@/constants/items";
import { computed, ref } from "vue";

const store = useGameStore();

const vaultGrid = computed(() => {
  return ITEM_CATALOG.map((item) => ({
    ...item,
    found: store.vaultItems.includes(item.id),
  }));
});

const selectedItem = ref<Item | null>(null);

const selectItem = (item: (typeof vaultGrid.value)[0]) => {
  if (item.found) {
    selectedItem.value = item;
  }
};
</script>

<template>
  <div class="panel-brutalist h-full flex flex-col gap-4 overflow-hidden">
    <div class="flex justify-between items-center border-b-2 border-white pb-2">
      <h3 class="uppercase font-black text-sm">> VAULT_ARCHIVE</h3>
      <span class="text-xs font-mono"
        >{{ store.discoveredCount }}/20 FOUND</span
      >
    </div>

    <!-- Details Overlay -->
    <div
      v-if="selectedItem"
      class="absolute inset-0 z-20 bg-black/90 p-6 flex flex-col border-4 border-brutalist-yellow"
    >
      <div class="flex justify-between items-start mb-4">
        <h4 class="text-2xl font-black uppercase text-brutalist-yellow">
          {{ selectedItem.name }}
        </h4>
        <button
          @click="selectedItem = null"
          class="text-white font-bold hover:text-brutalist-red"
        >
          [X]
        </button>
      </div>
      <div class="flex gap-4 mb-4">
        <div
          class="px-2 py-1 bg-white text-black font-black text-[10px] uppercase"
        >
          {{ selectedItem.tier }}
        </div>
        <div class="text-[10px] font-mono text-gray-400">
          ID: {{ selectedItem.id }}
        </div>
      </div>
      <p class="text-sm font-mono italic leading-relaxed text-gray-300">
        "{{ selectedItem.flavorText }}"
      </p>
      <div
        class="mt-auto pt-4 border-t border-white/20 text-[10px] text-gray-500 font-mono"
      >
        SCAN_SYNC_COMPLETE // AUTH_USER_01
      </div>
    </div>

    <div class="flex-1 overflow-y-auto pr-2 custom-scrollbar">
      <div class="grid grid-cols-4 gap-2">
        <div
          v-for="item in vaultGrid"
          :key="item.id"
          @click="selectItem(item)"
          :title="item.found ? item.name : '???'"
          :class="[
            'aspect-square border-2 flex items-center justify-center transition-all group relative cursor-pointer',
            item.found
              ? item.tier === 'rare'
                ? 'border-brutalist-yellow bg-zinc-800'
                : 'border-white bg-zinc-900 shadow-[2px_2px_0px_0px_rgba(255,255,255,1)]'
              : 'border-zinc-800 bg-black grayscale opacity-50 cursor-not-allowed',
          ]"
        >
          <span
            v-if="item.found"
            class="text-2xl transform group-hover:scale-125 transition-transform"
          >
            {{ item.tier === "rare" ? "🏆" : "📦" }}
          </span>
          <span v-else class="text-zinc-800 text-xs font-black">?</span>

          <div
            v-if="item.found && item.tier === 'rare'"
            class="absolute -top-1 -right-1 w-2 h-2 bg-brutalist-yellow animate-ping"
          ></div>
        </div>
      </div>
    </div>

    <div class="mt-auto border-t border-white/20 pt-4">
      <div
        class="text-[10px] font-mono text-gray-500 uppercase tracking-widest leading-tight"
      >
        COMPLETION_STATUS: {{ Math.round((store.discoveredCount / 20) * 100) }}%
        <br />
        ENCRYPTION: ACTIVE
      </div>
    </div>
  </div>
</template>
