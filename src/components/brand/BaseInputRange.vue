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
  <div class="relative grid grid-cols-[auto_repeat(5,minmax(0,1fr))] gap-x-2">
    <label :for="id" class="col-span-6 mb-1 font-display text-secondary-200">{{ name }}</label>

    <div
      class="row-span-1 flex w-24 cursor-text justify-center rounded-full bg-primary-700 px-2 text-secondary-100 inset-shadow-1 focus-within:bg-primary-800 hover:bg-primary-800 md:col-span-1"
      :class="large(['col-span-1'], ['col-span-6'])"
      @click="input?.focus()"
    >
      <input
        :id="id"
        ref="input"
        type="number"
        class="selection-darker bg-transparent pr-1 text-right font-body outline-hidden"
        :class="widthClass"
        :max="max"
        :min="min"
        :step="step"
        :value="floorValue"
        @input="onInput"
        @blur="onBlur"
      />
      <span class="selection-darker">{{ suffix }}</span>
    </div>
    <input
      type="range"
      class="brand-range col-span-5 md:block"
      :class="large([], ['hidden'])"
      :max="max"
      :min="min"
      :step="step"
      :value="floorValue"
      :aria-label="name"
      tabindex="-1"
      @input="onInput"
      @change="onBlur"
    />

    <p class="col-start-2 col-end-4 text-secondary-200 md:block" :class="large([], ['hidden'])">{{ min }} {{ suffix }}</p>
    <p class="col-start-4 col-end-7 text-right text-secondary-200 md:block" :class="large([], ['hidden'])">
      {{ max }} {{ suffix }}
    </p>
    <Transition name="fade">
      <p v-if="warning" class="absolute top-full z-10 w-full rounded-xs bg-warn-400 px-2 py-1 text-sm text-black shadow-sm">
        {{ warning }}
      </p>
    </Transition>
  </div>
</template>
