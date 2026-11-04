<script setup lang="ts">
import ButtonToggle from "./ButtonToggle.vue";

defineProps<{ on: boolean; stateOn: string; stateOff: string }>();
const emit = defineEmits<{ toggle: [on: boolean] }>();
</script>

<template>
  <div class="flex items-center">
    <ButtonToggle :on="on" :label="on ? stateOn : stateOff" class="shrink-0" @toggle="emit('toggle', $event)">
      <template #iconOn><slot name="iconOn" /></template>
      <template #iconOff><slot name="iconOff" /></template>
    </ButtonToggle>
    <p class="ml-2 font-display text-secondary-200">{{ on ? stateOn : stateOff }}</p>
  </div>
</template>
