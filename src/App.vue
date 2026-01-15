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
import WorldEventBanner from "@/components/events/WorldEventBanner.vue";
import MuseumView from "@/components/museum/MuseumView.vue";
import InfluenceShop from "@/components/shop/InfluenceShop.vue";

const store = useGameStore();
type Deck =
  | "FIELD"
  | "LAB"
  | "WORKSHOP"
  | "COLLECTIONS"
  | "BAZAAR"
  | "MUSEUM"
  | "SHOP";
const currentDeck = ref<Deck>("FIELD");

const setDeck = (deck: Deck) => {
  currentDeck.value = deck;
  store.addLog(`Opened file: ${deck}`);
};
</script>

<template>
  <div
    class="min-h-screen p-2 md:p-6 mx-auto max-w-[1400px] flex flex-col gap-4 text-ink-black"
  >
    <!-- World Event Banner -->
    <WorldEventBanner />

    <!-- Main Container - Looks like a large clipboard or desk surface -->
    <div class="flex flex-col gap-6">
      <!-- Header: The "Letterhead" -->
      <Header />

      <!-- Navigation Tabs: File Folder look -->
      <nav
        class="flex px-4 border-b-2 border-ink-black gap-1 translate-y-[2px] z-10 flex-wrap"
      >
        <button
          v-for="deck in ['FIELD', 'LAB', 'WORKSHOP', 'COLLECTIONS', 'BAZAAR', 'MUSEUM', 'SHOP'] as Deck[]"
          :key="deck"
          @click="setDeck(deck)"
          :class="[
            'px-6 py-2 font-serif font-bold text-sm uppercase border-t-2 border-l-2 border-r-2 border-ink-black rounded-t-md transition-all',
            currentDeck === deck
              ? 'bg-[#FDFDFB] translate-y-[2px] pb-3 z-20'
              : 'bg-[#D6D6C2] text-gray-800 hover:bg-[#EBEBE0] hover:text-black mb-[2px]',
          ]"
        >
          <span
            class="mr-2 opacity-60 text-xs font-sans text-ink-black font-bold"
            >REF:{{
              String(
                [
                  "FIELD",
                  "LAB",
                  "WORKSHOP",
                  "COLLECTIONS",
                  "BAZAAR",
                  "MUSEUM",
                  "SHOP",
                ].indexOf(deck) + 1
              ).padStart(2, "0")
            }}</span
          >
          {{ deck }}
        </button>
      </nav>

      <!-- Main Workspace: The "Paper Page" -->
      <main
        class="grid grid-cols-1 lg:grid-cols-12 gap-8 paper-panel p-6 -mt-6 z-0 min-h-[700px]"
      >
        <!-- Ledger Grid Background Overlay -->
        <div
          class="absolute inset-0 ledger-grid-bg pointer-events-none opacity-50 z-[-1]"
        ></div>

        <!-- Left Workspace (Main Task) -->
        <section
          class="lg:col-span-8 flex flex-col h-full bg-white/50 border border-gray-300 p-4 shadow-inner"
        >
          <div class="flex-1 flex flex-col">
            <FieldView v-if="currentDeck === 'FIELD'" />
            <LabView v-if="currentDeck === 'LAB'" />
            <WorkshopView v-if="currentDeck === 'WORKSHOP'" />
            <CollectionsView v-if="currentDeck === 'COLLECTIONS'" />
            <BazaarView v-if="currentDeck === 'BAZAAR'" />
            <MuseumView v-if="currentDeck === 'MUSEUM'" />
            <InfluenceShop v-if="currentDeck === 'SHOP'" />
          </div>
        </section>

        <!-- Right Workspace (The "Notepad" Side) -->
        <aside class="lg:col-span-4 flex flex-col gap-6 h-full">
          <!-- Activity Feed: Ticker Tape Style -->
          <div
            class="h-64 paper-card p-3 relative overflow-hidden bg-[#FAF9F6]"
          >
            <!-- "Tape" visual -->
            <div
              class="absolute top-0 left-0 right-0 h-4 bg-[repeating-linear-gradient(45deg,#ddd,#ddd_10px,#eee_10px,#eee_20px)] border-b border-gray-300"
            ></div>
            <div class="mt-4 h-full">
              <ActivityFeed />
            </div>
          </div>

          <!-- Action Log: Typed Manifest -->
          <div
            class="flex-1 min-h-[250px] paper-card p-3 bg-white font-mono text-xs border-t-4 border-black"
          >
            <TerminalLog />
          </div>

          <!-- Vault View: Mini Reference Card -->
          <div
            class="h-80 paper-card p-2 bg-[#F5F5F0] border-2 border-dashed border-gray-400"
          >
            <VaultView />
          </div>
        </aside>
      </main>

      <!-- Footer: Stamped Footer -->
      <footer
        class="mt-4 border-t-2 border-black border-dashed pt-4 flex justify-between items-center text-xs font-mono text-gray-600 uppercase"
      >
        <div class="flex items-center gap-4">
          <span>System_Ref: {{ new Date().toLocaleDateString() }}</span>
          <span
            >Session_ID:
            {{ Math.random().toString(36).substring(7).toUpperCase() }}</span
          >
        </div>
        <div class="flex gap-4 items-center">
          <span
            >Relics_Catalogued:
            <b class="text-black">{{ store.uniqueItemsFound }}/20</b></span
          >
          <span class="stamp-box text-[10px] scale-75 border-2">APPROVED</span>
        </div>
      </footer>
    </div>
  </div>
</template>

<style>
/* Global overrides that might be specific to main layout structure */
body {
  background-color: #f5f5f0;
}
</style>
