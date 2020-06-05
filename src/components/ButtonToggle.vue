<template>
  <div
    @click="toggle"
    class="relative rounded-full shadow-inner-2-top-2 bg-secondary-1050 items-center flex justify-evenly h-11 w-18 cursor-pointer"
  >
    <div
      class="h-full opacity-75 transform scale-75 flex justify-center items-center"
    >
      <slot name="iconOn" />
    </div>
    <div
      class="h-full opacity-75 transform scale-75 flex justify-center items-center"
    >
      <slot name="iconOff" />
    </div>
    <BaseButton
      class="bottom-0 left-0 w-10 h-10 transform transition-transform duration-100 ease-in"
      :class="on ? [] : ['translate-x-8']"
      center
      absolute
    >
      <template v-if="on">
        <slot name="iconOn" />
      </template>
      <template v-else>
        <slot name="iconOff" />
      </template>
    </BaseButton>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import BaseButton from './BaseButton.vue'

export default Vue.extend({
  components: {
    BaseButton,
  },
  props: {
    on: {
      type: Boolean,
      required: true,
    },
  },
  methods: {
    toggle() {
      this.$emit('toggle', !this.on)
    },
  },
})
</script>
