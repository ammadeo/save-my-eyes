<template>
  <div
    class="flex flex-col items-end justify-end p-16 overflow-hidden min-h-screen"
  >
    <div>
      <transition name="slide" appear @after-leave="startBreak()">
        <BaseCard class="pointer-events-auto" v-show="showBreakCard">
          <ContentBeforeBreak
            @break.once="beforeStartBreak()"
            @skip.once="skipBreak()"
          />
        </BaseCard>
      </transition>
    </div>
  </div>
</template>

<script lang="ts">
import ContentBeforeBreak from '../components/ContentBeforeBreak.vue'
import BaseCard from '../components/BaseCard.vue'

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
      StartBreak.ask({})
      this.$router.push({ name: 'Index' })
    },
    async skipBreak() {
      await setNextBreak.ask({})
      const window = remote.getCurrentWindow()
      window.close()
    },
  },
})
</script>

<style lang="postcss">
body {
  @apply pointer-events-none;
}
</style>
