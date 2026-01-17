<template>
  <div class="quest-item" :class="status.toLowerCase()">
    <div class="quest-header">
      <div class="quest-type-badge">{{ quest.type }}</div>
      <div class="quest-title">{{ quest.title }}</div>
    </div>
    
    <div class="quest-context">
      {{ quest.context }}
    </div>

    <!-- Objectives -->
    <div class="quest-objectives">
      <div v-for="(obj, idx) in quest.objectives" :key="idx" class="objective-row">
        <span class="obj-label">{{ formatObjective(obj) }}</span>
        <span class="obj-progress">{{ getCurrent(obj.kind) }} / {{ obj.target }}</span>
        <div class="progress-bar">
          <div class="progress-fill" :style="{ width: getProgressPercent(obj) + '%' }"></div>
        </div>
      </div>
    </div>

    <!-- Rewards -->
    <div class="quest-rewards">
      <div v-for="(reward, idx) in quest.rewards" :key="idx" class="reward-pill">
        <span class="reward-kind" :class="reward.kind">{{ reward.kind.replace('_', ' ') }}</span>
        <span v-if="reward.amount" class="reward-amount">+{{ reward.amount }}</span>
        <span v-if="reward.id" class="reward-id">{{ reward.id }}</span>
      </div>
    </div>

    <!-- Actions -->
    <div class="quest-actions">
      <button v-if="status === 'AVAILABLE'" @click="$emit('accept', quest.quest_id)" class="btn-retro">
        [ACCEPT DIRECTIVE]
      </button>
      <button v-if="status === 'COMPLETED'" @click="$emit('claim', quest.id)" class="btn-retro btn-claim">
        [CLAIM REWARD]
      </button>
      <div v-if="status === 'ACCEPTED'" class="status-text">
        IN PROGRESS...
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import type { Quest, QuestObjective } from '@/stores/quests';

const props = defineProps<{
  quest: Quest;
}>();

defineEmits(['accept', 'claim']);

const status = computed(() => props.quest.status);

function getCurrent(kind: string): number {
  return props.quest.progress?.[kind] || 0;
}

function getProgressPercent(obj: QuestObjective): number {
  const current = getCurrent(obj.kind);
  return Math.min(100, (current / obj.target) * 100);
}

function formatObjective(obj: QuestObjective): string {
  // Simple map for now, can be expanded
  const map: Record<string, string> = {
    'extract_manual': 'Manual Extractions',
    'crate_obtained': 'Find Crates',
    'crate_opened': 'Open Crates',
    'sift_attempted': 'Sift Attempts',
    'sift_stage_at_least': `Reach Stage ${obj.stage_at_least}`,
    'claim_stage_at_least': `Claim Stage ${obj.stage_at_least}`,
    'smelt_items': 'Smelt Items',
    'listings_created': 'Create Listings',
    'museum_submissions': 'Museum Submissions',
    'complete_onboarding': 'Finalize Training'
  };
  return map[obj.kind] || obj.kind.replace(/_/g, ' ');
}
</script>

<style scoped>
.quest-item {
  background: rgba(0, 0, 0, 0.4);
  border: 1px solid #333;
  padding: 1rem;
  margin-bottom: 0.5rem;
  font-family: 'JetBrains Mono', monospace;
  position: relative;
  overflow: hidden;
}

.quest-item.completed {
  border-color: #0f0;
  box-shadow: 0 0 10px rgba(0, 255, 0, 0.1);
}

.quest-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.5rem;
}

.quest-type-badge {
  font-size: 0.7rem;
  text-transform: uppercase;
  background: #333;
  color: #888;
  padding: 2px 6px;
  border-radius: 2px;
}

.quest-title {
  font-weight: bold;
  color: #eee;
  flex: 1;
  text-align: right;
}

.quest-context {
  font-size: 0.8rem;
  color: #aaa;
  font-style: italic;
  margin-bottom: 1rem;
  border-left: 2px solid #555;
  padding-left: 0.5rem;
}

.objective-row {
  font-size: 0.8rem;
  margin-bottom: 0.5rem;
}

.obj-header {
  display: flex;
  justify-content: space-between;
}

.progress-bar {
  height: 4px;
  background: #222;
  margin-top: 4px;
}

.progress-fill {
  background: #0f0;
  height: 100%;
  transition: width 0.3s ease;
}

.quest-rewards {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
  margin-top: 0.5rem;
}

.reward-pill {
  font-size: 0.7rem;
  background: rgba(255, 255, 255, 0.1);
  padding: 2px 6px;
  border: 1px solid rgba(255, 255, 255, 0.2);
  display: flex;
  gap: 5px;
}

.reward-kind.scrap { color: #f1c40f; }
.reward-kind.fine_dust { color: #3498db; }
.reward-kind.hi { color: #9b59b6; }
.reward-kind.title { color: #e67e22; }

.quest-actions {
  margin-top: 1rem;
  text-align: right;
}

.btn-retro {
  background: transparent;
  border: 1px solid #666;
  color: #888;
  padding: 5px 10px;
  cursor: pointer;
  font-family: inherit;
  font-size: 0.8rem;
  transition: all 0.2s;
}

.btn-retro:hover {
  background: #333;
  color: #fff;
}

.btn-claim {
  border-color: #0f0;
  color: #0f0;
  box-shadow: 0 0 5px rgba(0, 255, 0, 0.3);
}

.btn-claim:hover {
  background: #0f0;
  color: #000;
}

.status-text {
  font-size: 0.7rem;
  color: #666;
  letter-spacing: 1px;
}
</style>
