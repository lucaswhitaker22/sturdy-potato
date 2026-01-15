<script setup lang="ts">
import { useGameStore } from "@/stores/game";
const store = useGameStore();
</script>

<template>
  <div class="h-full flex flex-col font-mono text-xs overflow-hidden relative">
    <div
      class="flex items-baseline justify-between border-b border-black pb-1 mb-2"
    >
      <h4 class="font-bold uppercase tracking-wider">Operation Manifest</h4>
      <span class="text-[10px] text-gray-500"
        >Pg. {{ Math.floor(store.log.length / 10) + 1 }}</span
      >
    </div>

    <div
      class="flex-1 overflow-y-auto pr-2 custom-scrollbar flex flex-col gap-1"
    >
      <div
        v-for="(line, index) in store.log"
        :key="index"
        :class="[
          'pl-2 relative border-l-2',
          line.includes('SUCCESS') || line.includes('RECOVERED')
            ? 'border-green-600 text-green-900 bg-green-50/50'
            : line.includes('SHATTERED') || line.includes('!!')
            ? 'border-red-600 text-red-900 bg-red-50/50'
            : line.includes('CRATE')
            ? 'border-yellow-600 text-yellow-900 bg-yellow-50/50'
            : 'border-gray-300 text-gray-600',
        ]"
      >
        <span class="font-bold mr-2 text-[10px] text-gray-500"
          >{{ (50 - index).toString().padStart(2, "0") }}:</span
        >
        <span class="font-serif">{{ line }}</span>
      </div>
    </div>
  </div>
</template>
