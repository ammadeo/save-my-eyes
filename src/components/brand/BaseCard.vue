<script setup lang="ts">
withDefaults(defineProps<{ absolute?: boolean }>(), { absolute: false });
</script>

<template>
  <!-- Raised glass group; the inner box scrolls (glass-group clips its overflow). Callers cap the height. -->
  <div class="glass-group is-raised flex w-full flex-col" :class="absolute ? ['absolute', 'is-floating'] : ['relative']">
    <div class="flex min-h-0 flex-1 flex-col overflow-y-auto overscroll-contain p-4">
      <slot />
    </div>
  </div>
</template>

<style scoped>
/* Floating cards overlap other controls on the cover: blur what is under them so it never reads through. */
.glass-group.is-floating {
  -webkit-backdrop-filter: blur(24px) saturate(1.2);
  backdrop-filter: blur(24px) saturate(1.2);
}
</style>
