<script setup lang="ts">
import { ref } from "vue";
import { useGameStore } from "@/stores/game";
import Header from "@/components/Header.vue";
import FieldView from "@/components/FieldView.vue";
import LabView from "@/components/LabView.vue";
import VaultView from "@/components/VaultView.vue";
import WorkshopView from "@/components/WorkshopView.vue";
import CollectionsView from "@/components/CollectionsView.vue";
import BazaarView from "@/components/BazaarView.vue";
import ActivityFeed from "@/components/ActivityFeed.vue";
import TerminalLog from "@/components/TerminalLog.vue";

const store = useGameStore();
type Deck = "FIELD" | "LAB" | "WORKSHOP" | "COLLECTIONS" | "BAZAAR";
const currentDeck = ref<Deck>("FIELD");

const setDeck = (deck: Deck) => {
  currentDeck.value = deck;
  store.addLog(`Switched to ${deck} deck.`);
};
</script>

<template>
  <div class="min-h-screen p-4 md:p-8 flex flex-col gap-6 max-w-7xl mx-auto">
    <!-- Header Section -->
    <Header />

    <!-- Navigation Tabs (Brutalist Style) -->
    <nav class="flex gap-2">
      <button
        @click="setDeck('FIELD')"
        :class="[
          'px-8 py-3 font-black uppercase border-t-4 border-l-4 border-r-4 border-white transition-all',
          currentDeck === 'FIELD'
            ? 'bg-white text-black translate-y-1'
            : 'bg-black text-white hover:bg-zinc-800',
        ]"
      >
        [01] THE FIELD
      </button>
      <button
        @click="setDeck('LAB')"
        :class="[
          'px-8 py-3 font-black uppercase border-t-4 border-l-4 border-r-4 border-white transition-all',
          currentDeck === 'LAB'
            ? 'bg-white text-black translate-y-1'
            : 'bg-black text-white hover:bg-zinc-800',
        ]"
      >
        [02] THE LAB
      </button>
      <button
        @click="setDeck('WORKSHOP')"
        :class="[
          'px-8 py-3 font-black uppercase border-t-4 border-l-4 border-r-4 border-white transition-all',
          currentDeck === 'WORKSHOP'
            ? 'bg-white text-black translate-y-1'
            : 'bg-black text-white hover:bg-zinc-800',
        ]"
      >
        [03] WORKSHOP
      </button>
      <button
        @click="setDeck('COLLECTIONS')"
        :class="[
          'px-8 py-3 font-black uppercase border-t-4 border-l-4 border-r-4 border-white transition-all',
          currentDeck === 'COLLECTIONS'
            ? 'bg-white text-black translate-y-1'
            : 'bg-black text-white hover:bg-zinc-800',
        ]"
      >
        [04] SETS
      </button>
      <button
        @click="setDeck('BAZAAR')"
        :class="[
          'px-8 py-3 font-black uppercase border-t-4 border-l-4 border-r-4 border-white transition-all',
          currentDeck === 'BAZAAR'
            ? 'bg-white text-black translate-y-1'
            : 'bg-black text-white hover:bg-zinc-800',
        ]"
      >
        [05] BAZAAR
      </button>
    </nav>

    <!-- Main Content Area -->
    <main
      class="flex-1 grid grid-cols-1 lg:grid-cols-12 gap-6 overflow-hidden min-h-[600px]"
    >
      <!-- Workspace Left (8/12 cols) -->
      <section
        class="lg:col-span-8 flex flex-col h-full border-4 border-white shadow-[12px_12px_0px_0px_rgba(255,255,255,1)]"
      >
        <div class="flex-1 flex flex-col">
          <FieldView v-if="currentDeck === 'FIELD'" />
          <LabView v-if="currentDeck === 'LAB'" />
          <WorkshopView v-if="currentDeck === 'WORKSHOP'" />
          <CollectionsView v-if="currentDeck === 'COLLECTIONS'" />
          <BazaarView v-if="currentDeck === 'BAZAAR'" />
        </div>
      </section>

      <!-- Sidebar Right (4/12 cols) -->
      <aside class="lg:col-span-4 flex flex-col gap-6 h-full">
        <!-- Activity Feed -->
        <div class="h-64 shadow-[8px_8px_0px_0px_rgba(236,72,153,0.3)]">
          <ActivityFeed />
        </div>

        <!-- Action Log -->
        <div
          class="flex-1 min-h-[250px] shadow-[8px_8px_0px_0px_rgba(74,222,128,0.3)]"
        >
          <TerminalLog />
        </div>

        <!-- Vault View -->
        <div class="h-80 shadow-[8px_8px_0px_0px_rgba(250,204,21,0.3)]">
          <VaultView />
        </div>
      </aside>
    </main>

    <!-- Footer Stats -->
    <footer
      class="border-t-2 border-white/20 pt-4 flex justify-between items-center text-[10px] font-mono uppercase text-gray-500 tracking-widest"
    >
      <div>SYSTEM_TIME: {{ new Date().toLocaleTimeString() }}</div>
      <div>CORE_AUTH: ANONYMOUS_SESSION</div>
      <div class="flex gap-4">
        <span>UNIQUE_RELICS: {{ store.uniqueItemsFound }}/20</span>
        <span class="text-brutalist-green">READY</span>
      </div>
    </footer>
  </div>
</template>

<style>
/* Global overrides for customs scrollbars */
.custom-scrollbar::-webkit-scrollbar {
  width: 6px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: #444;
  border-radius: 10px;
}
.custom-scrollbar::-webkit-scrollbar-thumb:hover {
  background: #666;
}
</style>
