<template>
  <div
    v-if="activeEvent"
    class="world-event-banner bg-red-900 border-b-2 border-red-500 p-2 text-white font-mono shadow-lg animate-pulse-slow"
  >
    <div
      class="container mx-auto flex flex-col md:flex-row justify-between items-center"
    >
      <div class="flex items-center gap-4">
        <span class="text-2xl animate-pulse">⚠️</span>
        <div>
          <div class="font-bold text-lg uppercase tracking-wider">
            World Event: {{ activeEvent.name }}
          </div>
          <div class="text-xs text-red-200">{{ activeEvent.description }}</div>
        </div>
      </div>

      <div class="flex-1 mx-8 w-full md:w-auto mt-2 md:mt-0">
        <div class="flex justify-between text-xs mb-1">
          <span>Global Progress</span>
          <span>{{ progressPercentage }}%</span>
        </div>
        <div
          class="w-full bg-red-950 h-3 rounded-full border border-red-700 overflow-hidden"
        >
          <div
            class="bg-red-500 h-full transition-all duration-1000"
            :style="{ width: `${progressPercentage}%` }"
          ></div>
        </div>
        <div class="text-center text-xs mt-1">
          {{ activeEvent.global_goal_progress.toLocaleString() }} /
          {{ activeEvent.global_goal_target.toLocaleString() }}
        </div>
      </div>

      <div class="text-sm">Ends: {{ timeLeft }}</div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, computed, ref } from "vue";
import { useWorldEventStore } from "@/stores/world-event";
import { storeToRefs } from "pinia";

const eventStore = useWorldEventStore();
const { activeEvent } = storeToRefs(eventStore);

const now = ref(Date.now());

onMounted(() => {
  eventStore.fetchActiveEvent();
  eventStore.subscribe();
  setInterval(() => {
    now.value = Date.now();
  }, 60000);
});

const progressPercentage = computed(() => {
  if (!activeEvent.value) return 0;
  const pct =
    (activeEvent.value.global_goal_progress /
      activeEvent.value.global_goal_target) *
    100;
  return Math.min(100, Math.max(0, pct)).toFixed(1);
});

const timeLeft = computed(() => {
  if (!activeEvent.value) return "";
  const end = new Date(activeEvent.value.ends_at).getTime();
  const diff = end - now.value;
  if (diff <= 0) return "Ended";

  const hours = Math.floor(diff / (1000 * 60 * 60));
  const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
  return `${hours}h ${minutes}m`;
});
</script>

<style scoped>
.animate-pulse-slow {
  animation: pulse 4s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}
@keyframes pulse {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.9;
  }
}
</style>
