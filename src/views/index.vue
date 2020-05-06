<template>
  <div
    v-show="!closing"
    class="font-body pointer-events-auto bg-secondary-600 h-screen grid grid-cols-base grid-rows-base pt-8 lg:pt-12 xlg:pt-16  px-8 lg: px-12 xlg: px-16 flex-grow overflow-hidden"
    @scroll="scroolTop($event.target)"
  >
    <HeaderTitle class="col-start-1 col-end-3 row-start-1" />

    <div class="col-start-3 row-start-1 flex justify-end items-baseline">
      <p class="font-display tracking-wide mr-2 text-secondary-300">
        Stop protection
      </p>
      <ButtonClose
        @click="showStopProtection = !showStopProtection"
      ></ButtonClose>
    </div>
    <BaseCard
      v-show="showStopProtection"
      color="secondary-500"
      class="col-start-1 col-end-4 row-start-1 row-end-4 right-0 top-0 z-10 p-4"
      @mouseleave.native="showStopProtection = false"
    >
      <ContentStopProtection @close="closeWindow()" />
    </BaseCard>
    <div></div>
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

      <ButtonTimer
        class="row-start-3"
        :class="[
          ...(finished ? ['col-start-1', 'col-end-4'] : ['col-start-3']),
        ]"
        :long="long"
        :finished="finished"
        @click="finishForce()"
      />
    </template>
    <HelpInfo class="col-start-1 row-start-4 mb-2" />
    <HelpCards
      class="col-start-1 row-start-5"
      @changeAutoFinishLock="setAutoFinishLock($event)"
    />
    <CardAbsolute
      v-if="ready"
      color="secondary-300"
      class="col-start-3 row-start-5"
      @focusin="setAutoFinishLock(true)"
      @focusout="setAutoFinishLock(false)"
    >
      <TheSettings />
    </CardAbsolute>
  </div>
</template>

<script lang="ts">
import TimerInfo from '../components/TimerInfo.vue'
import BaseCard from '../components/BaseCard.vue'
import ContentStopProtection from '../components/ContentStopProtection.vue'
import CardAbsolute from '../components/CardAbsolute.vue'
import ButtonTimer from '../components/ButtonTimer.vue'
import ButtonClose from '../components/ButtonClose.vue'
import TimerClock from '../components/TimerClock.vue'
import HelpInfo from '../components/HelpInfo.vue'
import HelpCards from '../components/HelpCards.vue'
import TheSettings from '../components/TheSettings.vue'
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
    CardAbsolute,
    ButtonTimer,
    ButtonClose,
    TimerClock,
    HelpInfo,
    ContentStopProtection,
    HelpCards,
    TheSettings,
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
      // ? state
      showStopProtection: false,
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
      const preventFinish =
        this.autoFinishLock || this.long || this.showStopProtection
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
