<script setup lang="ts">
import { useGameStore } from "@/stores/game";
import { COLLECTION_SETS, ITEM_CATALOG } from "@/constants/items";
import { computed } from "vue";

const store = useGameStore();

const sets = computed(() => {
  return COLLECTION_SETS.map((set) => {
    const collectedItems = set.itemIds.filter((id) =>
      store.vaultItems.includes(id)
    );
    const isComplete = collectedItems.length === set.itemIds.length;
    const isClaimed = store.completedSetIds.includes(set.id);

    return {
      ...set,
      collectedCount: collectedItems.length,
      isComplete,
      isClaimed,
      items: set.itemIds.map((id) => {
        const item = ITEM_CATALOG.find((i) => i.id === id);
        return {
          id,
          name: item?.name || "Unknown",
          isCollected: store.vaultItems.includes(id),
        };
      }),
    };
  });
});

const claim = (setId: string, reward: number) => {
  store.claimSet(setId, reward);
};
</script>

<template>
  <div class="h-full flex flex-col gap-6 p-1">
    <!-- Header -->
    <div class="border-b-2 border-black pb-2">
      <h2
        class="text-2xl font-serif font-black uppercase text-ink-black tracking-tight"
      >
        Piece Assembly
      </h2>
      <p class="text-xs font-mono text-gray-500 mt-1">
        RECONSTRUCT HISTORICAL SETS FOR BOUNTY
      </p>
    </div>

    <div
      class="flex-1 overflow-y-auto pr-2 custom-scrollbar flex flex-col gap-8"
    >
      <div
        v-for="set in sets"
        :key="set.id"
        class="relative border-l-4 pl-6 py-2 flex flex-col gap-4 transition-all"
        :class="set.isComplete ? 'border-ink-black' : 'border-gray-300'"
      >
        <!-- Connector Line Visual -->
        <div
          class="absolute -left-[4px] top-0 bottom-0 w-1 bg-gradient-to-b from-black to-transparent opacity-10"
        ></div>

        <div class="flex justify-between items-start">
          <div>
            <h3
              class="text-xl font-bold font-serif uppercase tracking-wider relative inline-block"
            >
              {{ set.name }}
              <span
                class="absolute -bottom-1 left-0 w-full h-[2px] bg-yellow-200"
                v-if="!set.isComplete"
              ></span>
              <span
                class="absolute -bottom-1 left-0 w-full h-[2px] bg-green-200"
                v-else
              ></span>
            </h3>
            <div class="text-[10px] font-mono text-gray-400 mt-1">
              CASE_ID: {{ set.id.toUpperCase() }}
            </div>
          </div>

          <div class="text-right">
            <div class="border border-black px-2 py-1 text-center min-w-[80px]">
              <div class="text-[9px] uppercase font-bold text-gray-500">
                Reward Value
              </div>
              <div class="text-lg font-bold">{{ set.rewardScrap }}</div>
            </div>
          </div>
        </div>

        <!-- Evidence Grid -->
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
          <div
            v-for="item in set.items"
            :key="item.id"
            class="p-2 border text-[10px] font-bold uppercase flex items-center gap-2 shadow-sm"
            :class="[
              item.isCollected
                ? 'bg-white text-ink-black border-black/20'
                : 'bg-gray-100 text-gray-400 border-dashed border-gray-300',
            ]"
          >
            <!-- Checkbox visual -->
            <div
              class="w-3 h-3 border border-black flex items-center justify-center bg-white"
            >
              <span
                v-if="item.isCollected"
                class="text-xs font-black leading-none transform -translate-y-[1px]"
                >✓</span
              >
            </div>
            <span class="truncate">{{ item.name }}</span>
          </div>
        </div>

        <!-- Action Area -->
        <div class="flex justify-start pt-2">
          <button
            v-if="!set.isClaimed"
            @click="claim(set.id, set.rewardScrap)"
            :disabled="!set.isComplete"
            class="px-6 py-2 font-bold uppercase border-2 text-xs transition-all relative overflow-hidden"
            :class="[
              set.isComplete
                ? 'bg-white border-black text-black hover:bg-black hover:text-white shadow-[4px_4px_0_0_#000]'
                : 'bg-gray-100 border-gray-300 text-gray-500 cursor-not-allowed',
            ]"
          >
            {{ set.isComplete ? "SUBMIT COMPLETED SET" : "AWAITING EVIDENCE" }}
          </button>

          <div
            v-else
            class="stamp-box border-green-600 text-green-700 -rotate-3 text-sm"
          >
            BOUNTY PAID
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
