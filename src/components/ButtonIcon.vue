<template>
  <BaseButton
    :primary="primary"
    :absolute="absolute"
    :disabled="disabled"
    class="flex-0 flex  min-h-12"
    @click="$emit('click')"
  >
    <p class="py-2 px-4 font-display text-lg">
      {{ content }}
    </p>
    <BaseIcon :icon="icon" class="h-4 pr-4" />
  </BaseButton>
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
    disabled: {
      default: false,
      type: Boolean,
    },
    content: {
      type: String,
      required: true,
    },
    icon: {
      type: String,
      required: true,
    },
    primary: {
      type: Boolean,
      default: false,
    },
    absolute: {
      default: false,
      type: Boolean,
    },
  },
})
</script>
