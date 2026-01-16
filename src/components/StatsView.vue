<script setup lang="ts">
import { useGameStore } from "@/stores/game";
import { computed } from "vue";
import { TOOL_CATALOG } from "@/constants/items";

const store = useGameStore();

const getLevelProgress = (xp: number) => {
  let threshold = 0;
  let prevThreshold = 0;
  for (let i = 1; i <= 99; i++) {
    prevThreshold = threshold;
    threshold += Math.floor(i + 300 * Math.pow(2, i / 7));
    if (xp < threshold) {
      const progress =
        ((xp - prevThreshold) / (threshold - prevThreshold)) * 100;
      return Math.min(100, Math.max(0, progress));
    }
  }
  return 100;
};

const getLevelThreshold = (xp: number) => {
  let threshold = 0;
  for (let i = 1; i <= 99; i++) {
    threshold += Math.floor(i + 300 * Math.pow(2, i / 7));
    if (xp < threshold) return threshold;
  }
  return Infinity;
};

// Skill Data Helper
const skills = computed(() => [
  {
    name: "Excavation",
    level: store.excavationLevel,
    xp: store.excavationXP,
    progress: getLevelProgress(store.excavationXP),
    nextLevelAt: getLevelThreshold(store.excavationXP),
    description:
      "Ability to locate items in the field. Higher levels increase crate find chance.",
    bonusText: `+${(Math.floor(store.excavationLevel / 5) * 0.5).toFixed(
      1
    )}% Find Rate`,
  },
  {
    name: "Restoration",
    level: store.restorationLevel,
    xp: store.restorationXP,
    progress: getLevelProgress(store.restorationXP),
    nextLevelAt: getLevelThreshold(store.restorationXP),
    description:
      "Skill in cleaning and stabilizing artifacts. Improves stability during sifting.",
    bonusText: `+${(
      store.restorationLevel * 0.1 +
      store.overclockBonus * 100
    ).toFixed(1)}% Stability`,
  },
  {
    name: "Appraisal",
    level: store.appraisalLevel,
    xp: store.appraisalXP,
    progress: getLevelProgress(store.appraisalXP),
    nextLevelAt: getLevelThreshold(store.appraisalXP),
    description:
      "Knowledge of item value. Grants access to market features and insights.",
    bonusText: `Market Access`,
  },
  {
    name: "Smelting",
    level: store.smeltingLevel,
    xp: store.smeltingXP,
    progress: getLevelProgress(store.smeltingXP),
    nextLevelAt: getLevelThreshold(store.smeltingXP),
    description:
      "Efficiency in recycling materials. Level 99 doubles scrap from junk.",
    bonusText: `Recycling Eff.`,
  },
]);

const totalLevel = computed(
  () =>
    store.excavationLevel +
    store.restorationLevel +
    store.appraisalLevel +
    store.smeltingLevel
);

const totalPlaytime = computed(() => {
  // If not tracked backend, maybe use a humorous "unknown" or estimate if we had it
  // Store doesn't track playtime, use "Classified"
  return "CLASSIFIED";
});

const joinDate = computed(() => {
  // Just use a static date or maybe we can fetch created_at from profile if we had it
  // Using current date for now or "Unknown"
  return "2024-EST";
});

const toolsOwnedCount = computed(() => {
  return Object.keys(store.ownedTools).length;
});

const totalTools = TOOL_CATALOG.length;
</script>

