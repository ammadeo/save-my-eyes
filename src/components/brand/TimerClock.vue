<script setup lang="ts">
import { computed } from "vue";
import ProgressbarIcon from "./ProgressbarIcon.vue";
import { useCountdown } from "@/composables/useCountdown";

const props = withDefaults(defineProps<{ startDate: Date; endDate: Date; autoFinish?: boolean }>(), {
  autoFinish: false,
});
const emit = defineEmits<{ finished: [] }>();

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
const percentage = computed(() => (total.value ? (elapsed.value / total.value) * 100 : 100));
</script>

<template>
  <div
    class="relative flex w-full min-w-full items-center self-start transition-opacity duration-1000 ease-in"
    :class="remaining <= 0 ? ['opacity-25'] : []"
  >
    <p
      class="shrink-0 grow-0 pr-6 font-body text-3xl leading-none font-semibold text-secondary-100 tabular-nums"
      role="timer"
    >
      {{ timeLeftInfo }}
    </p>
    <div class="h-12 w-full">
      <ProgressbarIcon :min="0" :max="100" :value="percentage" :icon="autoFinish ? 'finish' : ''" />
    </div>
  </div>
</template>
