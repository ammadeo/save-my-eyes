<template>
  <ButtonIcon
    :primary="finished"
    centered
    :icon="icon"
    :content="content"
    class="flex-0 self-start min-h-12"
    @click="delayClick()"
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
  methods: {
    delayClick() {
      setTimeout(() => {
        this.$emit('click')
      }, 50)
    },
  },
  computed: {
    content() {
      if (this.long)
        if (this.finished) return 'Finish long break'
        else return 'Skip long break'
      if (this.finished) return 'Finish short break'
      return 'Skip short break'
    },
    icon() {
      // todo set proper icon
      return this.finished ? 'close' : 'skip'
    },
  },
})
</script>
