<template>
  <div class="h-40 md:h-48 lg:h-56 xl:h-64 relative">
    <div
      ref="card"
      class="rounded-lg scroll-smooth focus:outline-none max-h-screen-card overflow-y-hidden overflow-x-hidden scroll-sm rounded-lg min-h-full transform hover:overflow-y-auto hover:-translate-y-card-40 md:hover:-translate-y-card-48 lg:hover:-translate-y-card-56 xl:hover:-translate-y-card-64 duration-500 transition-transform ease-out flex flex-col absolute left-0 top-0 w-full"
      :class="[
        ...autoColorClasses(...autoColorSplit(color)),
        ...autoBorderClasses(6),
        ...autoFocusWithinCardClasses(focused),
      ]"
      tabindex="0"
      @mouseleave="focusOut()"
      @mouseover="focusIn()"
    >
      <slot />
    </div>
  </div>
</template>

<script>
import {
  AutoBorderClasses,
  AutoColorClasses,
  AutoFocusWithinCardClasses,
} from '../utils/mixins/autoClasses'
export default {
  mixins: [AutoBorderClasses, AutoColorClasses, AutoFocusWithinCardClasses],
  props: {
    color: {
      type: String,
      default: 'secondary-800',
    },
  },
  data() {
    return {
      focused: false,
    }
  },
  mounted() {
    const card = this.$refs.card
    card.addEventListener('focusin', this.focusIn)
    card.addEventListener('focusout', this.focusOut)
  },
  beforeDestroy() {
    const card = this.$refs.card
    card.removeEventListener('focusin', this.focusIn)
    card.removeEventListener('focusout', this.focusOut)
  },
  methods: {
    focusIn() {
      // console.log('focusIn')
      this.focused = true
      this.$emit('focusin')
    },
    focusOut() {
      // console.log('focusOut')
      const card = this.$refs.card
      card.scrollTop = 0
      this.focused = false
      this.$emit('focusout')
    },
  },
}
</script>
