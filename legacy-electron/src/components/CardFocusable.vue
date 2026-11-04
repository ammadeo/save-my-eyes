<template>
  <BaseCard
    ref="card"
    class="focus:outline-none"
    :absolute="absolute"
    @mouseleave.native="focusOut()"
    @mouseover.native="focusIn()"
  >
    <slot />
  </BaseCard>
</template>

<script lang="ts">
import BaseCard from './BaseCard.vue'
import Vue from 'vue'

export default Vue.extend({
  components: {
    BaseCard,
  },
  props: {
    absolute: {
      type: Boolean,
      default: false,
    },
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
    },
  },
  methods: {
    focusIn() {
      this.$emit('focusin')
    },
    focusOut() {
      this.$emit('focusout')
    },
  },
})
</script>
