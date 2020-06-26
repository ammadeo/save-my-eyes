<template>
  <button
    class="group flex flex-col rounded-full items-stretch focus:outline-none disabled:opacity-50 disabled:cursor-not-allowed transition-shadow duration-100 shadow-lg-revers active:shadow-revers"
    :class="absolute ? ['absolute'] : ['relative']"
    @click="$emit('click')"
    :disabled="disabled"
  >
    <div
      class="rounded-full absolute shadow-inner-1 inset-0 top-0 left-0"
      :class="classesBottom"
    ></div>
    <div
      class="rounded-full shadow relative flex-1 flex items-center transform transition-transform delay-100"
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
    absolute: {
      default: false,
      type: Boolean,
    },
    disabled: {
      default: false,
      type: Boolean,
    },
  },
  computed: {
    classesTop() {
      const disabled = this.disabled
      return [
        ...(this.primary
          ? [
              'text-primary-50',
              'bg-primary-700',
              disabled ? '' : 'group-hocus:bg-primary-800',
            ]
          : [
              'text-secondary-50',
              'bg-secondary-700',
              disabled ? '' : 'group-hocus:bg-secondary-800',
            ]),
        ...(this.center ? ['justify-center'] : ['justify-between']),
        ...(disabled ? [] : ['-translate-y-1', 'group-active:-translate-y-px']),
      ]
    },
    classesBottom() {
      return [
        ...(this.primary
          ? [
              'bg-primary-800',
              this.disabled ? '' : 'group-hocus:bg-primary-900',
            ]
          : [
              'bg-secondary-800',
              this.disabled ? '' : 'group-hocus:bg-secondary-900',
            ]),
      ]
    },
  },
})
</script>
