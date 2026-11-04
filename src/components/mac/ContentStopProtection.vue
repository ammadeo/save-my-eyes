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
      <h2 class="mac-section-title">{{ t("stopFor") }}</h2>
      <div class="mac-group hours">
        <button
          v-for="option in options"
          :key="option.hours"
          type="button"
          class="mac-button is-large"
          data-testid="button-pause-break"
          @click="pauseFor(option.hours)"
        >
          {{ option.label }}
        </button>
      </div>
    </div>

    <div>
      <h2 class="mac-section-title">{{ t("turnOffTitle") }}</h2>
      <div class="mac-group turn-off">
        <button type="button" class="mac-button is-large is-destructive" data-testid="button-close-app" @click="quit">
          {{ t("turnOffContent") }}
        </button>
      </div>
      <p class="mac-footnote">{{ t("turnOffInfo") }}</p>
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
  padding: 12px;
}
.turn-off {
  display: flex;
  padding: 12px;
}
.turn-off .mac-button {
  flex: 1;
}
</style>
