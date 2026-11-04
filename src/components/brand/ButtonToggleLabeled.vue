<script setup lang="ts">
import ButtonToggle from "./ButtonToggle.vue";

defineProps<{ on: boolean; stateOn: string; stateOff: string }>();
const emit = defineEmits<{ toggle: [on: boolean] }>();
</script>

<template>
  <div class="flex items-center gap-2">
    <ButtonToggle :on="on" :label="on ? stateOn : stateOff" class="shrink-0" @toggle="emit('toggle', $event)">
      <template v-if="$slots.iconOn" #iconOn><slot name="iconOn" /></template>
      <template v-if="$slots.iconOff" #iconOff><slot name="iconOff" /></template>
    </ButtonToggle>
    <p class="text-body text-label">{{ on ? stateOn : stateOff }}</p>
  </div>
</template>
