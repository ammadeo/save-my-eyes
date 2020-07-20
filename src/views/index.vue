<template>
  <div
    v-show="!closing"
    class="font-body pointer-events-auto bg-secondary-1000 h-screen grid grid-cols-base grid-rows-base p-8 lg:p-12 xl:p-16 flex-grow overflow-hidden"
    @scroll="scroolTop($event.target)"
  >
    <HeaderTitle class="col-start-1 col-end-3 row-start-1" />
    <IndexStopProtection
      class="col-start-3 row-start-1"
      :disabled="forceCloseLock"
      @changeAutoFinishLock="setLocks($event)"
      @close="closeWindow()"
    />
    <p v-if="!ready" class="font-preset-info mb-8">
      {{ $t('loading') }}
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
        class="col-start-1 row-start-3"
        :auto-finish="!long && !autoFinishLock"
        :start-date="startDate"
        :end-date="endDate"
        @finished="finish"
      />

      <IndexTimerButton
        class="row-start-3 col-start-3"
        :long="long"
        :finished="finished"
        :disabled="forceCloseLock"
        @click="finishForce()"
      />
    </template>
    <IndexIdea
      class="col-start-1 row-start-4"
      :long="long"
      @changeAutoFinishLock="setAutoFinishLock($event)"
    />
    <IndexSettings
      class="row-start-4 col-start-3"
      @changeAutoFinishLock="setLocks($event)"
      @changed="setLocks(true, true)"
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
import {
  rendererSetNextBreak as setNextBreak,
  rendererEmitEndBreak as emitEndBreak,
} from '@/background/ipc'
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
      forceCloseLock: false,
      closing: false,
    }
  },
  beforeMount() {
    this.$useI18n((t) => ({
      loading: t(
        "We're loading a timer. You can start Your break now",
        'Nakręcamy zegar. Możesz już zacząć przerwę'
      ),
    }))
  },
  async mounted() {
    await this.setup()
    await this.playBreakSound()
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
    async playBreakSound() {
      if (this.long) {
        await play.sound.long()
      } else {
        await play.sound.short()
      }
    },
    setLocks(to: boolean, forceClose = false) {
      this.setAutoFinishLock(to)
      if (forceClose || !to) this.setForceCloseLock(forceClose ? to : false)
    },
    setAutoFinishLock(to: boolean) {
      this.autoFinishLock = to
    },
    setForceCloseLock(to: boolean) {
      this.forceCloseLock = to
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
      } else {
        emitEndBreak.ask({})
      }

      await this.playBreakSound()

      if (!preventFinish) {
        this.close()
      }
    },
    async finishForce() {
      this.close()
    },
    async close() {
      this.closing = true
      // await setNextBreak.ask({ forceNextBreakIn }) //? moved to main process close handler
      this.closeWindow()
    },
  },
})
</script>
