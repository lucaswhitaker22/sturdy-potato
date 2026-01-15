<script setup lang="ts">
import { ref, onMounted, computed } from "vue";
import { useGameStore } from "@/stores/game";

const store = useGameStore();
const activeTab = ref<"MARKET" | "SELL">("MARKET");

onMounted(() => {
  store.fetchMarket();
});

const refreshMarket = () => {
  store.fetchMarket();
};

const formatMint = (num: number | null | undefined) => {
  if (num === null || num === undefined) return "GEN-0";
  return `#${num}`;
};

// Bidding Logic
const handleBid = async (listing: any) => {
  const minBid = (listing.highest_bid || listing.reserve_price) + 1;
  // Simple prompt for MVP - can be replaced with modal
  const bidStr = prompt(
    `Place bid on ${listing.item_id.toUpperCase()}?\nMinimum: ${minBid} Scrap\nYour Balance: ${
      store.scrapBalance
    }`,
    minBid.toString()
  );

  if (!bidStr) return;
  const amount = parseInt(bidStr);

  if (isNaN(amount) || amount < minBid) {
    alert("Invalid bid amount.");
    return;
  }

  if (amount > store.scrapBalance) {
    alert("Insufficient funds.");
    return;
  }

  await store.placeBid(listing.id, amount);
  store.fetchMarket();
};

// Selling Logic
const sellPrice = ref(100);
const selectedSellItem = ref<string | null>(null);

const handleList = async () => {
  if (!selectedSellItem.value) return;

  if (sellPrice.value < 0) {
    alert("Price cannot be negative.");
    return;
  }

  const success = await store.listItem(selectedSellItem.value, sellPrice.value);
  if (success) {
    selectedSellItem.value = null;
    activeTab.value = "MARKET";
    store.fetchMarket();
    alert("Item listed successfully.");
  }
};

const sellableItems = computed(() => [...store.inventory].reverse());
</script>

