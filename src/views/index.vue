<template>
  <div
    v-show="!closing"
    class="font-body pointer-events-auto bg-secondary-1000 h-screen grid grid-cols-base grid-rows-base p-8 lg:p-12 xlg:p-16 flex-grow overflow-hidden"
    @scroll="scroolTop($event.target)"
  >
    <HeaderTitle class="col-start-1 col-end-3 row-start-1" />

    <div class="col-start-3 row-start-1 flex justify-end items-center">
      <p
        class="font-display selection-darker text-sm tracking-wide mr-2 uppercase text-secondary-400"
      >
        Stop protection
      </p>
      <ButtonRoundable
        icon="pause"
        @click="showStopProtection = !showStopProtection"
      ></ButtonRoundable>
    </div>
    <BaseCard
      v-show="showStopProtection"
      class="col-start-1 col-end-4 row-start-1 row-end-4 right-0 top-0 z-10 m-4"
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
    <HelpInfo class="col-start-1 row-start-4 mb-2" />
    <IndexIdeaCard
      class="col-start-1 row-start-5"
      @changeAutoFinishLock="setAutoFinishLock($event)"
    />
    <ButtonIcon
      class="col-start-3 row-start-5 self-end"
      icon="settings"
      content="Show settings"
      @click="showSettings = true"
    >
    </ButtonIcon>
    <BaseCard
      v-if="ready && showSettings"
      color="secondary-300"
      class="absolute bottom-0 right-0 col-start-3 row-start-5"
      @focusout="showSettings = false"
    >
      <ContentSettings />
    </BaseCard>
  </div>
</template>

<script lang="ts">
import TimerInfo from '../components/TimerInfo.vue'
import BaseCard from '../components/BaseCard.vue'
import ContentStopProtection from '../components/ContentStopProtection.vue'
import CardAbsolute from '../components/CardAbsolute.vue'
import IndexTimerButton from '../components/IndexTimerButton.vue'
import ButtonRoundable from '../components/ButtonRoundable.vue'
import ButtonIcon from '../components/ButtonIcon.vue'
import TimerClock from '../components/TimerClock.vue'
import HelpInfo from '../components/HelpInfo.vue'
import IndexIdeaCard from '../components/IndexIdeaCard.vue'
import ContentSettings from '../components/ContentSettings.vue'
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
    CardAbsolute,
    IndexTimerButton,
    ButtonRoundable,
    TimerClock,
    HelpInfo,
    ContentStopProtection,
    IndexIdeaCard,
    ContentSettings,
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
      showSettings: false,
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
        this.autoFinishLock ||
        this.long ||
        this.showStopProtection ||
        this.showSettings
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
