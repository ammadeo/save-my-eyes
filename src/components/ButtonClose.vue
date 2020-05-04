<template>
  <BaseButton
    primary
    class="flex-0 self-start align-baseline"
    :class="[
      ...(round
        ? ['w-8', 'h-8', 'justify-center']
        : ['justify-around', 'min-h-8']),
    ]"
    @click="$emit('click')"
    ><p v-show="!round" class="py-2 px-4 font-display text-lg">{{ content }}</p>
    <p class="text-lg">X</p></BaseButton
  >
</template>

<script lang="ts">
import BaseButton from './BaseButton.vue'

import Vue from 'vue'
export default Vue.extend({
  components: {
    BaseButton,
  },
  props: {
    content: {
      type: String,
      required: false,
    },
  },
  computed: {
    round() {
      return !this.content
    },
  },
})
</script>
