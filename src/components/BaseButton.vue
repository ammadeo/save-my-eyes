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
      class="rounded-full shadow relative flex-1 flex  items-center transform transition-transform delay-100 -translate-y-1 group-active:-translate-y-px"
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
    center: {
      default: false,
      type: Boolean,
    },
  },
  computed: {
    classesTop() {
      return [
        ...(this.primary
          ? ['text-primary-50', 'bg-primary-700', 'group-hocus:bg-primary-800']
          : [
              'text-secondary-50',
              'bg-secondary-700',
              'group-hocus:bg-secondary-800',
            ]),
        ...(this.center ? ['justify-center'] : ['justify-between']),
      ]
    },
    classesBottom() {
      return [
        ...(this.primary
          ? ['bg-primary-800', 'group-hocus:bg-primary-900']
          : ['bg-secondary-800', 'group-hocus:bg-secondary-900']),
      ]
    },
  },
})
</script>
