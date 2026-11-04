<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import { format, formatDistanceStrict } from "date-fns";
import BaseIcon from "../BaseIcon.vue";
import { getBreakState, getCalendarStatus, type BreakState, type CalendarStatus } from "@/bridge";
import { useEvent } from "@/composables/useEvent";
import { useNow } from "@/composables/useNow";
import { dateLocale, t, useI18n } from "@/i18n";
import type { RunKey } from "./types";

const emit = defineEmits<{ run: [key: RunKey] }>();

const { t: tl, tg } = useI18n({
  breakNext: t("Next", "Następna"),
  breakIn: t("in", "za"),
  breakIsNow: t("is still going", "trwa"),
  heldForMeeting: t("Waiting for your meeting to end", "Czeka na koniec spotkania"),
  meetingUntil: t("until {time}", "do {time}"),
  meetingUntitled: t("Busy", "Zajęte"),
  callPaused: t("Breaks paused until the end of your call", "Przerwy wstrzymane do końca rozmowy"),
  callNext: t("Your next break is scheduled after the meeting", "Następna przerwa zaplanowana jest po spotkaniu"),
  buttonStartLongBreak: t("Start a long break now", "Zacznij długą przerwę teraz"),
  buttonStopProtection: t("Stop protection", "Wstrzymaj ochronę"),
  buttonSettings: t("Settings", "Ustawienia"),
  buttonQuit: t("Quit Save My Eyes", "Zakończ Save My Eyes"),
});

const state = ref<BreakState>();
const calendar = ref<CalendarStatus>();
const now = useNow(1000);

onMounted(async () => {
  try {
    state.value = await getBreakState();
  } catch {
    // unknown until a `break-state` event arrives
  }
  try {
    calendar.value = await getCalendarStatus();
  } catch {
    // no meeting line until a `calendar-status` event arrives
  }
});
useEvent("break-state", (next) => (state.value = next));
useEvent("calendar-status", (next) => (calendar.value = next));

const meeting = computed(() => {
  const m = calendar.value?.meeting;
  if (!m || Date.parse(m.until) <= now.value) return undefined;
  return {
    title: m.title.trim() || tl("meetingUntitled"),
    until: tl("meetingUntil").replace("{time}", format(Date.parse(m.until), "p", { locale: dateLocale.value })),
  };
});

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
    <div v-if="meeting && !isBreakNow" class="glass-group status" role="status">
      <p class="status-label meeting">
        <svg class="meeting-icon" viewBox="0 0 12 12" width="12" height="12" aria-hidden="true">
          <rect x="1" y="2" width="10" height="9" rx="2" fill="none" stroke="currentColor" stroke-width="1.2" />
          <path d="M1 5h10M4 1v2M8 1v2" fill="none" stroke="currentColor" stroke-width="1.2" stroke-linecap="round" />
        </svg>
        <span class="meeting-title">{{ meeting.title }}</span>
        <span class="shrink-0">· {{ meeting.until }}</span>
      </p>
      <p class="call-paused">{{ tl("callPaused") }}</p>
      <p class="status-note">{{ tl("callNext") }}</p>
    </div>
    <div v-else class="glass-group status">
      <p class="status-label first-letter:uppercase">{{ label }}</p>
      <p v-if="!isBreakNow" class="status-value">{{ nextBreakTime }}</p>
      <p v-if="!isBreakNow && state?.heldForMeeting" class="status-note">{{ tl("heldForMeeting") }}</p>
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
.status-note {
  margin: 4px 0 0;
  font-size: 11px;
  line-height: 14px;
  color: var(--label-secondary);
}
.meeting {
  display: flex;
  align-items: center;
  gap: 6px;
  white-space: nowrap;
}
.meeting-icon {
  flex-shrink: 0;
}
.meeting-title {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
}
.call-paused {
  margin: 4px 0 0;
  font-size: 17px;
  line-height: 22px;
  font-weight: 500;
  text-wrap: balance;
}
.chevron {
  flex-shrink: 0;
  color: var(--label-tertiary);
}
</style>
