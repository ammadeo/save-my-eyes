<script setup lang="ts">
import BaseButton from "./BaseButton.vue";

const props = defineProps<{ on: boolean; label?: string }>();
const emit = defineEmits<{ toggle: [on: boolean] }>();
</script>

<template>
  <button
    type="button"
    role="switch"
    :aria-checked="on"
    :aria-label="label"
    class="relative flex h-11 w-18 cursor-pointer items-center justify-evenly rounded-full bg-secondary-1050 inset-shadow-2-top-2 focus:outline-hidden"
    @click="emit('toggle', !props.on)"
  >
    <div class="flex h-full scale-75 items-center justify-center opacity-75"><slot name="iconOn" /></div>
    <div class="flex h-full scale-75 items-center justify-center opacity-75"><slot name="iconOff" /></div>
    <BaseButton
      class="bottom-0 left-0 h-10 w-10 transition-transform duration-100 ease-in"
      :class="on ? [] : ['translate-x-8']"
      center
      absolute
      tabindex="-1"
      aria-hidden="true"
    >
      <slot v-if="on" name="iconOn" />
      <slot v-else name="iconOff" />
    </BaseButton>
  </button>
</template>
