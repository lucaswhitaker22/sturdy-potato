<template>
  <div v-if="trackedQuests.length > 0" class="quest-tracker">
    <div class="tracker-header">ACTIVE DIRECTIVES</div>
    <div v-for="quest in trackedQuests" :key="quest.id" class="tracker-item">
      <div class="tracker-title">{{ quest.title }}</div>
      <div v-for="(obj, idx) in quest.objectives" :key="idx" class="tracker-obj">
        <div class="tracker-progress-text">
          {{ getCurrent(quest, obj.kind) }} / {{ obj.target }}
        </div>
        <div class="tracker-bar">
          <div class="tracker-fill" :style="{ width: getPercent(quest, obj) + '%' }"></div>
        </div>
      </div>
      <div v-if="quest.status === 'COMPLETED'" class="tracker-complete">
        READY TO CLAIM
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { useQuestStore, type Quest, type QuestObjective } from '@/stores/quests';

const store = useQuestStore();

// Show first 3 active quests
const trackedQuests = computed(() => store.trackedQuests);

function getCurrent(quest: Quest, kind: string): number {
  return quest.progress?.[kind] || 0;
}

function getPercent(quest: Quest, obj: QuestObjective): number {
  const current = getCurrent(quest, obj.kind);
  return Math.min(100, (current / obj.target) * 100);
}
</script>

<style scoped>
.quest-tracker {
  background: rgba(0, 0, 0, 0.7);
  border: 1px solid #444;
  padding: 0.5rem;
  font-family: 'JetBrains Mono', monospace;
  width: 250px;
  backdrop-filter: blur(2px);
}

.tracker-header {
  font-size: 0.7rem;
  color: #888;
  border-bottom: 1px solid #333;
  margin-bottom: 0.5rem;
  padding-bottom: 2px;
}

.tracker-item {
  margin-bottom: 0.8rem;
}

.tracker-title {
  font-size: 0.8rem;
  color: #ddd;
  margin-bottom: 2px;
}

.tracker-obj {
  margin-top: 2px;
}

.tracker-progress-text {
  font-size: 0.65rem;
  color: #aaa;
  text-align: right;
}

.tracker-bar {
  height: 3px;
  background: #222;
  margin-top: 1px;
}

.tracker-fill {
  height: 100%;
  background: #f1c40f;
  transition: width 0.3s;
}

.tracker-complete {
  font-size: 0.7rem;
  color: #0f0;
  text-align: center;
  margin-top: 4px;
  animation: pulse 1s infinite;
}

@keyframes pulse {
  0% { opacity: 0.5; }
  50% { opacity: 1; }
  100% { opacity: 0.5; }
}
</style>
