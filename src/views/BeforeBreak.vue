<template>
  <div
    class="flex flex-col items-end justify-end p-16 overflow-hidden min-h-screen"
  >
    <div>
      <transition name="slide" appear>
        <BaseCard class="pointer-events-auto" v-show="showBreakCard">
          <ContentBeforeBreak @break="startBreak()" @skip="skipBreak()" />
        </BaseCard>
      </transition>
    </div>
  </div>
</template>

<script lang="ts">
import ContentBeforeBreak from '../components/ContentBeforeBreak.vue'
import BaseCard from '../components/BaseCard.vue'

import { remote } from 'electron'
import { rendererSetNextBreak as setNextBreak } from '@/background/ipc'

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
    startBreak() {
      // todo use this real handler for blank window creation
      this.showBreakCard = false
      setTimeout(() => {
        this.$router.push({ name: 'Index' })
      }, 300)
    },
    async skipBreak() {
      await setNextBreak.ask({ forceNextBreakIn: 5 * 60 })
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
