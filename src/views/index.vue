<template>
  <div
    v-show="!closing"
    class="grid grid-cols-base grid-rows-base pt-8 lg:pt-12 xlg:pt-16 mx-8 lg:mx-12 xlg:mx-16 flex-grow overflow-hidden"
    @scroll="scroolTop($event.target)"
  >
    <HeaderTitle class="col-span-3" />
    <p v-if="!$fetchState || $fetchState.pending" class="font-preset-info mb-8">
      Loading...
    </p>
    <p v-else-if="$fetchState.error" class="font-preset-info mb-8">
      Something went wrong...
    </p>
    <template v-else>
      <TimerInfo
        class="col-span-3 row-start-2"
        :long="long"
        :start-date="startDate"
        :end-date="endDate"
      />
      <TimerClock
        class="col-span-1 row-start-3"
        :long="long"
        :start-date="startDate"
        :end-date="endDate"
        @finished="finish"
      />

      <TimerButton
        class="col-start-3 row-start-3"
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
      v-if="$fetchState && !$fetchState.pending && !$fetchState.error"
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
import { ipcRenderer } from 'electron-better-ipc'
import { channelSetBreak, channelGetBreakCount } from '../../main/helpers/ipc'
import { isProd } from '../../main/helpers/env'
import { addSeconds } from 'date-fns'
import { getUserSettingsStore } from '../../main/helpers/db'
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
  async fetch() {
    await this.setup()
  },
  asyncData({ req }) {
    return {
      name: process.static ? 'static' : process.server ? 'server' : 'client'
    }
  },
  data() {
    return {
      startDate: new Date(),
      endDate: new Date(),
      long: false,
      finished: false,
      autoFinishLock: false,
      closing: false
    }
  },
  fetchOnServer: false,
  async mounted() {
    if (process.env.NODE_ENV === 'test') await this.setup()
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
    },
    scroolTop(target) {
      // console.log('scroll', target)
      target.scroll({
        top: 0,
        left: 0,
        behavior: 'auto'
      })
    },
    async getBreakIndex() {
      return await ipcRenderer.callMain(channelGetBreakCount)
    },
    async checkIsLongBreak() {
      const breakIndex = await this.getBreakIndex()
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
    async getBreakTime(isLong) {
      const breaks = getUserSettingsStore().get('breaks')
      if (isLong) return breaks.long.last
      return breaks.short.last
    },
    setAutoFinishLock(to) {
      this.autoFinishLock = to
    },
    setNextBreak(forceNextBreakIn = undefined) {
      ipcRenderer.callMain(channelSetBreak, { forceNextBreakIn })
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
    close(forceNextBreakIn = undefined) {
      this.closing = true
      this.setNextBreak(forceNextBreakIn)
      this.closeWindow()
    }
  }
})
</script>
