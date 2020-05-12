<template>
  <div
    class="items-stretch flex flex-col w-full max-h-full"
    :class="cardClasses"
  >
    <div
      class="rounded-lg absolute bg-secondary-1200 shadow-inner-1 inset-0 top-0 left-0 max-h-full"
    ></div>
    <div
      class="flex flex-1 flex-col max-h-full shadow-xl rounded-lg overflow-auto bg-gradient-card scroll-smooth scroll-sm relative transform  -translate-y-1"
    >
      <slot />
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'

export default Vue.extend({
  props: {
    absolute: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    cardClasses(): string[] {
      return this.absolute ? ['absolute'] : ['relative']
    },
  },
})
</script>
