<script setup lang="ts">
import { computed, useId } from "vue";

const props = withDefaults(
  defineProps<{ modelValue: number; label: string; min: number; max: number; step?: number; scale?: number; suffix?: string }>(),
  { step: 1, scale: 1, suffix: "" },
);
const emit = defineEmits<{ "update:modelValue": [value: number] }>();

const id = useId();
const display = computed(() => Math.floor(props.modelValue / props.scale));
const onInput = (event: Event) => emit("update:modelValue", Number((event.target as HTMLInputElement).value) * props.scale);
</script>

<template>
  <div class="glass-row slider-row">
    <div class="slider-top">
      <label :for="id">{{ label }}</label>
      <output :for="id" class="slider-value">{{ display }}&nbsp;{{ suffix }}</output>
    </div>
    <input
      :id="id"
      type="range"
      class="glass-slider"
      :min="min"
      :max="max"
      :step="step"
      :value="display"
      :aria-valuetext="`${display} ${suffix}`.trim()"
      @input="onInput"
    />
  </div>
</template>

<style scoped>
.slider-row {
  flex-direction: column;
  align-items: stretch;
  gap: 4px;
  padding-top: 9px;
  padding-bottom: 7px;
}
.slider-top {
  display: flex;
  justify-content: space-between;
  gap: 8px;
}
.slider-value {
  flex-shrink: 0;
  color: var(--label-secondary);
  font-variant-numeric: tabular-nums;
}
</style>
