<template>
  <component
    :is="as"
    class="rounded-full"
    :class="[
      ...autoColorClasses(...autoColorSplit(color)),
      ...autoBorderClasses(elevation)
    ]"
  >
    <slot />
  </component>
</template>

<script lang="ts">
import {
  AutoBorderClasses,
  AutoColorClasses
} from '../utils/mixins/autoClasses'
import Vue from 'vue'
export default Vue.extend({
  mixins: [AutoBorderClasses, AutoColorClasses],
  props: {
    color: {
      type: String,
      default: 'secondary-800'
    },
    as: {
      type: String,
      default: 'div'
    },
    elevation: {
      type: Number,
      default: 4
    }
  }
})
</script>
