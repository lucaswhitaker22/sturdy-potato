<script setup lang="ts">
import { ref, onMounted, computed } from "vue";
import { useGameStore } from "@/stores/game";
import { useMMOStore } from "@/stores/mmo";

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
  const bidStr = prompt(
    `SUBMIT BID FOR LOT: ${listing.item_id.toUpperCase()}?\nMinimum: ${minBid} Scrap\nYour Funds: ${
      store.scrapBalance
    }`,
    minBid.toString()
  );

  if (!bidStr) return;
  const amount = parseInt(bidStr);

  if (isNaN(amount) || amount < minBid) {
    alert("BID REJECTED: INVALID AMOUNT.");
    return;
  }

  if (amount > store.scrapBalance) {
    alert("BID REJECTED: INSUFFICIENT FUNDS.");
    return;
  }

  await store.placeBid(listing.id, amount);
  store.fetchMarket();
};

// Settlement Logic
const mmoStore = useMMOStore();
const handleSettle = async (listing: any) => {
  const result = await mmoStore.settleListing(listing.id);
  if (result && result.success) {
    alert(`SETTLEMENT COMPLETE: ${result.outcome.toUpperCase()}`);
    store.fetchMarket();
  } else {
    alert("SETTLEMENT FAILED.");
  }
};

const isExpired = (ends_at: string) => {
  return new Date(ends_at) < new Date();
};

// Selling Logic
const sellPrice = ref(100);
const selectedSellItem = ref<string | null>(null);

const handleList = async () => {
  if (!selectedSellItem.value) return;

  if (sellPrice.value < 0) {
    alert("ERROR: Negative Valuation.");
    return;
  }

  if (store.scrapBalance < 50) {
    alert("ERROR: Insufficient funds for listing deposit (50 Scrap).");
    return;
  }

  if (
    !confirm(
      `List ${selectedSellItem.value} for ${sellPrice.value} Scrap?\nDeposit of 50 Scrap will be deducted.`
    )
  ) {
    return;
  }

  const success = await store.listItem(selectedSellItem.value, sellPrice.value);
  if (success) {
    selectedSellItem.value = null;
    activeTab.value = "MARKET";
    store.fetchMarket();
    alert("CONSIGNMENT ACCEPTED.");
  }
};

const sellableItems = computed(() => [...store.inventory].reverse());
</script>

