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
    storeBranch: 'excavationBranch',
    progress: getLevelProgress(store.excavationXP),
    nextLevelAt: getLevelThreshold(store.excavationXP),
    description:
      "Ability to locate items in the field. Higher levels increase crate find chance.",
    bonusText: `+${(Math.floor(store.excavationLevel / 5) * 0.5).toFixed(
      1
    )}% Find Rate`,
    branches: [
      { id: 'area_specialist', label: 'Area Specialist', desc: 'Urban & Branded focus. Higher yields in Industrial/Suburbs.' },
      { id: 'deep_seeker', label: 'Deep Seeker', desc: 'Tech & Cultural focus. Better for finding high-tier artifacts.' }
    ]
  },
  {
    name: "Restoration",
    level: store.restorationLevel,
    xp: store.restorationXP,
    storeBranch: 'restorationBranch',
    progress: getLevelProgress(store.restorationXP),
    nextLevelAt: getLevelThreshold(store.restorationXP),
    description:
      "Skill in cleaning and stabilizing artifacts. Improves stability during sifting.",
    bonusText: `+${(
      store.restorationLevel * 0.1 +
      store.overclockBonus * 100
    ).toFixed(1)}% Stability`,
    branches: [
      { id: 'master_preserver', label: 'Master Preserver', desc: 'Stability bonus in early stages (0-3).' },
      { id: 'swift_handler', label: 'Swift Handler', desc: 'Stability bonus in late stages (4+).' }
    ]
  },
  {
    name: "Appraisal",
    level: store.appraisalLevel,
    xp: store.appraisalXP,
    storeBranch: 'appraisalBranch',
    progress: getLevelProgress(store.appraisalXP),
    nextLevelAt: getLevelThreshold(store.appraisalXP),
    description:
      "Knowledge of item value. Grants access to market features and insights.",
    bonusText: `Market Access`,
    branches: [
      { id: 'authenticator', label: 'Authenticator', desc: 'Lower certification costs and higher value bonus.' },
      { id: 'insider', label: 'Insider', desc: 'Reduces Counter-Bazaar risk and listing fees.' }
    ]
  },
  {
    name: "Smelting",
    level: store.smeltingLevel,
    xp: store.smeltingXP,
    storeBranch: 'smeltingBranch',
    progress: getLevelProgress(store.smeltingXP),
    nextLevelAt: getLevelThreshold(store.smeltingXP),
    description:
      "Efficiency in recycling materials. Level 99 doubles scrap from junk.",
    bonusText: `Recycling Eff.`,
    branches: [
      { id: 'scrap_tycoon', label: 'Scrap Tycoon', desc: '+25% Scrap balance from smelting junk items.' },
      { id: 'fragment_alchemist', label: 'Fragment Alchemist', desc: 'Chance to find Cursed Fragments during failure salvage.' }
    ]
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

          <span class="font-mono font-bold text-ink-black">{{
            skill.bonusText
          }}</span>

        <!-- Specialization Section (Lv 60+) -->

        <div v-if="skill.level >= 60" class="mt-4 pt-4 border-t-2 border-black">
          <div class="flex justify-between items-center mb-2">
            <span class="text-[10px] font-black uppercase text-inking-blue">Specialization</span>
            <span v-if="store[skill.storeBranch as keyof typeof store]" class="bg-black text-white px-2 py-0.5 text-[10px] font-mono uppercase">
              {{ (store[skill.storeBranch as keyof typeof store] as string).replace(/_/g, ' ') }}
            </span>
            <span v-else class="text-[10px] font-mono text-gray-400">UNSET</span>
          </div>

          <div v-if="!store[skill.storeBranch as keyof typeof store]" class="grid grid-cols-2 gap-2">
            <button 
              v-for="branch in skill.branches" 
              :key="branch.id"
              @click="store.chooseSpecialization(skill.name.toLowerCase(), branch.id)"
              class="border border-black p-2 text-[10px] font-bold hover:bg-black hover:text-white transition-colors text-left flex flex-col gap-1"
            >
              <span class="uppercase">{{ branch.label }}</span>
              <span class="text-[8px] font-normal leading-tight opacity-70">{{ branch.desc }}</span>
            </button>
          </div>
          <div v-else class="flex justify-between items-center">
            <p class="text-[9px] font-serif italic text-gray-600">
              {{ skill.branches.find(b => b.id === store[skill.storeBranch as keyof typeof store])?.desc }}
            </p>
            <button 
              @click="store.respecSpecialization(skill.name.toLowerCase())"
              class="text-[8px] font-mono border-b border-gray-400 hover:text-red-600 hover:border-red-600 transition-colors"
            >
              RESPEC (2.5k)
            </button>
          </div>
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
