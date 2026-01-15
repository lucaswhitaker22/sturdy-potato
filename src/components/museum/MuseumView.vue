<template>
  <div class="museum-view p-4 text-green-400 font-mono">
    <div v-if="isLoading" class="text-center">Loading Museum Archives...</div>

    <div
      v-else-if="!activeWeek"
      class="text-center border border-green-800 p-8"
    >
      <h2 class="text-xl">No Exhibition Currently Open</h2>
      <p class="mt-2 text-green-600">
        Please check back later for the next curatorial theme.
      </p>
    </div>

    <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <!-- Left Panel: Theme & Info -->
      <div class="border border-green-600 p-4 bg-black/50">
        <h2 class="text-2xl font-bold mb-2 glitch-text">
          {{ activeWeek.theme_name }}
        </h2>
        <p class="mb-4 text-sm whitespace-pre-wrap">
          {{ activeWeek.description }}
        </p>

        <div class="text-sm border-t border-green-800 pt-2 mt-4">
          <p>
            Exhibition Ends: {{ new Date(activeWeek.ends_at).toLocaleString() }}
          </p>
          <p class="mt-2">Submissions: {{ userSubmissions.length }} / 10</p>
        </div>
      </div>

      <!-- Right Panel: My Submissions -->
      <div class="border border-green-600 p-4">
        <h3 class="text-xl mb-4 text-green-300">My Contributions</h3>
        <ul v-if="userSubmissions.length > 0" class="space-y-2">
          <li
            v-for="sub in userSubmissions"
            :key="sub.vault_item_id"
            class="flex justify-between items-center bg-green-900/20 p-2 border border-green-800"
          >
            <span
              >{{ sub.item_details.item_id }} #{{
                sub.item_details.mint_number
              }}</span
            >
            <span class="text-yellow-400 font-bold">{{ sub.score }} HV</span>
          </li>
        </ul>
        <div v-else class="text-green-700 italic">
          You have not submitted any relics yet.
        </div>
      </div>
    </div>

    <!-- Submission Interface -->
    <div v-if="activeWeek" class="mt-6 border-t-2 border-green-800 pt-6">
      <h3 class="text-xl mb-4">Eligible Artifacts from Vault</h3>
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div
          v-for="item in availableItems"
          :key="item.id"
          class="border border-green-700 p-3 hover:bg-green-900/30 cursor-pointer transition-colors"
          @click="submit(item)"
        >
          <div class="font-bold">{{ item.item_id }}</div>
          <div class="text-xs text-green-500">Mint #{{ item.mint_number }}</div>
          <button
            class="mt-2 w-full bg-green-800 text-green-100 text-xs py-1 hover:bg-green-700"
          >
            Submit
          </button>
        </div>
      </div>
      <div v-if="availableItems.length === 0" class="text-green-700">
        No available items found in your vault.
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, computed } from "vue";
import { useMuseumStore } from "@/stores/museum";
import { useGameStore } from "@/stores/game";
import { storeToRefs } from "pinia";

const museumStore = useMuseumStore();
const gameStore = useGameStore();

const { activeWeek, userSubmissions, isLoading } = storeToRefs(museumStore);
const { inventory } = storeToRefs(gameStore);

onMounted(() => {
  museumStore.fetchActiveWeek();
});

// Filter items that are NOT already submitted
const availableItems = computed(() => {
  const submittedIds = new Set(
    userSubmissions.value.map((s) => s.vault_item_id)
  );
  return inventory.value.filter((i) => !submittedIds.has(i.id));
});

async function submit(item: any) {
  if (
    !confirm(
      `Submit ${item.item_id} to the Museum? It will be locked until the exhibition ends.`
    )
  )
    return;
  await museumStore.submitItem(item.id);
}
</script>

<style scoped>
.glitch-text {
  text-shadow: 2px 2px #0f0, -1px -1px #f0f;
}
</style>
