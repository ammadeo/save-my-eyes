<template>
  <ButtonIcon
    centered
    :icon="icon"
    :content="content"
    absolute
    class="bottom-0 right-0 m-8 lg:m-12 xl:m-16 transform scale-75 origin-bottom-right tracking-wider font-light"
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
    finished: {
      type: Boolean,
      required: true,
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
      finish: t('Finish this break', 'Zakończ przerwę'),
      skip: t('Skip this break', 'Pomiń przerwę'),
    }))
  },
  computed: {
    content(): string {
      if (this.finished) return this.$t('finish')
      return this.$t('skip')
    },
    icon(): string {
      return this.finished ? 'finish' : 'skip'
    },
  },
})
</script>