<template>
  <div class="h-full flex flex-col gap-6 overflow-y-auto pr-2">
    <!-- Header Card -->
    <div
      class="paper-card bg-[#F5F5F0] border-2 border-black p-6 relative shadow-md"
    >
      <!-- ID Badge Look -->
      <div class="flex flex-col md:flex-row gap-6 items-center">
        <div
          class="w-32 h-32 border-2 border-black bg-gray-200 flex items-center justify-center relative overflow-hidden shrink-0"
        >
          <div
            class="absolute inset-0 opacity-20 bg-[repeating-linear-gradient(45deg,#000,#000_1px,transparent_1px,transparent_4px)]"
          ></div>
          <span class="text-4xl font-serif">👤</span>
          <div
            class="absolute bottom-0 w-full bg-black text-white text-[10px] text-center font-mono py-1"
          >
            OPERATOR
          </div>
        </div>

        <div class="flex-1 w-full">
          <div
            class="flex justify-between items-start border-b-2 border-dashed border-gray-400 pb-2 mb-4"
          >
            <div>
              <h2
                class="text-3xl font-bold font-serif uppercase tracking-widest text-ink-black"
              >
                Personnel Dossier
              </h2>
              <div class="font-mono text-xs text-gray-500">
                ID: {{ store.userSessionId || "UNKNOWN" }}
              </div>
            </div>
            <div class="text-right">
              <div class="text-[10px] font-bold uppercase text-gray-500">
                Clearance Level
              </div>
              <div class="text-4xl font-mono font-bold">{{ totalLevel }}</div>
            </div>
          </div>

          <div class="grid grid-cols-2 md:grid-cols-4 gap-4 text-xs font-mono">
            <div>
              <div class="text-gray-500 uppercase">Service Record</div>
              <div class="font-bold">{{ joinDate }}</div>
            </div>
            <div>
              <div class="text-gray-500 uppercase">Deployed Time</div>
              <div class="font-bold">{{ totalPlaytime }}</div>
            </div>
            <div>
              <div class="text-gray-500 uppercase">Discoveries</div>
              <div class="font-bold">
                {{ store.uniqueItemsFound }} /
                {{ store.catalog.length || "??" }}
              </div>
            </div>
            <div>
              <div class="text-gray-500 uppercase">Equipment</div>
              <div class="font-bold">
                {{ toolsOwnedCount }} / {{ totalTools }} Units
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Stamp -->
      <div
        class="absolute top-4 right-4 md:top-6 md:right-8 transform rotate-12 opacity-80 border-4 border-stamp-blue text-stamp-blue px-2 py-1 text-xs font-black uppercase tracking-widest pointer-events-none"
      >
        Active Duty
      </div>
    </div>

    <!-- Skills Section -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div
        v-for="skill in skills"
        :key="skill.name"
        class="paper-card bg-white p-4 border border-gray-300 relative group hover:shadow-lg transition-shadow"
      >
        <div class="flex justify-between items-baseline mb-2">
          <h3 class="font-bold font-serif text-lg uppercase">
            {{ skill.name }}
          </h3>
          <span class="font-mono font-bold text-xl"
            >Lvl. {{ skill.level }}</span
          >
        </div>

        <div class="h-4 w-full bg-gray-100 border border-black mb-2 relative">
          <div
            class="h-full bg-black transition-all duration-500"
            :style="{ width: `${skill.progress}%` }"
          ></div>
          <!-- Striped effect on bar -->
          <div
            class="absolute inset-0 opacity-20 bg-[repeating-linear-gradient(-45deg,transparent,transparent_4px,white_4px,white_6px)]"
          ></div>
        </div>

        <div
          class="flex justify-between text-[10px] font-mono text-gray-500 mb-3"
        >
          <span>{{ skill.xp.toLocaleString() }} XP</span>
          <span>NEXT: {{ skill.nextLevelAt.toLocaleString() }} XP</span>
        </div>

        <p
          class="text-xs font-serif text-gray-700 italic border-l-2 border-gray-300 pl-2 mb-2"
        >
          {{ skill.description }}
        </p>

        <div
          class="mt-auto pt-2 border-t border-dashed border-gray-300 flex justify-between items-center bg-gray-50 p-2"
        >
          <span class="text-[10px] font-bold uppercase text-gray-500"
            >Current Efficiency</span
          >
          <span class="font-mono font-bold text-ink-black">{{
            skill.bonusText
          }}</span>
        </div>
      </div>
    </div>

    <!-- Collections / Achievements Summary -->
    <div class="paper-section p-6 bg-[#F9F9F9] border-t-4 border-black">
      <h3
        class="font-bold font-serif text-xl uppercase mb-4 flex items-center gap-2"
      >
        <span>🏆</span> Commendations & Sets
      </h3>

      <div
        v-if="store.completedSetIds.length === 0"
        class="text-center py-8 text-gray-500 italic font-serif"
      >
        No commendations recorded. Complete museum sets to earn badges.
      </div>
      <div v-else class="flex flex-wrap gap-2">
        <div
          v-for="setId in store.completedSetIds"
          :key="setId"
          class="bg-white border border-black px-3 py-1 shadow-[2px_2px_0_0_#000] text-xs font-bold uppercase hover:-translate-y-0.5 transition-transform"
        >
          {{ setId.replace(/_/g, " ") }}
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.paper-card {
  /* Inherit global paper styles or define basics */
}
</style>
