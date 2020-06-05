<template>
  <div class="flex items-center">
    <ButtonToggle
      :on="on"
      @toggle="$emit('toggle', $event)"
      class="flex-shrink-0"
    >
      <template #iconOn>
        <slot name="iconOn" />
      </template>
      <template #iconOff>
        <slot name="iconOff" />
      </template>
    </ButtonToggle>
    <p class="ml-2 text-secondary-200 font-display">{{ stateContent }}</p>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
// import mixins from 'vue-typed-mixins'

import ButtonToggle from './ButtonToggle.vue'

export default Vue.extend({
  components: {
    ButtonToggle,
  },
  props: {
    on: {
      type: Boolean,
      required: true,
    },
    stateOn: {
      type: String,
      required: true,
    },
    stateOff: {
      type: String,
      required: true,
    },
  },
  computed: {
    stateContent() {
      return this.on ? this.stateOn : this.stateOff
    },
  },
})
</script>
