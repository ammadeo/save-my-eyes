<script setup lang="ts">
import { useStopProtection } from "@/composables/useStopProtection";

const emit = defineEmits<{ close: [] }>();
const { t, options, pause, quit } = useStopProtection();

async function pauseFor(hours: number) {
  if (await pause(hours)) emit("close");
}
</script>

<template>
  <section class="stop-pane">
    <div>
      <h2 class="glass-section-title">{{ t("stopFor") }}</h2>
      <div class="hours">
        <button
          v-for="option in options"
          :key="option.hours"
          type="button"
          class="glass-button is-large"
          data-testid="button-pause-break"
          @click="pauseFor(option.hours)"
        >
          {{ option.label }}
        </button>
      </div>
    </div>

    <div>
      <div class="glass-group">
        <button type="button" class="glass-row" data-testid="button-close-app" @click="quit">
          <span class="grow text-destructive">{{ t("turnOffContent") }}</span>
        </button>
      </div>
      <p class="glass-footnote">{{ t("turnOffInfo") }}</p>
    </div>
  </section>
</template>

<style scoped>
.stop-pane {
  display: flex;
  flex-direction: column;
  gap: 18px;
}
.hours {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
}
</style>
