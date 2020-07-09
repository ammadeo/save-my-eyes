<template funtional>
  <div
    class="flex justify-center items-center min-h-screen opacity-50 pointer-events-auto"
  >
    <div>
      <HeaderTitle class="flex justify-center text-center" />
      <p class="font-preset-info text-center">{{ content }}</p>
    </div>
    <BlankBreakButton :finished="finished" @click="setNextBreak" />
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import HeaderTitle from '../components/HeaderTitle.vue'
import BlankBreakButton from '../components/BlankBreakButton.vue'

import { rendererEmitEndBreak, rendererSetNextBreak } from '@/background/ipc'
export default Vue.extend({
  components: { HeaderTitle, BlankBreakButton },
  beforeMount() {
    this.$useI18n((t) => {
      return {
        content: t('Wait for break to end', 'Poczekaj na koniec przerwy'),
        contentFinished: t('Break has ended', 'Przerwa zakończyła się'),
      }
    })
    rendererEmitEndBreak
      .listen()
      .then(() => {
        console.log('ipc finished break')
        this.finished = true
      })
      .catch((e) => console.error(e))
  },
  data() {
    return {
      finished: false,
    }
  },
  methods: {
    setNextBreak() {
      rendererSetNextBreak.ask({})
    },
  },
  computed: {
    content(): string {
      return this.$t(this.finished ? 'contentFinished' : 'content')
    },
  },
})
</script>
