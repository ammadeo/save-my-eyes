<template>
  <div class="h-40 md:h-48 lg:h-56 xl:h-64 relative">
    <BaseCard
      ref="card"
      class="focus:outline-none transform hover:overflow-y-auto hover:-translate-y-card-40 md:hover:-translate-y-card-48 lg:hover:-translate-y-card-56 xl:hover:-translate-y-card-64 duration-500 transition-transform ease-out absolute left-0 top-0"
      :class="[...autoFocusWithinCardClasses(focused)]"
      :color="color"
      tabindex="0"
      @mouseleave="focusOut()"
      @mouseover="focusIn()"
    >
      <slot />
    </BaseCard>
  </div>
</template>

<script lang="ts">
import BaseCard from './BaseCard.vue'
import { AutoFocusWithinCardClasses } from '../utils/mixins/autoClasses'
import mixins from 'vue-typed-mixins'

export default mixins(AutoFocusWithinCardClasses).extend({
  components: {
    BaseCard
  },
  props: {
    color: {
      type: String,
      default: 'secondary-800'
    }
  },
  data() {
    return {
      focused: false
    }
  },
  mounted() {
    const card = this.card
    card.addEventListener('focusin', this.focusIn)
    card.addEventListener('focusout', this.focusOut)
  },
  beforeDestroy() {
    const card = this.card

    card.removeEventListener('focusin', this.focusIn)
    card.removeEventListener('focusout', this.focusOut)
  },
  computed: {
    card(): HTMLDivElement {
      const cardInstance = this.$refs.card as Vue
      return cardInstance.$el as HTMLDivElement
    }
  },
  methods: {
    focusIn() {
      // console.log('focusIn')
      this.focused = true
      this.$emit('focusin')
    },
    focusOut() {
      // console.log('focusOut')

      this.card.scrollTop = 0
      this.focused = false
      this.$emit('focusout')
    }
  }
})
</script>
