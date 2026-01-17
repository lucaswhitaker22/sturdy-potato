<template>
  <div class="quest-board">
    <div class="board-header">
      <h2>ARCHIVE DIRECTIVES</h2>
      <div class="tabs">
        <button 
          :class="{ active: tab === 'current' }" 
          @click="tab = 'current'"
        >
          CURRENT [{{ activeCount }}]
        </button>
        <button 
          :class="{ active: tab === 'available' }" 
          @click="tab = 'available'"
        >
          AVAILABLE [{{ availableCount }}]
        </button>
      </div>
    </div>

    <div class="quest-list">
      <div v-if="loading" class="loading">LOADING DIRECTIVES...</div>
      
      <div v-else-if="currentList.length === 0" class="empty-state">
        [NO DIRECTIVES FOUND]
      </div>

      <QuestItem 
        v-for="quest in currentList" 
        :key="quest.id" 
        :quest="quest"
        @accept="handleAccept"
        @claim="handleClaim"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useQuestStore } from '@/stores/quests';
import QuestItem from './QuestItem.vue';

const store = useQuestStore();
const tab = ref<'current' | 'available'>('current');

onMounted(() => {
  store.fetchQuests();
});

const loading = computed(() => store.loading);
const activeCount = computed(() => store.activeQuests.length);
const availableCount = computed(() => store.availableQuests.length);

const currentList = computed(() => {
  if (tab.value === 'current') return store.activeQuests;
  return store.availableQuests;
});

async function handleAccept(questId: string) {
  await store.acceptQuest(questId);
}

async function handleClaim(questDbId: string) {
  await store.claimReward(questDbId);
}
</script>

<style scoped>
.quest-board {
  background: #111;
  border: 1px solid #444;
  padding: 1rem;
  font-family: 'JetBrains Mono', monospace;
  height: 100%;
  display: flex;
  flex-direction: column;
}

.board-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
  border-bottom: 2px solid #333;
  padding-bottom: 0.5rem;
}

h2 {
  font-size: 1rem;
  color: #fff;
  margin: 0;
}

.tabs {
  display: flex;
  gap: 10px;
}

.tabs button {
  background: transparent;
  border: none;
  color: #666;
  cursor: pointer;
  font-family: inherit;
  font-size: 0.8rem;
  padding: 5px;
}

.tabs button.active {
  color: #0f0;
  border-bottom: 2px solid #0f0;
}

.quest-list {
  flex: 1;
  overflow-y: auto;
  padding-right: 5px;
}

.loading, .empty-state {
  text-align: center;
  color: #555;
  margin-top: 2rem;
  font-style: italic;
}
</style>
