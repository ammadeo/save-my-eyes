<script setup lang="ts">
import { computed } from "vue";
import BaseProgressbar from "./BaseProgressbar.vue";
import { useCountdown } from "@/composables/useCountdown";
import { t, useI18n } from "@/i18n";

const props = withDefaults(defineProps<{ startDate: Date; endDate: Date; autoFinish?: boolean }>(), {
  autoFinish: false,
});
const emit = defineEmits<{ finished: [] }>();

const { t: tl, tg } = useI18n({
  autoFinish: t("Ends by itself", "Zakończy się sama"),
  progress: t("Break progress", "Postęp przerwy"),
  left: t("left", "zostało"),
});

const { remaining, elapsed, total } = useCountdown(
  () => props.startDate.getTime(),
  () => props.endDate.getTime(),
  () => emit("finished"),
);

const pad = (n: number) => n.toString().padStart(2, "0");
/** "mm : ss", rounded up so a 20 min break starts at 20 : 00 and ends at 00 : 00. */
const timeLeftInfo = computed(() => {
  const secs = Math.ceil(remaining.value / 1000);
  return `${pad(Math.floor(secs / 60))} : ${pad(secs % 60)}`;
});
/** What VoiceOver reads for the timer: "4 min. 59 sec. left". */
const timeLeftSpoken = computed(() => {
  const secs = Math.max(0, Math.ceil(remaining.value / 1000));
  return `${Math.floor(secs / 60)} ${tg("minutesSuffix")} ${secs % 60} ${tg("secondsSuffix")} ${tl("left")}`;
});
const percentage = computed(() => (total.value ? (elapsed.value / total.value) * 100 : 100));
</script>

<template>
  <div
    class="flex w-full max-w-[680px] flex-col gap-6 self-start transition-opacity duration-1000 ease-out"
    :class="remaining <= 0 ? ['opacity-25'] : []"
  >
    <p class="text-display whitespace-nowrap text-label" role="timer" :aria-label="timeLeftSpoken">{{ timeLeftInfo }}</p>
    <div class="flex flex-col gap-2">
      <BaseProgressbar :min="0" :max="100" :value="percentage" :label="tl('progress')" />
      <!-- Short breaks close themselves when the time is up; say so instead of a lone glyph. -->
      <p v-if="autoFinish" class="text-footnote text-label-secondary">{{ tl("autoFinish") }}</p>
    </div>
  </div>
</template>
