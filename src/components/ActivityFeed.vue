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
  <div class="h-full flex flex-col font-mono text-xs overflow-hidden">
    <div class="mb-2 text-center border-b-2 border-dashed border-gray-300 pb-1">
      <span
        class="bg-gray-200 px-2 py-0.5 text-[10px] uppercase font-bold tracking-widest text-gray-600"
        >Global Wire Service</span
      >
    </div>

    <div
      class="flex-1 overflow-y-auto px-1 custom-scrollbar flex flex-col gap-3"
    >
      <div
        v-if="events.length === 0"
        class="text-center py-8 text-gray-500 italic font-serif"
      >
        -- No signals on wire --
      </div>

      <div
        v-for="event in events"
        :key="event.id"
        class="relative pb-2 border-b border-gray-300 last:border-0"
      >
        <!-- Ticker Timestamp -->
        <div
          class="absolute right-0 top-0 text-[10px] text-gray-600 font-bold bg-gray-100 px-1 border border-gray-300"
        >
          {{
            new Date(event.created_at).toLocaleTimeString([], {
              hour: "2-digit",
              minute: "2-digit",
            })
          }}
        </div>

        <div v-if="event.event_type === 'find'" class="pr-8">
          <div class="flex items-center gap-1 mb-1">
            <span
              class="w-2 h-2 rounded-full bg-blue-600 border border-blue-800"
            ></span>
            <span class="font-bold text-blue-900 uppercase text-[10px]"
              >Discovery</span
            >
          </div>
          <div class="text-ink-black ml-3 leading-tight">
            New specimen
            <span class="font-bold underline">{{
              event.details.item_id?.toUpperCase()
            }}</span>
            catalogued.
            <span class="text-[10px] text-gray-500 block mt-0.5"
              >Mint #{{ event.details.mint_number }}</span
            >
          </div>
        </div>

        <div v-else-if="event.event_type === 'listing'" class="pr-8">
          <div class="flex items-center gap-1 mb-1">
            <span class="w-2 h-2 rounded-full bg-yellow-500"></span>
            <span class="font-bold text-yellow-800 uppercase text-[10px]"
              >Auction</span
            >
          </div>
          <div class="text-ink-black ml-3 leading-tight">
            <span class="font-bold border-b border-dashed border-black">{{
              event.details.item_id?.toUpperCase()
            }}</span>
            listed for
            <span class="bg-yellow-100 px-1 font-bold"
              >{{ event.details.price }} SCRAP</span
            >.
          </div>
        </div>

        <div v-else class="pr-8">
          <span class="font-bold uppercase text-[10px] text-gray-500">{{
            event.event_type
          }}</span>
          <div class="text-gray-600 ml-3 truncate">
            {{ JSON.stringify(event.details) }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
