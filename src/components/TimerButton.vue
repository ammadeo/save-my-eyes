<template>
  <BaseButton
    :primary="finished"
    class="flex-0 self-start min-h-12"
    @click="$emit('click')"
    ><p class="py-2 px-4 font-display">{{ content }}</p></BaseButton
  >
</template>

<script>
import BaseButton from './BaseButton.vue'

export default {
  components: {
    BaseButton,
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
  },
}
</script>
