<template>
  <div class="flex-grow">
    <p class="mb-4 text-lg uppercase text-secondary-200">
      next {{ nextBreakName }} in
      <span class="text-secondary-100">{{ nextBreakTime }}</span>
    </p>
    <ButtonIcon
      primary
      class="mb-8 w-full"
      @click="emitRun('start-long-break')"
      content="Start a long break now"
    ></ButtonIcon>
    <ButtonIcon
      class="mb-4 w-full"
      @click="emitRun('open-stop-protection')"
      content="Stop protection"
    ></ButtonIcon>
    <ButtonIcon
      class="mb-4 w-full"
      @click="emitRun('open-settings')"
      content="Settings"
    ></ButtonIcon>
  </div>
</template>

<script lang="ts">
import ButtonIcon from './ButtonIcon.vue'
import { RunKey } from '@/types/menu'
import { formatDistanceStrict, addSeconds } from 'date-fns'
import { CheckIsLongBreak, GetBreakTime } from '@/utils/mixins/breaks'
import { rendererGetBreakerData } from '@/background/ipc'

import mixins from 'vue-typed-mixins'
export default mixins(CheckIsLongBreak, GetBreakTime).extend({
  components: {
    ButtonIcon,
  },
  data() {
    return {
      nextBreakName: '',
      nextBreakTime: '',
    }
  },
  async mounted() {
    const isLong = await this.checkIsLongBreak()
    this.nextBreakName = this.breakName(isLong)
    this.runClock()
  },
  methods: {
    emitRun(key: RunKey) {
      this.$emit('run', key)
    },
    async runClock() {
      console.log('run clock')
      try {
        this.nextBreakTime = await this.nextBreakIn()
        console.log('clock set', 'this.nextBreakTime', this.nextBreakTime)
      } catch (error) {
        console.error(error)
      } finally {
        setTimeout(this.runClock, 1000)
      }
    },
    async nextBreakDate(): Promise<Date> {
      const {
        lastSchedulerJobDate,
        lastSchedulerJobLength,
      } = await rendererGetBreakerData()
      console.log('resived ipc ')
      return addSeconds(lastSchedulerJobDate, lastSchedulerJobLength)
    },
    async nextBreakIn(): Promise<string> {
      const nextBreakDate = await this.nextBreakDate()
      console.log('new Date()', new Date(), 'nextBreakDate', nextBreakDate)
      return formatDistanceStrict(new Date(), nextBreakDate, {
        roundingMethod: 'floor',
      })
    },
    breakName(isLong: boolean): string {
      const name = isLong ? 'long' : 'short'
      return `${name} break`
    },
  },
})
</script>
