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
    <div class="glass-group status">
      <p class="status-label first-letter:uppercase">{{ label }}</p>
      <p v-if="!isBreakNow" class="status-value">{{ nextBreakTime }}</p>
    </div>

    <button type="button" class="glass-button is-primary is-large w-full" @click="emit('run', 'start-long-break')">
      <BaseIcon icon="start" class="h-[11px]" />
      <span>{{ tl("buttonStartLongBreak") }}</span>
    </button>

    <div class="glass-group">
      <button type="button" class="glass-row" @click="emit('run', 'open-stop-protection')">
        <span class="glass-row-icon"><BaseIcon icon="pause" class="h-[12px]" /></span>
        <span class="grow">{{ tl("buttonStopProtection") }}</span>
        <svg class="chevron" viewBox="0 0 7 12" width="7" height="12" aria-hidden="true">
          <path d="m1 1 5 5-5 5" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" />
        </svg>
      </button>
      <button type="button" class="glass-row" @click="emit('run', 'open-settings')">
        <span class="glass-row-icon"><BaseIcon icon="settings" class="h-[13px]" /></span>
        <span class="grow">{{ tl("buttonSettings") }}</span>
        <svg class="chevron" viewBox="0 0 7 12" width="7" height="12" aria-hidden="true">
          <path d="m1 1 5 5-5 5" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" />
        </svg>
      </button>
    </div>

    <div class="glass-group">
      <button type="button" class="glass-row" @click="emit('run', 'quit')">
        <span class="glass-row-icon"><BaseIcon icon="stop" class="h-[11px]" /></span>
        <span class="grow text-destructive">{{ tl("buttonQuit") }}</span>
        <kbd aria-hidden="true">⌘Q</kbd>
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
  padding: 12px 14px 14px;
}
.status-label {
  margin: 0;
  color: var(--label-secondary);
}
.status-value {
  margin: 2px 0 0;
  font-size: 26px;
  line-height: 32px;
  font-weight: 500;
  font-variant-numeric: tabular-nums;
}
.chevron {
  flex-shrink: 0;
  color: var(--label-tertiary);
}
</style>
