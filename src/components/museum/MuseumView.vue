<template>
  <div class="h-full p-4 font-serif text-ink-black flex flex-col gap-6">
    <div
      v-if="isLoading"
      class="text-center font-mono text-sm animate-pulse mt-20"
    >
      Accessing Curatorial Archives...
    </div>

    <div
      v-else-if="!activeWeek"
      class="text-center border-2 border-double border-gray-400 p-12 bg-[#fafafa]"
    >
      <div
        class="w-16 h-16 border-4 border-gray-300 rounded-full mx-auto mb-4 flex items-center justify-center text-2xl text-gray-300"
      >
        🏛️
      </div>
      <h2 class="text-xl font-bold uppercase tracking-widest text-gray-500">
        Exhibit Closed
      </h2>
      <p class="mt-2 text-sm text-gray-400 font-mono italic">
        The gallery is currently being rotated. Check back for the next
        curatorial theme.
      </p>
    </div>

    <div v-else class="flex flex-col gap-6 h-full">
      <!-- Exhibition Poster Header -->
      <div
        class="border-4 border-ink-black p-6 bg-white shadow-lg relative overflow-hidden"
      >
        <!-- Background Texture -->
        <div
          class="absolute inset-0 opacity-5 bg-[url('https://www.transparenttextures.com/patterns/linen.png')]"
        ></div>

        <!-- Decorative Corner -->
        <div
          class="absolute top-0 right-0 w-16 h-16 bg-black transform rotate-45 translate-x-8 -translate-y-8"
        ></div>

        <div class="relative z-10 flex justify-between items-start">
          <div>
            <span
              class="block text-xs font-mono uppercase tracking-[0.2em] mb-2 text-gray-600"
              >Current Exhibition</span
            >
            <h2
              class="text-4xl font-black uppercase leading-none tracking-tighter mb-4 border-b-2 border-black inline-block pb-1"
            >
              {{ activeWeek.theme_name }}
            </h2>
            <p
              class="text-sm max-w-2xl font-serif leading-relaxed text-gray-800 border-l-2 border-gray-300 pl-4 italic"
            >
              "{{ activeWeek.description }}"
            </p>
          </div>

          <div class="flex flex-col gap-2">
            <div
              class="text-right font-mono text-xs border border-black p-2 bg-gray-50 transform rotate-1 shadow-sm"
            >
              <p class="font-bold border-b border-gray-200 pb-1 mb-1">
                EXHIBIT DETAILS
              </p>
              <p>
                Closes: {{ new Date(activeWeek.ends_at).toLocaleDateString() }}
              </p>
              <p>Capacity: {{ userSubmissions.length }} / 10 Spots</p>
            </div>

            <!-- Score Badge -->
            <div
              class="bg-ink-black text-white p-2 text-right transform -rotate-1 shadow-md"
            >
              <div
                class="text-[10px] uppercase font-mono tracking-widest text-gray-400"
              >
                Historical Influence
              </div>
              <div class="text-2xl font-black text-yellow-500">
                {{ gameStore.historicalInfluence.toLocaleString() }}
              </div>
              <div
                class="text-[10px] uppercase font-mono tracking-widest text-gray-400 mt-2"
              >
                Current Week Score
              </div>
              <div class="text-xl font-black">
                {{ totalScore.toLocaleString() }}
              </div>
              <div
                v-if="setBonusActive"
                class="text-[9px] bg-yellow-400 text-black px-1 font-bold inline-block mt-1"
              >
                SET BONUS ACTIVE (1.5x)
              </div>
            </div>

          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-8 flex-1 min-h-0">
        <!-- My Submissions (Contributor Log) -->
        <div
          class="border border-gray-300 p-4 bg-[#FDFDFB] flex flex-col h-full shadow-sm"
        >
          <h3
            class="text-lg font-bold uppercase border-b border-black pb-2 mb-4 flex justify-between items-center"
          >
            <span>Contributor Log</span>
            <span
              class="text-[10px] font-mono bg-black text-white px-2 py-0.5 rounded-full"
              >{{ userSubmissions.length }} Entries</span
            >
          </h3>

          <ul
            v-if="userSubmissions.length > 0"
            class="space-y-4 flex-1 overflow-y-auto pr-2 custom-scrollbar"
          >
            <li
              v-for="sub in userSubmissions"
              :key="sub.vault_item_id"
              class="flex justify-between items-center p-3 border border-gray-200 bg-white hover:border-gray-400 transition-colors shadow-sm"
            >
              <div class="flex flex-col">
                <span class="font-bold uppercase text-sm">{{
                  sub.item_details.item_id
                }}</span>
                <span class="text-[10px] font-mono text-gray-500"
                  >MINT #{{ sub.item_details.mint_number }}</span
                >
              </div>
              <div class="flex flex-col items-end">
                <span class="font-black text-lg">{{ sub.score }}</span>
                <span class="text-[9px] uppercase font-mono text-gray-400"
                  >Appraisal Value</span
                >
              </div>
            </li>
          </ul>
          <div v-else class="text-center py-10 text-gray-500 italic">
            No contributions recorded in the log.
          </div>
        </div>

        <!-- Submission Interface (Eligible Artifacts) -->
        <div
          class="border-2 border-dashed border-gray-300 p-4 flex flex-col h-full bg-gray-50"
        >
          <h3
            class="text-lg font-bold uppercase border-b border-gray-300 pb-2 mb-4 text-gray-700"
          >
            Available for Loan
          </h3>

          <div class="flex-1 overflow-y-auto pr-2 custom-scrollbar">
            <div
              v-if="availableItems.length === 0"
              class="text-gray-500 text-center py-8 italic font-serif"
            >
              No eligible artifacts currently in vault storage.
            </div>

            <div v-else class="grid grid-cols-2 gap-4">
              <div
                v-for="item in availableItems"
                :key="item.id"
                class="bg-white border border-gray-200 p-3 cursor-pointer hover:shadow-md hover:border-black transition-all group"
                @click="submit(item)"
              >
                <div class="font-bold text-sm uppercase mb-1">
                  {{ item.item_id }}
                </div>
                <div class="text-[10px] font-mono text-gray-600 mb-3">
                  Mint #{{ item.mint_number }}
                </div>
                <button
                  class="w-full border border-black text-black text-[10px] font-bold uppercase py-1 group-hover:bg-black group-hover:text-white transition-colors"
                >
                  Prepare for Transport
                </button>
              </div>
            </div>
          </div>
        </div>
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

const { activeWeek, userSubmissions, isLoading, totalScore, setBonusActive } =
  storeToRefs(museumStore);
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
      `Loan ${item.item_id} to the Museum? It will be locked until the exhibition ends.`
    )
  )
    return;
  const result = await museumStore.submitItem(item.id);
  if (result) {
    gameStore.addLog(`MUSEUM: ${item.item_id} loaned. Entry Score: ${result.score}`);
  }
}
</script>

<style scoped>
/* Scoped styles replaced by Tailwind classes */
</style>
