<template>
  <ButtonIcon
    :primary="finished"
    centered
    :icon="icon"
    :content="content"
    class="flex-0 self-start min-h-12"
    @click="$emit('click')"
  />
  <!-- <p
      class="py-2 px-4 font-display"
      :class="[...(finished ? ['text-lg'] : [])]"
    >
      {{  }}
    </p></ButtonIcon
  > -->
</template>

<script lang="ts">
import ButtonIcon from './ButtonIcon.vue'

import Vue from 'vue'
export default Vue.extend({
  components: {
    ButtonIcon,
  },
  props: {
    long: {
      type: Boolean,
      default: false,
    },
    finished: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    content() {
      if (this.long)
        if (this.finished) return 'Finish a long break'
        else return 'Skip a long break'
      if (this.finished) return 'Finish a short break'
      return 'Skip for 5 minutes'
    },
    icon() {
      // todo set proper icon
      return this.finished ? 'close' : 'skip'
    },
  },
})
</script>
