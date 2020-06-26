<template>
  <ButtonIcon
    :primary="finished"
    centered
    :icon="icon"
    :content="content"
    :disabled="disabled"
    class="flex-0 self-start min-h-12"
    @click="delayClick()"
  />
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
    disabled: {
      default: false,
      type: Boolean,
    },
  },
  methods: {
    delayClick(): void {
      setTimeout(() => {
        this.$emit('click')
      }, 50)
    },
  },
  beforeMount() {
    this.$useI18n((t) => ({
      finishLong: t('Finish long break', 'Zakończ długą przerwę'),
      finishShort: t('Finish short break', 'Zakończ krótką przerwę'),
      skipLong: t('Skip long break', 'Pomiń długą przerwę'),
      skipShort: t('Skip short break', 'Pomiń krótką przerwę'),
    }))
  },
  computed: {
    content(): string {
      if (this.long)
        if (this.finished) return this.$t('finishLong')
        else return this.$t('skipLong')
      if (this.finished) return this.$t('finishShort')
      return this.$t('skipShort')
    },
    icon(): string {
      return this.finished ? 'close' : 'skip'
    },
  },
})
</script>
