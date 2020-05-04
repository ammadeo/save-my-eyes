<template>
  <BaseButton
    :primary="primary"
    class="flex-0 self-start min-h-12"
    @click="$emit('click')"
  >
    <div>
      <p class="py-2 px-4 font-display text-lg">
        {{ content }}
      </p>
      <div>
        <slot name="icon" />
      </div>
    </div>
  </BaseButton>
</template>

<script lang="ts">
import BaseButton from './BaseButton.vue'

import Vue from 'vue'
export default Vue.extend({
  components: {
    BaseButton
  },
  props: {
    content: {
      type: String,
      required: true
    },
    primary: {
      type: Boolean,
      default: false
    }
  }
})
</script>
