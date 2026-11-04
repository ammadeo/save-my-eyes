<script setup lang="ts">
const props = defineProps<{ on: boolean; label?: string }>();
const emit = defineEmits<{ toggle: [on: boolean] }>();
</script>

<template>
  <!-- A macOS-style switch; the icon slots, when given, show the current state beside it. -->
  <button
    type="button"
    role="switch"
    :aria-checked="on"
    :aria-label="label"
    class="switch inline-flex items-center gap-2"
    @click="emit('toggle', !props.on)"
  >
    <span class="switch-track" :class="{ 'is-on': on }" aria-hidden="true"><span class="switch-knob" /></span>
    <span v-if="$slots.iconOn || $slots.iconOff" class="inline-flex h-3.5 items-center text-label-secondary" aria-hidden="true">
      <slot v-if="on" name="iconOn" />
      <slot v-else name="iconOff" />
    </span>
  </button>
</template>

<style scoped>
.switch {
  -webkit-appearance: none;
  appearance: none;
  min-height: 24px;
  padding: 0;
  border: 0;
  background: transparent;
  color: inherit;
  font: inherit;
}
.switch:focus-visible {
  border-radius: 999px;
}
.switch-track {
  position: relative;
  flex-shrink: 0;
  width: 26px;
  height: 16px;
  border-radius: 999px;
  background: var(--fill);
  border: 0.5px solid var(--separator);
  box-sizing: border-box;
  transition: background-color 150ms ease-out;
}
.switch-track.is-on {
  background: var(--accent);
  border-color: transparent;
}
.switch-knob {
  position: absolute;
  top: 1.5px;
  left: 1.5px;
  width: 12px;
  height: 12px;
  border-radius: 999px;
  background: oklch(100% 0 0);
  border: 0.5px solid var(--separator);
  box-sizing: border-box;
  transition: transform 150ms cubic-bezier(0.25, 0.8, 0.25, 1);
}
.is-on .switch-knob {
  transform: translateX(10px);
}
@media (prefers-reduced-motion: reduce) {
  .switch-track,
  .switch-knob {
    transition: none;
  }
}
</style>
