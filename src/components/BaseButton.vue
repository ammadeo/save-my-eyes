<template>
  <button
    class="group flex flex-col items-stretch focus:outline-none relative"
    @click="$emit('click')"
  >
    <div
      class="rounded-full absolute shadow-inner-1 inset-0 top-0 left-0"
      :class="classesBottom"
    ></div>
    <div
      class="rounded-full relative flex-1 flex justify-center items-center transform transition-transform delay-100 -translate-y-1 group-active:-translate-y-px"
      :class="classesTop"
    >
      <slot />
    </div>
  </button>
</template>

<script lang="ts">
import Vue from 'vue'

export default Vue.extend({
  props: {
    primary: {
      default: false,
      type: Boolean,
    },
  },
  computed: {
    classesTop() {
      return [
        ...(this.primary
          ? ['text-black', 'bg-primary-400', 'group-hocus:bg-primary-500']
          : [
              'text-secondary-100',
              'bg-secondary-700',
              'group-hocus:bg-secondary-800',
            ]),
      ]
    },
    classesBottom() {
      return [
        ...(this.primary
          ? ['bg-primary-600', 'group-hocus:bg-primary-700']
          : ['bg-secondary-800', 'group-hocus:bg-secondary-900']),
      ]
    },
  },
})
</script>
