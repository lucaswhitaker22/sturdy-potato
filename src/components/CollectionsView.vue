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
  <div
    class="p-6 flex flex-col gap-6 h-full overflow-y-auto custom-scrollbar bg-black text-white"
  >
    <div class="border-b-4 border-white pb-4 mb-4">
      <h2 class="text-4xl font-black uppercase tracking-tighter italic">
        > ARCHIVE_SETS
      </h2>
      <p class="text-xs font-mono text-zinc-500 mt-2 uppercase">
        Reconstruct the past for material rewards. Completeness is power.
      </p>
    </div>

    <div class="flex flex-col gap-8">
      <div
        v-for="set in sets"
        :key="set.id"
        class="border-l-8 border-white pl-6 py-2 flex flex-col gap-4"
      >
        <div class="flex justify-between items-start">
          <div>
            <h3 class="text-2xl font-black uppercase">{{ set.name }}</h3>
            <span class="text-[10px] font-mono text-zinc-500">
              SET_ID: {{ set.id.toUpperCase() }} // STATUS:
              <span
                :class="
                  set.isComplete ? 'text-brutalist-green' : 'text-brutalist-red'
                "
              >
                {{ set.isComplete ? "VERIFIED" : "INCOMPLETE" }}
              </span>
            </span>
          </div>
          <div class="text-right">
            <span class="block text-[10px] font-mono text-zinc-500 uppercase"
              >REWARD:</span
            >
            <span class="text-xl font-black text-brutalist-yellow"
              >{{ set.rewardScrap }} SCRAP</span
            >
          </div>
        </div>

        <!-- Item Grid -->
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2">
          <div
            v-for="item in set.items"
            :key="item.id"
            :class="[
              'p-2 border-2 text-[10px] font-black uppercase flex items-center gap-2',
              item.isCollected
                ? 'bg-white text-black border-white'
                : 'bg-zinc-900 text-zinc-600 border-zinc-800',
            ]"
          >
            <div
              :class="[
                'w-2 h-2',
                item.isCollected ? 'bg-black' : 'bg-zinc-700',
              ]"
            ></div>
            {{ item.name }}
          </div>
        </div>

        <button
          v-if="!set.isClaimed"
          @click="claim(set.id, set.rewardScrap)"
          :disabled="!set.isComplete"
          :class="[
            'w-fit px-8 py-2 font-black uppercase border-2 transition-all',
            set.isComplete
              ? 'bg-brutalist-green text-black border-brutalist-green hover:-translate-y-1 shadow-[4px_4px_0px_0px_rgba(255,255,255,1)]'
              : 'bg-zinc-800 text-zinc-500 border-zinc-800 cursor-not-allowed opacity-50',
          ]"
        >
          {{ set.isComplete ? "CLAIM_DATA_REWARD" : "DATA_VARY_MISMATCH" }}
        </button>
        <div
          v-else
          class="text-xs font-black text-brutalist-green flex items-center gap-2 italic uppercase"
        >
          <span class="text-xl">✓</span> REWARDED_ARCHIVE_LOCKED
        </div>
      </div>
    </div>
  </div>
</template>
