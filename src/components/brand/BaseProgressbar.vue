<script setup lang="ts">
import { computed } from "vue";

const props = defineProps<{ min: number; max: number; value: number }>();
const progress = computed(() => ((props.max - props.value - props.min) / props.max) * 100);
</script>

<template>
  <div
    class="relative h-full w-full flex-1 overflow-hidden rounded-full"
    role="progressbar"
    :aria-valuenow="Math.round(value)"
    :aria-valuemin="min"
    :aria-valuemax="max"
  >
    <div class="absolute inset-0 rounded-full bg-primary-600 shadow-sm" :style="{ transform: `translateX(-${progress}%)` }" />
    <div class="h-full w-full rounded-full bg-secondary-1050 inset-shadow-2-top-2" />
    <slot />
  </div>
</template>
