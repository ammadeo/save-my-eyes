<script setup lang="ts">
import { computed } from "vue";

const props = defineProps<{ min: number; max: number; value: number; label: string }>();
const progress = computed(() => ((props.max - props.value - props.min) / props.max) * 100);
</script>

<template>
  <div
    class="glass-progress is-wide w-full"
    role="progressbar"
    :aria-label="label"
    :aria-valuenow="Math.round(value)"
    :aria-valuemin="min"
    :aria-valuemax="max"
  >
    <!-- The bar slides in from the left; the countdown ticks every 250 ms, the transition fills the gaps. -->
    <div
      class="glass-progress-bar absolute inset-0 transition-transform duration-[250ms] ease-linear motion-reduce:transition-none"
      :style="{ transform: `translateX(-${progress}%)` }"
    />
    <slot />
  </div>
</template>
