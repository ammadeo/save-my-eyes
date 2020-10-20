<template>
  <div
    class="flex flex-col items-end justify-end p-8 lg:p-12 xl:p-16 overflow-hidden min-h-screen"
  >
    <div class="min-w-80">
      <transition name="slide" appear @after-leave="startBreak()">
        <BaseCard
          ref="BreakCard"
          class="pointer-events-auto perspective-64"
          v-show="showBreakCard"
        >
          <ContentBeforeBreak
            @break.once="beforeStartBreak()"
            @skip.once="skipBreak()"
            @wait.once="animateWaiting()"
          />
        </BaseCard>
      </transition>
    </div>
  </div>
</template>

<script lang="ts">
import ContentBeforeBreak from '../components/ContentBeforeBreak.vue'
import BaseCard from '../components/BaseCard.vue'
import anime from 'animejs'

import { remote } from 'electron'
import {
  rendererSetNextBreak as setNextBreak,
  rendererStartBreak as StartBreak,
} from '@/background/ipc'

import { TransparentClickEngine } from '@/utils/mixins/transparentClickEngine'
import mixins from 'vue-typed-mixins'

export default mixins(TransparentClickEngine).extend({
  components: {
    BaseCard,
    ContentBeforeBreak,
  },
  data() {
    return {
      showBreakCard: true,
    }
  },
  methods: {
    beforeStartBreak() {
      this.showBreakCard = false
    },
    startBreak() {
      try {
        StartBreak.ask({})
        this.$router.push({ name: 'Index' })
      } catch (error) {
        console.error(error)
      }
    },
    async skipBreak() {
      try {
        await setNextBreak.ask({})
        const window = remote.getCurrentWindow()
        window.close()
      } catch (error) {
        console.error(error)
      }
    },
    animateWaiting() {
      const BreakCard = (this.$refs.BreakCard as Vue).$el
      anime({
        targets: BreakCard,
        scale: [1, 1.05],
        loop: true,
        delay: 60000,
        duration: 500,
        autoplay: true,
        direction: 'alternate',
        easing: 'easeInCirc',
      })
    },
  },
})
</script>

<style lang="postcss">
body {
  @apply pointer-events-none;
}
</style>
