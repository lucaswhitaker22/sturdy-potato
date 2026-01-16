import { useGameStore } from "@/stores/game";
import { computed, ref } from "vue";
import { audio } from "@/services/audio";
const store = useGameStore();

const currentStability = computed(() => {
  const stage = store.labState.currentStage;
  let base = 0;
  if (stage === 0) base = 90;
  else if (stage === 1) base = 75;
  else if (stage === 2) base = 50;
  else if (stage === 3) base = 25;
  else if (stage === 4) base = 10;

  const bonus = store.restorationLevel * 0.1 + store.overclockBonus * 100;
  return (base + bonus).toFixed(1) + "%";
});

const isShaking = ref(false);
const revealedItem = ref<any>(null);

async function handleSift() {
  if (store.isExtracting) return;
  isShaking.value = true;
  await store.sift();
  setTimeout(() => (isShaking.value = false), 500);
}

async function handleClaim() {
  if (store.isExtracting) return;

  // Tension Shake
  isShaking.value = true;
  await new Promise((resolve) => setTimeout(resolve, 800)); // Build tension

  const result = await store.claim();
  isShaking.value = false;

  if (result) {
    audio.playCompletion(result.tier?.toLowerCase() || 'common');
    revealedItem.value = result;
  }
}
</script>

<template>
  <div class="flex-1 flex flex-col min-h-[400px] gap-6 p-4">
    <!-- Header -->
    <div
      class="flex justify-between items-center border-b-2 border-black pb-2 form-line"
    >
      <h2
        class="text-2xl font-serif font-black text-ink-black uppercase tracking-tight"
      >
        Analysis Lab
      </h2>
      <div
        v-if="store.labState.isActive"
        class="px-2 py-1 font-mono text-xs border border-black bg-white shadow-[2px_2px_0_0_rgba(0,0,0,1)]"
      >
        SEQUENCE: {{ store.labState.currentStage }}/5
      </div>
    </div>

    <!-- Empty State -->
    <div
      v-if="!store.labState.isActive"
      class="flex-1 flex flex-col items-center justify-center gap-6"
    >
      <div
        class="w-48 h-48 border-4 border-dashed border-gray-400 flex items-center justify-center bg-gray-100 rounded-sm"
      >
        <div class="text-center grayscale rotate-12">
          <span class="text-6xl block mb-2 opacity-50">📦</span>
          <span class="font-serif font-bold italic text-gray-600"
            >No Specimen</span
          >
        </div>
      </div>

      <div class="flex flex-col items-center gap-2">
        <button
          @click="store.startSifting()"
          :disabled="store.trayCount === 0"
          class="px-8 py-3 bg-ink-black text-white font-serif font-bold hover:bg-gray-800 shadow-[4px_4px_0_0_#999] hover:translate-x-[1px] hover:translate-y-[1px] hover:shadow-[3px_3px_0_0_#999] transition-all disabled:opacity-50 disabled:cursor-not-allowed"
        >
          Retrieve Specimen from Tray
        </button>
        <span
          class="font-mono text-[10px] text-gray-500 uppercase tracking-widest"
        >
          Available Units: {{ store.trayCount }}/5
        </span>
      </div>
    </div>

    <!-- Active Lab View -->
    <div v-else class="flex-1 flex flex-col gap-8">
      <div
        class="flex-1 flex flex-col md:flex-row items-center justify-center gap-12"
      >
        <!-- The "Specimen" (Crate) -->
        <div
          class="relative group"
          :class="{ 'animate-shake-heavy': isShaking }"
        >
          <!-- Stability Tag -->
          <div class="absolute -top-6 -right-6 z-20 transform rotate-6">
            <div
              class="bg-gray-100 border-2 border-dashed border-red-500 text-red-600 px-3 py-1 font-black font-mono text-sm shadow-sm"
            >
              STABILITY:
              {{ currentStability }}
            </div>
            <!-- Tape effect -->
            <div
              class="absolute -top-2 left-1/2 w-8 h-4 bg-yellow-100/80 transform -rotate-45 border-l border-r border-white/50"
            ></div>
          </div>

          <!-- Crate Visual: Sketch Style -->
          <div
            class="w-64 h-64 border-4 border-black bg-white shadow-[8px_8px_0_0_rgba(0,0,0,0.1)] relative overflow-hidden ring-4 ring-white ring-offset-2 ring-offset-gray-200"
          >
            <!-- Paper texture overlay -->
            <div class="absolute inset-0 bg-[#fdfdfd] opacity-90 z-0"></div>
            <!-- Grid for analysis -->
            <div
              class="absolute inset-0 z-0 opacity-20"
              style="
                background-image: linear-gradient(#000 1px, transparent 1px),
                  linear-gradient(90deg, #000 1px, transparent 1px);
                background-size: 20px 20px;
              "
            ></div>

            <!-- The Item/Crate -->
            <div
              class="relative z-10 w-full h-full flex items-center justify-center grayscale contrast-125 sepia-[.3]"
              :class="{ 'crt-flicker': store.labState.currentStage >= 4 }"
            >
              <span
                class="text-8xl filter drop-shadow-md transition-transform duration-300 transform group-hover:scale-110"
                >📦</span
              >
            </div>

            <!-- Scanning Line (Ruler) -->
            <div
              class="absolute top-0 left-0 w-full h-[1px] bg-red-500 z-20 animate-[scan_3s_ease-in-out_infinite] opacity-50"
            ></div>
          </div>
        </div>

        <!-- Controls (Clipboard Form) -->
        <div
          class="flex flex-col gap-0 min-w-[300px] paper-card bg-white p-6 rotate-1"
        >
          <!-- Clip visual -->
          <div
            class="h-4 bg-gray-300 rounded-t-lg mx-auto w-24 -mt-8 mb-4 border border-gray-400 relative"
          >
            <div
              class="absolute top-1 left-2 right-2 h-1 bg-black/10 rounded-full"
            ></div>
          </div>

          <div class="font-mono text-xs mb-6 border-b border-gray-200 pb-4">
            <div class="flex justify-between mb-1">
              <span class="text-gray-600">Subject ID:</span>
              <span class="font-bold"
                >UNK-{{ Math.floor(Math.random() * 9999) }}</span
              >
            </div>
            <div class="flex justify-between items-center">
              <span class="text-gray-600">Potential:</span>
              <span
                class="font-bold px-1"
                :class="store.labState.currentStage >= 3 ? 'bg-yellow-200' : ''"
              >
                {{
                  store.labState.currentStage >= 3
                    ? "HIGH VALUE WARNING"
                    : "STANDARD"
                }}
              </span>
            </div>
          </div>

          <div class="flex flex-col gap-3">
            <button
              @click="handleSift()"
              :disabled="store.isExtracting"
              class="w-full py-3 border-2 border-black font-bold uppercase hover:bg-black hover:text-white transition-colors relative overflow-hidden group disabled:opacity-50"
            >
              <span class="relative z-10">{{
                store.isExtracting
                  ? "Stabilizing..."
                  : `Process Layer ${store.labState.currentStage + 1}`
              }}</span>
              <!-- Ink fill hover effect could go here -->
            </button>
            <div class="text-center font-mono text-[10px] text-gray-400 py-1">
              - OR -
            </div>
            <button
              @click="handleClaim()"
              :disabled="store.isExtracting"
              class="w-full py-3 border-2 border-dashed border-green-600 text-green-700 font-bold uppercase hover:bg-green-50 transition-colors disabled:opacity-50"
            >
              Catalog Now
            </button>
          </div>
        </div>
      </div>

      <!-- Footer Warning sticker -->
      <div
        class="bg-yellow-50 border border-yellow-200 p-3 flex items-start gap-3 max-w-2xl mx-auto shadow-sm"
      >
        <span class="text-xl">⚠️</span>
        <p class="text-xs text-yellow-800 font-sans leading-relaxed">
          <strong>CAUTION:</strong> Continued processing increases specimen
          granularity but risks total decoherence. Shattered specimens
          <span class="underline decoration-red-400 decoration-wavy"
            >cannot be recovered</span
          >.
        </p>
      </div>
    </div>

    <!-- REVEAL OVERLAY -->
    <div
      v-if="revealedItem"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm"
      @click="revealedItem = null"
    >
      <div class="flash-overlay"></div>
      <!-- White flash animation -->
      <div
        class="bg-white p-12 border-4 border-ink-black shadow-[20px_20px_0_0_rgba(255,255,255,0.2)] text-center animate-shake-heavy relative max-w-md w-full"
        @click.stop
      >
        <!-- Header -->
        <div
          class="absolute -top-6 left-1/2 -translate-x-1/2 bg-stamp-red text-white px-4 py-1 font-mono font-bold rotate-[-2deg] shadow-lg border-2 border-white"
        >
          CATALOG SUCCESS
        </div>

        <!-- Item Icon -->
        <div
          class="text-9xl mb-8 filter drop-shadow-xl crt-flicker animate-bounce pt-6"
        >
          {{
            revealedItem.tier === "mythic"
              ? "👑"
              : revealedItem.tier === "unique"
              ? "🏺"
              : "💎"
          }}
        </div>

        <div class="space-y-4">
          <h2
            class="text-4xl font-serif font-black uppercase leading-none tracking-tight"
          >
            {{ revealedItem.item_id.replace(/_/g, " ") }}
          </h2>

          <div class="flex justify-center gap-2">
            <div
              class="text-xl font-mono font-bold inline-block px-3 py-1 border-2 border-ink-black bg-gray-100"
              :class="
                revealedItem.mint_number <= 10
                  ? 'text-stamp-red border-stamp-red bg-red-50'
                  : 'text-gray-700'
              "
            >
              MINT #{{ String(revealedItem.mint_number).padStart(3, "0") }}
            </div>
          </div>

          <div class="pt-6 mt-6 border-t border-gray-200">
            <button
              @click="revealedItem = null"
              class="px-8 py-2 bg-black text-white font-bold hover:bg-gray-800 transition-colors uppercase font-mono text-sm"
            >
              Secure to Vault
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
@keyframes scan {
  0% {
    top: 0;
    opacity: 0;
  }
  10% {
    opacity: 1;
  }
  90% {
    opacity: 1;
  }
  100% {
    top: 100%;
    opacity: 0;
  }
}
</style>
