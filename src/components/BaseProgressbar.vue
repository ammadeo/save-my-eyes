<template>
  <div
    class="relative w-full h-full flex-1 rounded-full overflow-hidden"
    role="progressbar"
    :aria-valuenow="value"
    :aria-valuemin="min"
    :aria-valuemax="max"
  >
    <slot />
    <div
      class="rounded-full absolute bg-primary-600 shadow inset-0"
      :style="{ transform: `translateX(-${progress}%)` }"
    ></div>
    <div
      class="h-full w-full shadow-inner-2-top-2 rounded-full bg-secondary-1050"
    ></div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
// import mixins from 'vue-typed-mixins'

export default Vue.extend({
  props: {
    min: {
      type: Number,
      required: true,
    },
    max: {
      type: Number,
      required: true,
    },
    value: {
      type: Number,
      required: true,
    },
  },
  computed: {
    progress(): number {
      return ((this.max - this.value - this.min) / this.max) * 100
    },
  },
})
</script>