<template>
  <div class="h-full flex flex-col p-6 h-full p-2">
    <!-- Header -->
    <div
      class="flex justify-between items-end border-b-2 border-black pb-2 mb-4"
    >
      <div>
        <h2
          class="text-2xl font-serif font-black uppercase text-ink-black tracking-tight"
        >
          Public Auction House
        </h2>
        <!-- TICKER START -->
        <div
          class="mt-1 bg-black text-white px-2 py-0.5 text-[10px] font-mono uppercase overflow-hidden whitespace-nowrap w-full max-w-md relative"
        >
          <div
            class="inline-block animate-marquee"
            :style="{ animationDuration: '20s' }"
          >
            <span v-if="mmoStore.feed.length === 0"
              >WAITING FOR NETWORK SIGNAL...</span
            >
            <span
              v-else
              v-for="(event, idx) in mmoStore.feed"
              :key="event.id"
              class="mr-8"
            >
              <span class="text-yellow-400 font-bold"
                >[{{ event.event_type }}]</span
              >
              {{ event.user_id.substring(0, 6) }}
              <span v-if="event.event_type === 'listing'"
                >LISTED {{ event.details.item_id }} FOR
                {{ event.details.price }} SCRAP</span
              >
              <span v-else-if="event.event_type === 'sale'"
                >SOLD {{ event.details.item_id }} FOR
                {{ event.details.price }} SCRAP</span
              >
              <span v-else-if="event.event_type === 'find'"
                >FOUND {{ event.details.item_id }} (HV:
                {{ event.details.hv }})</span
              >
              <span v-else>updated the ledger</span>
            </span>
          </div>
        </div>
        <!-- TICKER END -->
      </div>
      <div class="border border-black p-2 bg-white">
        <div
          class="text-[9px] font-mono text-gray-500 uppercase tracking-widest text-right"
        >
          Available Liquidity
        </div>
        <div class="text-xl font-bold font-serif text-right mt-1">
          {{ store.scrapBalance.toLocaleString() }}
          <span class="text-xs text-gray-500">SCRAP</span>
        </div>
      </div>
    </div>

    <!-- Tabs -->
    <div class="flex gap-2 mb-4 border-b border-gray-300">
      <button
        @click="activeTab = 'MARKET'"
        class="px-6 py-2 font-bold uppercase text-sm border-t border-l border-r rounded-t-sm transition-all relative top-[1px]"
        :class="
          activeTab === 'MARKET'
            ? 'bg-[#FDFDFB] border-black border-b-white z-10'
            : 'bg-gray-100 border-gray-300 text-gray-500 hover:bg-gray-50'
        "
      >
        Live Lots
      </button>
      <button
        @click="activeTab = 'SELL'"
        class="px-6 py-2 font-bold uppercase text-sm border-t border-l border-r rounded-t-sm transition-all relative top-[1px]"
        :class="
          activeTab === 'SELL'
            ? 'bg-[#FDFDFB] border-black border-b-white z-10'
            : 'bg-gray-100 border-gray-300 text-gray-500 hover:bg-gray-50'
        "
      >
        Consign Item
      </button>

      <button
        @click="refreshMarket"
        class="ml-auto text-[10px] font-mono uppercase text-blue-600 hover:underline flex items-center gap-1"
      >
        <span>↻</span> Sync Ledger
      </button>
    </div>

    <!-- Market View -->
    <div
      v-if="activeTab === 'MARKET'"
      class="flex-1 overflow-y-auto custom-scrollbar bg-white border border-gray-200 p-4 shadow-inner"
    >
      <div
        v-if="store.activeListings.length === 0"
        class="text-gray-400 font-serif italic text-center mt-20"
      >
        -- No active lots currently on the block --
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div
          v-for="listing in store.activeListings"
          :key="listing.id"
          class="border-2 border-dashed border-gray-300 p-4 hover:border-black transition-colors group relative bg-[#fafafa]"
        >
          <!-- Lot Number Stamp -->
          <div
            class="absolute -top-3 -left-3 bg-white border border-black px-2 py-0.5 text-[10px] font-bold shadow-sm transform -rotate-3 group-hover:rotate-0 transition-transform"
          >
            LOT #{{ listing.id.substring(0, 4).toUpperCase() }}
          </div>

          <div class="flex justify-between items-start mb-4 mt-2">
            <h3
              class="font-bold text-lg font-serif uppercase tracking-wide border-b border-gray-200 pb-1 w-full"
            >
              {{ listing.item_id }}
            </h3>
            <span
              class="text-[10px] font-mono text-gray-500 absolute top-4 right-4"
            >
              {{ formatMint(listing.mint_number) }}
            </span>
          </div>

          <div
            class="space-y-2 mb-4 font-mono text-xs text-gray-800 bg-white p-2 border border-gray-200"
          >
            <div class="flex justify-between border-b border-gray-200 pb-1">
              <span class="text-gray-600">Reserve Price:</span>
              <span class="font-bold">{{ listing.reserve_price }}</span>
            </div>
            <div class="flex justify-between border-b border-gray-200 pb-1">
              <span class="text-gray-600">Current Bid:</span>
              <span
                class="font-bold bg-yellow-100 px-1 border border-yellow-200"
                >{{ listing.highest_bid || "--" }}</span
              >
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600">Closes:</span>
              <span class="font-bold">{{
                new Date(listing.ends_at).toLocaleDateString()
              }}</span>
            </div>
          </div>

          <button
            v-if="!isExpired(listing.ends_at)"
            @click="handleBid(listing)"
            class="w-full border-2 border-black text-black font-bold uppercase py-2 hover:bg-black hover:text-white transition-all text-xs tracking-widest"
          >
            Submit Bid
          </button>
          <button
            v-else
            @click="handleSettle(listing)"
            class="w-full border-2 border-red-800 text-red-800 font-bold uppercase py-2 hover:bg-red-800 hover:text-white transition-all text-xs tracking-widest bg-red-50"
          >
            Settle Auction
          </button>
        </div>
      </div>
    </div>

    <!-- Sell View -->
    <div
      v-if="activeTab === 'SELL'"
      class="flex-1 overflow-y-auto custom-scrollbar flex gap-6 bg-white border border-gray-200 p-4"
    >
      <!-- Inventory List -->
      <div class="w-1/2 border-r border-gray-200 pr-4">
        <div
          class="text-xs font-serif font-bold text-gray-500 mb-4 uppercase tracking-widest border-b border-gray-100 pb-2"
        >
          Select Artifact for Consignment
        </div>
        <div class="space-y-2">
          <div
            v-for="item in sellableItems"
            :key="item.id"
            @click="selectedSellItem = item.id"
            :class="[
              'cursor-pointer p-3 border flex justify-between items-center transition-all hover:shadow-sm',
              selectedSellItem === item.id
                ? 'bg-gray-50 border-black shadow-md'
                : 'bg-white border-gray-200 hover:border-gray-300',
            ]"
          >
            <span class="font-bold text-xs uppercase font-serif">{{
              item.item_id
            }}</span>
            <span
              class="text-[10px] font-mono text-gray-500 bg-gray-100 px-1 rounded"
              >{{ formatMint(item.mint_number) }}</span
            >
          </div>
        </div>
      </div>

      <!-- Listing Form -->
      <div class="w-1/2 flex flex-col justify-center pl-4 bg-[#f9f9f9]">
        <div v-if="selectedSellItem" class="p-4">
          <h3
            class="text-xl font-serif font-black mb-6 uppercase border-b-2 border-black pb-2"
          >
            Consignment Form
          </h3>

          <div class="mb-6 bg-white p-4 border border-gray-200 shadow-sm">
            <label
              class="block text-[10px] font-bold text-gray-600 uppercase tracking-widest mb-2"
              >Set Reserve Price (Scrap)</label
            >
            <input
              v-model="sellPrice"
              type="number"
              class="w-full bg-gray-50 border-b-2 border-gray-300 p-2 text-2xl font-mono focus:border-black focus:outline-none focus:bg-white transition-colors"
            />
          </div>

          <div
            class="text-[10px] font-mono text-gray-500 mb-6 italic border-l-2 border-gray-300 pl-2"
          >
            NOTICE: <br />
            * Auction duration fixed at 24 hours.<br />
            * Listing Deposit: 50 Scrap (Refunded if sold/expired).<br />
            * Archive Tax: 5% of final sale price.
          </div>

          <button
            @click="handleList"
            class="w-full bg-ink-black text-white font-bold uppercase py-3 hover:bg-gray-800 transition-all shadow-md active:translate-y-1 active:shadow-none"
          >
            Confirm & Publish Listing
          </button>
        </div>
        <div
          v-else
          class="text-center text-gray-400 font-serif italic border-2 border-dashed border-gray-200 p-12 rounded-lg"
        >
          Select an item from the manifest to begin consignment process.
        </div>
      </div>
    </div>
  </div>
</template>
