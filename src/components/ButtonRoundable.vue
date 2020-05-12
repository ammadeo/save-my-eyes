<template>
  <BaseButton
    :primary="primary"
    :center="round"
    class="flex-0 align-baseline"
    :class="[...(round ? ['w-8', 'h-8'] : ['min-h-8'])]"
    @click="$emit('click')"
    ><p v-show="!round" class="my-1 ml-4 mr-2 font-display text-lg">
      {{ content }}
    </p>
    <BaseIcon :icon="icon" class="h-3 m-1" :class="[...(round ? [] : ['pr-4'])]"
  /></BaseButton>
</template>

<script lang="ts">
import BaseButton from './BaseButton.vue'
import BaseIcon from './BaseIcon.vue'

import Vue from 'vue'
export default Vue.extend({
  components: {
    BaseButton,
    BaseIcon,
  },
  props: {
    content: {
      type: String,
      required: false,
    },
    icon: {
      type: String,
      default: 'close',
    },
    primary: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    round() {
      return !this.content
    },
  },
})
</script>
