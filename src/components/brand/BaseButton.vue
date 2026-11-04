<script setup lang="ts">
import { computed } from "vue";

const props = withDefaults(
  defineProps<{ primary?: boolean; center?: boolean; absolute?: boolean; disabled?: boolean }>(),
  { primary: false, center: false, absolute: false, disabled: false },
);
const emit = defineEmits<{ click: [] }>();

const classesTop = computed(() => [
  ...(props.primary
    ? ["text-primary-50", "bg-primary-700", props.disabled ? "" : "group-hocus:bg-primary-800"]
    : ["text-secondary-50", "bg-secondary-700", props.disabled ? "" : "group-hocus:bg-secondary-800"]),
  props.center ? "justify-center" : "justify-between",
  ...(props.disabled ? [] : ["-translate-y-1", "group-active:-translate-y-px"]),
]);

const classesBottom = computed(() =>
  props.primary
    ? ["bg-primary-800", props.disabled ? "" : "group-hocus:bg-primary-900"]
    : ["bg-secondary-800", props.disabled ? "" : "group-hocus:bg-secondary-900"],
);
</script>

<template>
  <button
    type="button"
    class="group flex flex-col items-stretch rounded-full shadow-lg-revers transition-shadow duration-100 focus:outline-hidden active:shadow-revers disabled:cursor-not-allowed disabled:opacity-50"
    :class="absolute ? 'absolute' : 'relative'"
    :disabled="disabled"
    @click="emit('click')"
  >
    <div class="absolute inset-0 rounded-full inset-shadow-1" :class="classesBottom" />
    <div
      class="relative flex flex-1 items-center rounded-full shadow-sm transition-transform delay-100 duration-150"
      :class="classesTop"
    >
      <slot />
    </div>
  </button>
</template>
