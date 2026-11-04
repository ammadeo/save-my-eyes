<script setup lang="ts">
withDefaults(defineProps<{ absolute?: boolean }>(), { absolute: false });
</script>

<template>
  <div
    class="flex max-h-full w-full flex-col items-stretch rounded-lg shadow-xl-revers"
    :class="absolute ? 'absolute' : 'relative'"
  >
    <div class="absolute inset-0 max-h-full rounded-lg bg-secondary-1075 inset-shadow-1" />
    <div
      class="scroll-sm relative flex max-h-full flex-1 -translate-y-2 flex-col overflow-auto scroll-smooth rounded-lg bg-gradient-card"
    >
      <slot />
    </div>
  </div>
</template>
