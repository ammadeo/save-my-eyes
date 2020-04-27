<template>
  <component
    :is="as"
    class="rounded-full"
    :class="[
      ...autoColorClasses(...autoColorSplit(color)),
      ...autoBorderClasses(elevation),
    ]"
  >
    <slot />
  </component>
</template>

<script>
import {
  AutoBorderClasses,
  AutoColorClasses,
} from '../utils/mixins/autoClasses'
export default {
  mixins: [AutoBorderClasses, AutoColorClasses],
  props: {
    color: {
      type: String,
      default: 'secondary-800',
    },
    as: {
      type: String,
      default: 'div',
    },
    elevation: {
      type: Number,
      default: 4,
    },
  },
}
</script>
