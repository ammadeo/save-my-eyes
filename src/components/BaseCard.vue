<template>
  <div ref="card" class="relative items-stretch flex flex-col w-full">
    <div
      class="rounded-lg absolute bg-secondary-1200 shadow-inner-1 inset-0 top-0 left-0"
    ></div>
    <div
      class="flex flex-1 flex-col shadow-xl rounded-lg bg-gradient-card scroll-smooth scroll-sm relative transform  -translate-y-1"
    >
      <slot />
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'

export default Vue.extend({})
</script>
