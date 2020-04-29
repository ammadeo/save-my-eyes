<template>
  <div
    v-show="!closing"
    class="grid grid-cols-base grid-rows-base pt-8 lg:pt-12 xlg:pt-16 mx-8 lg:mx-12 xlg:mx-16 flex-grow overflow-hidden"
    @scroll="scroolTop($event.target)"
  >
    <HeaderTitle class="col-span-3" />
    <p v-if="!ready" class="font-preset-info mb-8">
      Loading...
    </p>
    <template v-else>
      <TimerInfo
        class="col-span-3 row-start-2"
        :long="long"
        :start-date="startDate"
        :end-date="endDate"
        :finished="finished"
      />
      <TimerClock
        v-show="!finished"
        class="col-span-1 row-start-3"
        :long="long"
        :start-date="startDate"
        :end-date="endDate"
        @finished="finish"
      />

      <TimerButton
        class="row-start-3"
        :class="[
          ...(finished ? ['col-start-1', 'col-end-4'] : ['col-start-3'])
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
    <SettingsCard
      v-if="ready"
      class="col-start-3 row-start-5"
      @changeAutoFinishLock="setAutoFinishLock($event)"
    />
  </div>
</template>

<script lang="ts">
import TimerInfo from '../components/TimerInfo.vue'
import TimerButton from '../components/TimerButton.vue'
import TimerClock from '../components/TimerClock.vue'
import HelpInfo from '../components/HelpInfo.vue'
import HelpCards from '../components/HelpCards.vue'
import SettingsCard from '../components/SettingsCard.vue'
import HeaderTitle from '../components/HeaderTitle.vue'
import { remote } from 'electron'
import {
  rendererGetBreakIndex as getBreakIndex,
  rendererSetNextBreak as setNextBreak
} from '@/background/ipc'
import { isProd } from '@/background/env'
import { addSeconds } from 'date-fns'
import { getUserSettingsStore } from '@/background/db'
import { play } from '../utils/sound'

import Vue from 'vue'
export default Vue.extend({
  components: {
    TimerInfo,
    TimerButton,
    TimerClock,
    HelpInfo,
    HelpCards,
    SettingsCard,
    HeaderTitle
  },
  data() {
    return {
      startDate: new Date(),
      endDate: new Date(),
      long: false,
      finished: false,
      autoFinishLock: false,
      closing: false,
      ready: false
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
      const breakTime = await this.getBreakTime(await this.checkIsLongBreak())
      console.log('breakTime', breakTime)
      this.endDate = addSeconds(startDate, breakTime)
      this.ready = true
    },
    scroolTop(target: HTMLElement) {
      // console.log('scroll', target)
      target.scroll({
        top: 0,
        left: 0,
        behavior: 'auto'
      })
    },
    async checkIsLongBreak() {
      const breakIndex = await getBreakIndex()
      const longBreakEvery = getUserSettingsStore().get('breaks').long.every
      const isLong = breakIndex % longBreakEvery === 0
      console.log(
        'breakIndex',
        breakIndex,
        'longBreakEvery',
        longBreakEvery,
        'breakIndex % longBreakEvery',
        breakIndex % longBreakEvery
      )
      this.long = isLong
      return isLong
    },
    async getBreakTime(isLong: boolean) {
      const breaks = getUserSettingsStore().get('breaks')
      if (isLong) return breaks.long.last
      return breaks.short.last
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
      setNextBreak(forceNextBreakIn)
      this.closeWindow()
    }
  }
})
</script>