<template>
  <div
    class="h-full flex flex-col bg-black text-white p-6 relative overflow-hidden"
  >
    <!-- Header -->
    <div
      class="flex justify-between items-end border-b-4 border-white pb-4 mb-6"
    >
      <div>
        <h2 class="text-4xl font-black uppercase italic tracking-tighter">
          > BAZAAR_NET
        </h2>
        <p class="text-xs font-mono text-zinc-500 mt-2">
          GLOBAL_TRADE_ROUTER // LATENCY: 12ms
        </p>
      </div>
      <div class="text-right">
        <div class="text-xs font-mono text-zinc-500">YOUR_LIQUIDITY</div>
        <div class="text-3xl font-black text-brutalist-green">
          {{ store.scrapBalance }} SCRAP
        </div>
      </div>
    </div>

    <!-- Tabs -->
    <div class="flex gap-4 mb-6">
      <button
        @click="activeTab = 'MARKET'"
        :class="[
          'px-6 py-2 font-black uppercase text-sm border-2 transition-all',
          activeTab === 'MARKET'
            ? 'bg-white text-black border-white translate-x-1'
            : 'bg-black text-white border-zinc-700 hover:border-white',
        ]"
      >
        Live_Auctions
      </button>
      <button
        @click="activeTab = 'SELL'"
        :class="[
          'px-6 py-2 font-black uppercase text-sm border-2 transition-all',
          activeTab === 'SELL'
            ? 'bg-white text-black border-white translate-x-1'
            : 'bg-black text-white border-zinc-700 hover:border-white',
        ]"
      >
        Create_Listing
      </button>
      <button
        @click="refreshMarket"
        class="px-4 py-2 ml-auto font-mono text-xs border text-zinc-500 border-zinc-800 hover:text-white"
      >
        REFRESH_FEED
      </button>
    </div>

    <!-- Market View -->
    <div
      v-if="activeTab === 'MARKET'"
      class="flex-1 overflow-y-auto custom-scrollbar"
    >
      <div
        v-if="store.activeListings.length === 0"
        class="text-zinc-600 font-mono text-center mt-20"
      >
        NO SIGNAL DETECTED. MARKET IS QUIET.
      </div>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div
          v-for="listing in store.activeListings"
          :key="listing.id"
          class="border-2 border-zinc-800 p-4 hover:border-brutalist-yellow transition-colors group"
        >
          <div class="flex justify-between items-start mb-2">
            <div class="font-black text-xl uppercase">
              {{ listing.item_id }}
            </div>
            <div
              class="bg-zinc-900 text-zinc-400 px-2 py-1 text-xs font-mono rounded"
            >
              {{ formatMint(listing.mint_number) }}
            </div>
          </div>

          <div class="space-y-1 my-4 font-mono text-xs text-zinc-400">
            <div class="flex justify-between">
              <span>Reserve:</span>
              <span class="text-white">{{ listing.reserve_price }}</span>
            </div>
            <div class="flex justify-between">
              <span>Highest Bid:</span>
              <span class="text-brutalist-green font-bold">{{
                listing.highest_bid || "--"
              }}</span>
            </div>
            <div class="flex justify-between">
              <span>Ends In:</span>
              <span>{{ new Date(listing.ends_at).toLocaleDateString() }}</span>
            </div>
          </div>

          <button
            @click="handleBid(listing)"
            class="w-full bg-zinc-900 text-white font-black uppercase py-2 hover:bg-brutalist-yellow hover:text-black transition-colors"
          >
            PLACE_BID
          </button>
        </div>
      </div>
    </div>

    <!-- Sell View -->
    <div
      v-if="activeTab === 'SELL'"
      class="flex-1 overflow-y-auto custom-scrollbar flex gap-6"
    >
      <!-- Inventory List -->
      <div class="w-1/2 border-r-2 border-zinc-900 pr-4">
        <div class="text-xs font-mono text-zinc-500 mb-4">
          SELECT_ITEM_TO_LIST
        </div>
        <div class="space-y-2">
          <div
            v-for="item in sellableItems"
            :key="item.id"
            @click="selectedSellItem = item.id"
            :class="[
              'cursor-pointer p-3 border border-zinc-800 flex justify-between items-center transition-all',
              selectedSellItem === item.id
                ? 'bg-zinc-800 border-white'
                : 'hover:border-zinc-700',
            ]"
          >
            <span class="font-bold text-sm uppercase">{{ item.item_id }}</span>
            <span class="text-xs font-mono text-zinc-500">{{
              formatMint(item.mint_number)
            }}</span>
          </div>
        </div>
      </div>

      <!-- Listing Form -->
      <div class="w-1/2 flex flex-col justify-center">
        <div
          v-if="selectedSellItem"
          class="p-6 border-4 border-white bg-zinc-900/50"
        >
          <h3 class="text-2xl font-black mb-6 uppercase">Confirm Listing</h3>

          <div class="mb-6">
            <label class="block text-xs font-mono text-zinc-500 mb-2"
              >RESERVE_PRICE (SCRAP)</label
            >
            <input
              v-model="sellPrice"
              type="number"
              class="w-full bg-black border-2 border-zinc-700 p-4 text-2xl font-mono focus:border-brutalist-yellow outline-none"
            />
          </div>

          <div class="text-xs font-mono text-zinc-500 mb-6">
            * Listing duration is fixed at 24 hours.
            <br />* Listing fee: 0 Scrap (Standard License).
          </div>

          <button
            @click="handleList"
            class="w-full bg-white text-black font-black uppercase py-4 text-xl hover:bg-brutalist-green hover:text-white transition-all hover:-translate-y-1 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
          >
            PUBLISH_TO_NETWORK
          </button>
        </div>
        <div v-else class="text-center text-zinc-700 font-mono italic">
          Select an artifact from the manifest...
        </div>
      </div>
    </div>
  </div>
</template>
