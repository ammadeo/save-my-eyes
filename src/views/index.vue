<template>
  <div
    v-show="!closing"
    class="font-body pointer-events-auto bg-secondary-1000 h-screen grid grid-cols-base grid-rows-base p-8 lg:p-12 xl:p-16 flex-grow overflow-hidden"
    @scroll="scroolTop($event.target)"
  >
    <HeaderTitle class="col-start-1 col-end-3 row-start-1" />
    <IndexStopProtection
      class="col-start-3 row-start-1"
      @changeAutoFinishLock="setAutoFinishLock($event)"
    />
    <p v-if="!ready" class="font-preset-info mb-8">
      Loading...
    </p>
    <template v-else>
      <TimerInfo
        class="col-start-1 row-start-2"
        :long="long"
        :start-date="startDate"
        :end-date="endDate"
        :finished="finished"
      />
      <TimerClock
        v-show="!finished"
        class="col-start-1 row-start-3"
        :long="long"
        :start-date="startDate"
        :end-date="endDate"
        @finished="finish"
      />

      <IndexTimerButton
        class="row-start-3"
        :class="[
          ...(finished ? ['col-start-1', 'col-end-4'] : ['col-start-3']),
        ]"
        :long="long"
        :finished="finished"
        @click="finishForce()"
      />
    </template>
    <IndexIdea
      class="col-start-1 row-start-4"
      @changeAutoFinishLock="setAutoFinishLock($event)"
    />
    <IndexSettings
      class="row-start-4 col-start-3"
      @changeAutoFinishLock="setAutoFinishLock($event)"
    />
  </div>
</template>

<script lang="ts">
import TimerInfo from '../components/TimerInfo.vue'
import BaseCard from '../components/BaseCard.vue'
import CardFocusable from '../components/CardFocusable.vue'
import IndexTimerButton from '../components/IndexTimerButton.vue'
import IndexStopProtection from '../components/IndexStopProtection.vue'
import ButtonRoundable from '../components/ButtonRoundable.vue'
import ButtonIcon from '../components/ButtonIcon.vue'
import TimerClock from '../components/TimerClock.vue'
import IndexIdea from '../components/IndexIdea.vue'
import IndexSettings from '../components/IndexSettings.vue'
import HeaderTitle from '../components/HeaderTitle.vue'
import { remote } from 'electron'
import { rendererSetNextBreak as setNextBreak } from '@/background/ipc'
import { addSeconds } from 'date-fns'
import { CheckIsLongBreak, GetBreakTime } from '@/utils/mixins/breaks'
import { play } from '../utils/sound'
import mixins from 'vue-typed-mixins'
export default mixins(CheckIsLongBreak, GetBreakTime).extend({
  components: {
    TimerInfo,
    BaseCard,
    ButtonIcon,
    CardFocusable,
    IndexTimerButton,
    IndexSettings,
    IndexStopProtection,
    ButtonRoundable,
    TimerClock,
    IndexIdea,
    HeaderTitle,
  },
  data() {
    return {
      // ? break
      startDate: new Date(),
      endDate: new Date(),
      long: false,
      // ? starting
      ready: false,
      // ? closing
      finished: false,
      autoFinishLock: false,
      closing: false,
    }
  },
  async beforeMount() {
    await this.setup()
  },
  async mounted() {
    await play.sound.short()
  },
  methods: {
    async setup() {
      console.log('before mount page', '$isServer', this.$isServer)
      // if (this.$isServer) return
      const startDate = new Date()
      this.startDate = startDate
      const isLong = await this.checkIsLongBreak()
      this.long = isLong
      const breakTime = await this.getBreakTime(isLong)
      console.log('breakTime', breakTime)
      this.endDate = addSeconds(startDate, breakTime)
      this.ready = true
    },
    scroolTop(target: HTMLElement) {
      // console.log('scroll', target)
      target.scroll({
        top: 0,
        left: 0,
        behavior: 'auto',
      })
    },
    setAutoFinishLock(to: boolean) {
      this.autoFinishLock = to
    },
    closeWindow() {
      const window = remote.getCurrentWindow()
      window.close()
    },
    hideWindow() {
      const window = remote.getCurrentWindow()
      window.hide()
    },
    async finish() {
      this.finished = true
      const preventFinish = this.autoFinishLock || this.long
      if (!preventFinish) {
        this.hideWindow()
      }

      await play.sound.short()

      if (!preventFinish) {
        this.close()
      }
    },
    async finishForce() {
      const nextBreakIn = this.long || this.finished ? undefined : 5 * 60
      this.close(nextBreakIn)
    },
    close(forceNextBreakIn?: number) {
      this.closing = true
      setNextBreak.ask({ forceNextBreakIn })
      this.closeWindow()
    },
  },
})
</script>
