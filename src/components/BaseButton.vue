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
import {
  AutoBorderClasses,
  AutoColorClasses
} from '../utils/mixins/autoClasses'

import mixins from 'vue-typed-mixins'
export default mixins(AutoBorderClasses, AutoColorClasses).extend({
  props: {
    primary: {
      default: false,
      type: Boolean
    }
  },
  computed: {
    classesTop() {
      const autoColorClasses = this.autoColorClasses
      // const autoBorderClasses = this.autoBorderClasses
      return [
        // ...autoBorderClasses(4),
        // ...autoBorderClasses(2, 'active'),
        ...(this.primary
          ? [
              'text-black',
              ...autoColorClasses('primary', '400'),
              ...autoColorClasses('primary', '500', 'group-hover'),
              ...autoColorClasses('primary', '500', 'group-focus')
            ]
          : [
              'text-secondary-100',
              ...autoColorClasses('secondary', '700'),
              ...autoColorClasses('secondary', '800', 'group-hover'),
              ...autoColorClasses('secondary', '800', 'group-focus')
            ])
      ]
    },
    classesBottom() {
      const autoColorClasses = this.autoColorClasses
      // const autoBorderClasses = this.autoBorderClasses
      return [
        // ...autoBorderClasses(4),
        // ...autoBorderClasses(2, 'active'),
        ...(this.primary
          ? [
              'text-black',
              ...autoColorClasses('primary', '600'),
              ...autoColorClasses('primary', '700', 'group-hover'),
              ...autoColorClasses('primary', '700', 'group-focus')
            ]
          : [
              'text-secondary-100',
              ...autoColorClasses('secondary', '800'),
              ...autoColorClasses('secondary', '900', 'group-hover'),
              ...autoColorClasses('secondary', '900', 'group-focus')
            ])
      ]
    }
  }
})
</script>
