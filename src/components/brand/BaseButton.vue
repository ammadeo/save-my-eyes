<script setup lang="ts">
/**
 * Glass push button (DESIGN.md › Buttons). Quiet by default, `primary` is the one sage
 * control of a screen. Size and tone modifiers pass through as classes from callers
 * (`is-large`, `is-xl`, `is-destructive`, `is-plain`).
 */
withDefaults(defineProps<{ primary?: boolean; center?: boolean; absolute?: boolean; disabled?: boolean }>(), {
  primary: false,
  center: false,
  absolute: false,
  disabled: false,
});
const emit = defineEmits<{ click: [] }>();
</script>

<template>
  <button
    type="button"
    class="glass-button"
    :class="[primary ? 'is-primary' : '', center ? '' : 'is-spread', absolute ? 'absolute' : 'relative']"
    :disabled="disabled"
    @click="emit('click')"
  >
    <slot />
  </button>
</template>

<style scoped>
/* glass.css centres content; non-centred buttons spread label and icon. */
.glass-button.is-spread {
  justify-content: space-between;
}
</style>
