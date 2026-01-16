<script setup lang="ts">
import { computed } from 'vue';
import { useGameStore } from '@/stores/game';

const props = defineProps<{
  skill: string; 
  label: string;
  level: number;
  currentBranch: string | null;
  branches: {
     id: string;
     name: string;
     desc: string;
     effect: string;
  }[];
}>();

const store = useGameStore();

const isLocked = computed(() => props.level < 60);

const activeBranchInfo = computed(() => {
  if (!props.currentBranch) return null;
  return props.branches.find(b => b.id === props.currentBranch);
});

async function selectBranch(branchId: string) {
  if (confirm(`Confirm Specialization: ${branchId.toUpperCase()}?\n\nThis choice is persistent (Respec costs 25,000 Scrap).`)) {
    await store.chooseSpecialization(props.skill, branchId);
  }
}

async function doRespec() {
  await store.respecSpecialization(props.skill);
}
</script>

<template>
  <div class="border border-gray-300 p-4 bg-white shadow-sm relative overflow-hidden">
    <!-- Header -->
    <div class="flex justify-between items-center mb-4 border-b border-gray-100 pb-2">
      <div>
        <h3 class="font-serif font-bold uppercase text-lg">{{ label }}</h3>
        <span class="text-xs font-mono text-gray-500">LEVEL {{ level }} / 60 REQUIRED</span>
      </div>
      <div v-if="activeBranchInfo" class="bg-black text-white text-xs px-2 py-1 font-mono uppercase">
        ACTIVE SPEC
      </div>
    </div>

    <!-- Locked State -->
    <div v-if="isLocked" class="absolute inset-0 bg-gray-100/90 z-10 flex flex-col items-center justify-center text-center p-6">
      <div class="text-4xl mb-2">🔒</div>
      <h4 class="font-bold text-gray-600 uppercase">Clearance Level 60 Required</h4>
      <p class="text-xs text-gray-500 mt-1 max-w-[200px]">
        Continue basic operations to unlock advanced specialization protocols.
      </p>
    </div>

    <!-- Active State -->
    <div v-if="activeBranchInfo">
      <div class="border-2 border-black p-4 bg-gray-50">
        <h4 class="font-black text-xl uppercase mb-1">{{ activeBranchInfo.name }}</h4>
        <p class="font-serif italic text-gray-700 mb-4">{{ activeBranchInfo.desc }}</p>
        
        <div class="bg-white border border-gray-300 p-3 mb-4">
          <span class="text-xs font-black uppercase text-gray-400 block mb-1">Effect Protocol</span>
          <p class="text-sm font-mono leading-relaxed">{{ activeBranchInfo.effect }}</p>
        </div>

        <button 
          @click="doRespec"
          class="w-full border border-gray-300 py-2 text-xs hover:bg-red-50 hover:text-red-600 hover:border-red-300 transition-colors uppercase font-bold"
        >
          Respec (25,000 Scrap)
        </button>
      </div>
    </div>

    <!-- Selection State -->
    <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div 
        v-for="b in branches" 
        :key="b.id"
        class="border border-gray-200 hover:border-black p-3 hover:bg-gray-50 transition-colors cursor-pointer group flex flex-col"
        @click="selectBranch(b.id)"
      >
        <div class="mb-2">
          <h5 class="font-bold uppercase text-sm group-hover:underline">{{ b.name }}</h5>
          <p class="text-[10px] text-gray-500 font-mono">{{ b.id }}</p>
        </div>
        
        <p class="text-xs font-serif italic text-gray-600 mb-3 flex-1">
          "{{ b.desc }}"
        </p>

        <div class="text-[10px] bg-gray-100 p-2 font-mono text-gray-700">
          {{ b.effect }}
        </div>
        
        <button class="mt-3 w-full bg-black text-white text-[10px] py-1 opacity-0 group-hover:opacity-100 transition-opacity uppercase">
          Initialize
        </button>
      </div>
    </div>

  </div>
</template>
