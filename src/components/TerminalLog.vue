<script setup lang="ts">
import { useGameStore } from "@/stores/game";
const store = useGameStore();
</script>

<template>
  <div
    class="panel-brutalist h-full flex flex-col gap-2 overflow-hidden bg-zinc-950 font-mono text-xs"
  >
    <div
      class="flex justify-between items-center border-b border-white/30 pb-1 mb-2"
    >
      <span class="font-black uppercase text-gray-400">System.log</span>
      <span class="animate-pulse">●</span>
    </div>
    <div
      class="flex-1 overflow-y-auto pr-2 flex flex-col gap-1 custom-scrollbar"
    >
      <div
        v-for="(line, index) in store.log"
        :key="index"
        :class="[
          'leading-relaxed group',
          line.includes('SUCCESS') || line.includes('RECOVERED')
            ? 'text-brutalist-green'
            : line.includes('SHATTERED') || line.includes('!!')
            ? 'text-brutalist-red'
            : line.includes('CRATE')
            ? 'text-brutalist-yellow'
            : 'text-white',
        ]"
      >
        <span class="opacity-30 mr-2"
          >[{{ (50 - index).toString().padStart(2, "0") }}]</span
        >
        <span>{{ line }}</span>
      </div>
    </div>
  </div>
</template>
