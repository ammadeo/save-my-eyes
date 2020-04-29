<template>
  <div
    ref="card"
    class="rounded-lg scroll-smooth max-h-screen-card overflow-y-hidden overflow-x-hidden scroll-sm rounded-lg min-h-full flex flex-col w-full"
    :class="[
      ...autoColorClasses(...autoColorSplit(color)),
      ...autoBorderClasses(6)
    ]"
  >
    <slot />
  </div>
</template>

<script lang="ts">
import {
  AutoBorderClasses,
  AutoColorClasses
} from '../utils/mixins/autoClasses'
import mixins from 'vue-typed-mixins'

export default mixins(AutoBorderClasses, AutoColorClasses).extend({
  props: {
    color: {
      type: String,
      default: 'secondary-800'
    }
  }
})
</script>
