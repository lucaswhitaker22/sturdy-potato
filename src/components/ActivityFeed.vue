<script setup lang="ts">
import { ref, onMounted } from "vue";
import { supabase } from "@/lib/supabase";

interface GlobalEvent {
  id: string;
  event_type: "find" | "listing" | "sale";
  details: any;
  created_at: string;
}

const events = ref<GlobalEvent[]>([]);

onMounted(async () => {
  // Fetch recent
  const { data } = await supabase
    .from("global_events")
    .select("*")
    .order("created_at", { ascending: false })
    .limit(20);

  if (data) events.value = data as GlobalEvent[];

  // Subscribe
  supabase
    .channel("global_feed")
    .on(
      "postgres_changes",
      { event: "INSERT", schema: "public", table: "global_events" },
      (payload) => {
        events.value.unshift(payload.new as GlobalEvent);
        if (events.value.length > 50) events.value.pop();
      }
    )
    .subscribe();
});
</script>

<template>
  <div
    class="flex flex-col h-full bg-black text-white p-2 md:p-4 font-mono text-xs overflow-hidden border-4 border-zinc-800 shadow-[4px_4px_0px_0px_rgba(236,72,153,0.3)]"
  >
    <h3
      class="font-black mb-2 text-brutalist-pink uppercase tracking-widest border-b border-zinc-800 pb-2"
    >
      > GLOBAL_NET_FEED
    </h3>
    <div class="flex-1 overflow-y-auto custom-scrollbar flex flex-col gap-2">
      <div v-if="events.length === 0" class="text-zinc-600 italic">
        Listening for global frequencies...
      </div>
      <div
        v-for="event in events"
        :key="event.id"
        class="border-b border-zinc-900 pb-2"
      >
        <div class="text-[10px] text-zinc-500 mb-1">
          {{ new Date(event.created_at).toLocaleTimeString() }}
        </div>

        <div v-if="event.event_type === 'find'">
          <span class="text-brutalist-cyan font-bold">ANOMALY DETECTED</span>
          <div class="text-zinc-300 mt-1">
            User unearthed
            <span class="text-white font-bold">{{
              event.details.item_id?.toUpperCase()
            }}</span>
            <span class="bg-zinc-800 text-white px-1 ml-1 rounded"
              >#{{ event.details.mint_number }}</span
            >
          </div>
        </div>

        <div v-else-if="event.event_type === 'listing'">
          <span class="text-brutalist-yellow font-bold">NEW_LISTING</span>
          <div class="text-zinc-300 mt-1">
            Auction started:
            <span class="text-white font-bold">{{
              event.details.item_id?.toUpperCase()
            }}</span>
            <div class="text-brutalist-green">
              {{ event.details.price }} SCRAP
            </div>
          </div>
        </div>

        <div v-else>
          <span class="text-zinc-400">{{
            event.event_type.toUpperCase()
          }}</span>
          <div class="text-zinc-500">{{ JSON.stringify(event.details) }}</div>
        </div>
      </div>
    </div>
  </div>
</template>
