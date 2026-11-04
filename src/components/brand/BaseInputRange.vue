<script setup lang="ts">
import { computed, ref, useId } from "vue";
import { t, useI18n } from "@/i18n";

const props = withDefaults(
  defineProps<{
    modelValue: number;
    min: number;
    max: number;
    name: string;
    scale?: number;
    step?: number;
    suffix?: string;
    forceLarge?: boolean;
  }>(),
  { scale: 1, step: 1, suffix: "", forceLarge: false },
);
const emit = defineEmits<{ "update:modelValue": [value: number]; blur: [] }>();

const { t: tl } = useI18n({
  warningTooMuch: t("You can't set more than", "Musi być mniejsza niż"),
  warningTooSmall: t("You can't set less than", "Musi być większa niż"),
});

const id = useId();
const input = ref<HTMLInputElement>();
const warning = ref("");

const floorValue = computed(() => Math.floor(props.modelValue / props.scale));
const widthClass = computed(() => {
  const length = floorValue.value.toString().length;
  return length <= 1 ? "w-4" : length === 2 ? "w-6" : "w-8";
});
const large = (onForce: string[], otherwise: string[] = []) => (props.forceLarge ? onForce : otherwise);

function onInput(event: Event) {
  const value = Number((event.target as HTMLInputElement).value);
  warning.value = "";
  if (value < props.min) warning.value = `${tl("warningTooSmall")} ${props.min} ${props.suffix}`;
  if (value > props.max) warning.value = `${tl("warningTooMuch")} ${props.max} ${props.suffix}`;
  emit("update:modelValue", value * props.scale);
}

function onBlur() {
  warning.value = "";
  emit("blur");
}
</script>

<template>
  <div>
    <div class="flex items-center justify-between gap-3">
      <label :for="id" class="text-body text-label">{{ name }}</label>
      <!-- The number field is the keyboard path; the slider below is for the pointer. -->
      <div
        class="number-field flex h-6 shrink-0 cursor-text items-center gap-1 rounded-control border-[0.5px] border-separator bg-surface px-2"
        @click="input?.focus()"
      >
        <input
          :id="id"
          ref="input"
          type="number"
          class="number-input bg-transparent text-right text-label tabular-nums caret-accent"
          :class="widthClass"
          :max="max"
          :min="min"
          :step="step"
          :value="floorValue"
          @input="onInput"
          @blur="onBlur"
        />
        <span class="text-label-secondary">{{ suffix }}</span>
      </div>
    </div>
    <input
      type="range"
      class="glass-slider mt-2"
      :class="large([], ['hidden', 'md:block'])"
      :max="max"
      :min="min"
      :step="step"
      :value="floorValue"
      :aria-label="name"
      tabindex="-1"
      @input="onInput"
      @change="onBlur"
    />
    <div class="mt-0.5 justify-between text-footnote text-label-tertiary" :class="large(['flex'], ['hidden', 'md:flex'])">
      <p>{{ min }} {{ suffix }}</p>
      <p>{{ max }} {{ suffix }}</p>
    </div>
    <Transition name="fade">
      <p v-if="warning" class="mt-2 rounded-control bg-fill px-2 py-1 text-footnote text-warning" role="status">
        {{ warning }}
      </p>
    </Transition>
  </div>
</template>

<style scoped>
.number-input {
  -moz-appearance: textfield;
  border: 0;
  padding: 0;
  font: inherit;
}
/* The field wrapper carries the focus ring, not the bare input. */
.number-input:focus-visible {
  outline: none;
}
.number-field:focus-within {
  outline: 3px solid var(--focus-ring);
  outline-offset: 1px;
}
</style>
