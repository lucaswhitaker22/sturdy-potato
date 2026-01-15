<script setup lang="ts">
import { useGameStore } from "@/stores/game";
import { ITEM_CATALOG } from "@/constants/items";
import { computed } from "vue";

const store = useGameStore();

const vaultGrid = computed(() => {
  return ITEM_CATALOG.map((item) => ({
    ...item,
    found: store.vaultItems.includes(item.id),
  }));
});
</script>

<template>
  <div class="panel-brutalist h-full flex flex-col gap-4 overflow-hidden">
    <div class="flex justify-between items-center border-b-2 border-white pb-2">
      <h3 class="uppercase font-black text-sm">> VAULT_ARCHIVE</h3>
      <span class="text-xs font-mono"
        >{{ store.discoveredCount }}/20 FOUND</span
      >
    </div>

    <div class="flex-1 overflow-y-auto pr-2 custom-scrollbar">
      <div class="grid grid-cols-4 gap-2">
        <div
          v-for="item in vaultGrid"
          :key="item.id"
          :title="item.found ? item.name : '???'"
          :class="[
            'aspect-square border-2 flex items-center justify-center transition-all group relative',
            item.found
              ? item.tier === 'rare'
                ? 'border-brutalist-yellow bg-zinc-800'
                : 'border-white bg-zinc-900'
              : 'border-zinc-800 bg-black grayscale opacity-50',
          ]"
        >
          <span
            v-if="item.found"
            class="text-2xl transform group-hover:scale-125 transition-transform"
          >
            {{ item.tier === "rare" ? "🏆" : "📦" }}
          </span>
          <span v-else class="text-zinc-800 text-xs font-black">?</span>

          <!-- Tooltip-ish indicator for Rares -->
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
