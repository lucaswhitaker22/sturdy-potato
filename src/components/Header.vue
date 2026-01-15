<script setup lang="ts">
import { useGameStore } from "@/stores/game";
import { TOOL_CATALOG } from "@/constants/items";
import { computed } from "vue";

const store = useGameStore();

const excavationProgress = computed(() => store.excavationXP % 100);
const restorationProgress = computed(() => store.restorationXP % 100);
const activeTool = computed(
  () => TOOL_CATALOG.find((t) => t.id === store.activeToolId) || TOOL_CATALOG[0]
);

const excavationBonus = computed(() =>
  (Math.floor(store.excavationLevel / 5) * 0.5).toFixed(1)
);
const restorationBonus = computed(() =>
  (store.restorationLevel * 0.1).toFixed(1)
);
</script>

<template>
  <header
    class="flex flex-col md:flex-row justify-between items-end border-b-4 border-double border-black pb-4 px-2"
  >
    <!-- Left: Title & Levels (The "Letterhead") -->
    <div class="flex flex-col gap-2">
      <div class="flex items-baseline gap-4">
        <h1 class="text-5xl font-serif font-bold tracking-tight text-ink-black">
          RELIC_VAULT
        </h1>
        <span
          class="text-xs font-mono bg-black text-white px-2 py-0.5 transform -rotate-2"
          >CONFIDENTIAL</span
        >
      </div>

      <!-- Level Progress "Stamps" -->
      <div class="flex gap-6 mt-2 font-mono text-xs">
        <div class="flex items-center gap-2">
          <span class="font-bold underline">EXCAVATION:</span>
          <div class="flex flex-col items-center">
            <span
              class="text-xl font-bold leading-none"
              :title="`Bonus: +${excavationBonus}% Crate Chance`"
              >Lvl. {{ store.excavationLevel }}</span
            >
            <!-- Hand-drawn style progress bar -->
            <div class="w-24 h-2 border border-black relative">
              <div
                class="absolute inset-0 bg-black opacity-20"
                style="
                  background-image: repeating-linear-gradient(
                    45deg,
                    transparent,
                    transparent 2px,
                    #000 2px,
                    #000 4px
                  );
                "
              ></div>
              <div
                class="h-full bg-black transition-all duration-300"
                :style="{ width: `${excavationProgress}%` }"
              ></div>
            </div>
          </div>
        </div>

        <div class="flex items-center gap-2">
          <span class="font-bold underline">RESTORATION:</span>
          <div class="flex flex-col items-center">
            <span
              class="text-xl font-bold leading-none"
              :title="`Bonus: +${restorationBonus}% Stability`"
              >Lvl. {{ store.restorationLevel }}</span
            >
            <div class="w-24 h-2 border border-black relative">
              <div
                class="absolute inset-0 bg-black opacity-20"
                style="
                  background-image: repeating-linear-gradient(
                    45deg,
                    transparent,
                    transparent 2px,
                    #000 2px,
                    #000 4px
                  );
                "
              ></div>
              <div
                class="h-full bg-black transition-all duration-300"
                :style="{ width: `${restorationProgress}%` }"
              ></div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Right: Balance & Tools (The "Accounting" Section) -->
    <div class="flex flex-col items-end gap-2">
      <!-- Date Stamp -->
      <div
        class="text-[10px] font-mono border border-gray-400 px-2 text-gray-700 mb-1"
      >
        DATE: {{ new Date().toISOString().split("T")[0] }}
      </div>

      <div class="flex gap-8 items-end">
        <div class="text-right">
          <div
            class="text-[10px] uppercase font-bold text-gray-600 tracking-wider"
          >
            Assigned Equipment
          </div>
          <div
            class="text-lg font-serif italic border-b border-black inline-block px-2"
          >
            {{ activeTool?.name }}
          </div>
        </div>

        <div class="text-right group cursor-help">
          <div
            class="text-[10px] uppercase font-bold text-gray-600 tracking-wider"
          >
            Funds Allocated
          </div>
          <div class="text-4xl font-mono font-bold relative inline-block">
            <span
              class="highlight-marker-bg absolute bottom-1 left-0 right-0 h-3 -z-10 opacity-50 transform -skew-x-12"
            ></span>
            {{ store.scrapBalance.toLocaleString() }}
          </div>
          <div class="text-[10px] text-gray-400">SCRAP UNITS</div>
        </div>
      </div>
    </div>
  </header>
</template>
