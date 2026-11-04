<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import { formatDistanceStrict } from "date-fns";
import BaseIcon from "../BaseIcon.vue";
import { getBreakState, type BreakState } from "@/bridge";
import { useEvent } from "@/composables/useEvent";
import { useNow } from "@/composables/useNow";
import { dateLocale, t, useI18n } from "@/i18n";
import type { RunKey } from "./types";

const emit = defineEmits<{ run: [key: RunKey] }>();

const { t: tl, tg } = useI18n({
  breakNext: t("Next", "Następna"),
  breakIn: t("in", "za"),
  breakIsNow: t("is still going", "trwa"),
  buttonStartLongBreak: t("Start a long break now", "Zacznij długą przerwę teraz"),
  buttonStopProtection: t("Stop protection", "Wstrzymaj ochronę"),
  buttonSettings: t("Settings", "Ustawienia"),
  buttonCoffee: t("Buy me a coffee", "Zamów mi kawę"),
  buttonQuit: t("Quit Save My Eyes", "Zakończ Save My Eyes"),
});

const state = ref<BreakState>();
const now = useNow(1000);

onMounted(async () => {
  try {
    state.value = await getBreakState();
  } catch {
    // unknown until a `break-state` event arrives
  }
});
useEvent("break-state", (next) => (state.value = next));

const scheduledAt = computed(() => (state.value?.scheduledAt ? Date.parse(state.value.scheduledAt) : undefined));
const isBreakNow = computed(
  () => !!state.value && (state.value.phase !== "idle" || (scheduledAt.value !== undefined && scheduledAt.value <= now.value)),
);
const breakName = computed(() => (state.value?.isLong ? tg("breakLong") : tg("breakShort")));
const label = computed(() =>
  isBreakNow.value ? `${breakName.value} ${tl("breakIsNow")}` : `${tl("breakNext")} ${breakName.value} ${tl("breakIn")}`,
);
const nextBreakTime = computed(() =>
  scheduledAt.value === undefined
    ? "—"
    : formatDistanceStrict(now.value, scheduledAt.value, { roundingMethod: "floor", locale: dateLocale.value }),
);
</script>

<template>
  <section class="menu-pane">
    <div class="mac-group status">
      <p class="status-label first-letter:uppercase">{{ label }}</p>
      <p v-if="!isBreakNow" class="status-value">{{ nextBreakTime }}</p>
    </div>

    <button type="button" class="mac-button is-default is-large start" @click="emit('run', 'start-long-break')">
      <BaseIcon icon="start" class="h-3" />
      <span>{{ tl("buttonStartLongBreak") }}</span>
    </button>

    <div class="mac-group">
      <button type="button" class="mac-row" @click="emit('run', 'open-stop-protection')">
        <span class="row-icon tint-orange"><BaseIcon icon="pause" class="h-2.5" /></span>
        <span class="grow">{{ tl("buttonStopProtection") }}</span>
        <span class="chevron" aria-hidden="true">›</span>
      </button>
      <button type="button" class="mac-row" @click="emit('run', 'open-settings')">
        <span class="row-icon tint-gray"><BaseIcon icon="settings" class="h-3" /></span>
        <span class="grow">{{ tl("buttonSettings") }}</span>
        <span class="chevron" aria-hidden="true">›</span>
      </button>
    </div>

    <div class="mac-group">
      <button type="button" class="mac-row" @click="emit('run', 'coffee')">
        <span class="row-icon tint-brown"><BaseIcon icon="coffee" class="h-3" /></span>
        <span class="grow">{{ tl("buttonCoffee") }}</span>
        <span class="chevron" aria-hidden="true">↗</span>
      </button>
      <button type="button" class="mac-row" @click="emit('run', 'quit')">
        <span class="row-icon tint-red"><BaseIcon icon="stop" class="h-2.5" /></span>
        <span class="grow">{{ tl("buttonQuit") }}</span>
        <kbd class="shortcut">⌘Q</kbd>
      </button>
    </div>
  </section>
</template>

<style scoped>
.menu-pane {
  display: flex;
  flex-direction: column;
  gap: 14px;
}
.status {
  padding: 14px 14px 16px;
}
.status-label {
  margin: 0;
  color: var(--mac-label-secondary);
}
.status-value {
  margin: 2px 0 0;
  font-size: 26px;
  font-weight: 600;
  letter-spacing: -0.01em;
  font-variant-numeric: tabular-nums;
}
.start {
  width: 100%;
}
.row-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 20px;
  height: 20px;
  border-radius: 5px;
  color: #fff;
}
.tint-orange {
  background: #ff9500;
}
.tint-gray {
  background: #8e8e93;
}
.tint-brown {
  background: #a2845e;
}
.tint-red {
  background: #ff3b30;
}
.chevron,
.shortcut {
  color: var(--mac-label-tertiary);
  font-size: 15px;
  font-family: inherit;
}
.shortcut {
  font-size: 12px;
}
</style>
