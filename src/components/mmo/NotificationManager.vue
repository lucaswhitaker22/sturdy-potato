<script setup lang="ts">
import { useMMOStore, type Notification } from "@/stores/mmo";
import { watch, ref } from "vue";

const store = useMMOStore();
const activeToasts = ref<Notification[]>([]);

// Watch for new notifications
watch(
  () => store.notifications,
  (newVal, oldVal) => {
    // If new notification added (length increased or new ID at top)
    if (newVal.length > (oldVal?.length || 0)) {
      const latest = newVal[0];
      // Check if we already showed it (to avoid duplicates on refresh)
      if (latest && !activeToasts.value.find((t) => t.id === latest.id)) {
        // Only show if created recently (within last 10 seconds)
        // ensuring we don't spam toasts for old unread messages on load
        const age =
          new Date().getTime() - new Date(latest.created_at).getTime();
        if (age < 10000) {
          showToast(latest);
        }
      }
    }
  },
  { deep: true }
);

const showToast = (n: Notification) => {
  activeToasts.value.push(n);
  // Auto dismiss
  setTimeout(() => {
    removeToast(n.id);
  }, 5000);
  // Mark read automatically when shown? Or let user click?
  // R19 says "The client must show notifications".
  // I'll mark read so they don't pop up again.
  store.markRead(n.id);
};

const removeToast = (id: string) => {
  activeToasts.value = activeToasts.value.filter((t) => t.id !== id);
};
</script>

<template>
  <div class="fixed top-4 right-4 z-50 flex flex-col gap-2 pointer-events-none">
    <TransitionGroup name="toast">
      <div
        v-for="toast in activeToasts"
        :key="toast.id"
        class="pointer-events-auto bg-white border-2 border-black p-4 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] w-80 flex gap-3 items-start"
        :class="{
          'border-green-800 bg-green-50': toast.type === 'success',
          'border-red-800 bg-red-50':
            toast.type === 'error' || toast.type === 'warning',
          'border-blue-800 bg-blue-50': toast.type === 'info',
        }"
      >
        <div class="text-2xl">
          <span v-if="toast.type === 'success'">🎉</span>
          <span v-else-if="toast.type === 'warning'">⚠️</span>
          <span v-else>ℹ️</span>
        </div>
        <div>
          <h4 class="font-bold uppercase text-xs tracking-wider mb-1">
            {{ toast.type }}
          </h4>
          <p class="text-xs font-mono leading-tight">{{ toast.message }}</p>
        </div>
        <button
          @click="removeToast(toast.id)"
          class="ml-auto text-gray-500 hover:text-black"
        >
          ×
        </button>
      </div>
    </TransitionGroup>
  </div>
</template>

<style scoped>
.toast-enter-active,
.toast-leave-active {
  transition: all 0.3s ease;
}
.toast-enter-from {
  opacity: 0;
  transform: translateX(100%);
}
.toast-leave-to {
  opacity: 0;
  transform: translateY(-20px);
}
</style>
