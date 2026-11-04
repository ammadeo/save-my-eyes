<script setup lang="ts">
import { computed } from "vue";
import { differenceInMinutes, formatDistanceStrict } from "date-fns";
import { dateLocale, t, useI18n } from "@/i18n";
import { useNow } from "@/composables/useNow";

const props = withDefaults(defineProps<{ startDate: Date; endDate: Date; long?: boolean; finished?: boolean }>(), {
  long: false,
  finished: false,
});

const { t: tl } = useI18n({
  shortBreakFinished: t("short break has ended", "krótka przerwa zakończyła się"),
  longBreakFinished: t("long break has ended", "długa przerwa zakończyła się"),
  shortBreakStarted: t("take a short break for", "krótka przerwa przez"),
  longBreakStarted: t("take a long break for", "długa przerwa przez"),
});

const now = useNow(15_000);

const breakTime = computed(() =>
  formatDistanceStrict(props.startDate, props.endDate, { roundingMethod: "floor", locale: dateLocale.value }),
);

/** "2 minutes ago" once at least a minute has passed since the end. */
const timeAgo = computed(() => {
  const current = new Date(now.value);
  if (differenceInMinutes(current, props.endDate) < 1) return "";
  return formatDistanceStrict(props.endDate, current, {
    roundingMethod: "floor",
    addSuffix: true,
    locale: dateLocale.value,
  });
});

const info = computed(() => {
  const type = props.long ? "longBreak" : "shortBreak";
  if (props.finished) return `${tl(`${type}Finished`)} ${timeAgo.value}`.trim();
  return `${tl(`${type}Started`)} ${breakTime.value}`;
});
</script>

<template>
  <p class="text-large-title max-w-[40ch] text-label first-letter:uppercase" aria-live="polite">{{ info }}</p>
</template>
