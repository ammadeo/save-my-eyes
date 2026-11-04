<template>
  <div class="flex-grow">
    <p class="mb-4 text-lg uppercase text-secondary-200">
      {{
        (isBreakNow ? '' : $t('breakNext') + ' ') +
          nextBreakName +
          ' ' +
          (isBreakNow ? $t('breakIsNow') : $t('breakIn'))
      }}
      <span v-if="!isBreakNow" class="text-secondary-100">{{
        nextBreakTime
      }}</span>
    </p>
    <ButtonIcon
      primary
      class="mb-8 w-full"
      @click="emitRun('start-long-break')"
      :content="$t('buttonStartLongBreak')"
      icon="start"
    ></ButtonIcon>
    <ButtonIcon
      class="mb-4 w-full"
      @click="emitRun('open-stop-protection')"
      :content="$t('buttonStopProtection')"
      icon="pause"
    ></ButtonIcon>
    <ButtonIcon
      class="mb-4 w-full"
      @click="emitRun('open-settings')"
      :content="$t('buttonSettings')"
      icon="settings"
    ></ButtonIcon>
  </div>
</template>

<script lang="ts">
import ButtonIcon from './ButtonIcon.vue'
import { RunKey } from '@/types/menu'
import { addSeconds, parseISO } from 'date-fns'
import { formatDistanceStrict } from '@/utils/dateFnsI18n'
import { CheckIsLongBreak } from '@/utils/mixins/breaks'
import { rendererGetBreakData } from '@/background/ipc'

import mixins from 'vue-typed-mixins'

interface Data {
  nextBreakName: string
  nextBreakTime: string
  nextBreakDate?: Date
  isBreakNow: boolean
}

export default mixins(CheckIsLongBreak).extend({
  components: {
    ButtonIcon,
  },
  data(): Data {
    return {
      nextBreakName: '',
      nextBreakTime: '',
      nextBreakDate: undefined,
      isBreakNow: false,
    }
  },
  async mounted() {
    const isLong = await this.checkIsLongBreak()
    this.nextBreakName = this.breakName(isLong)
    this.runClock()
  },
  beforeMount() {
    this.$useI18n((t) => ({
      breakNext: t('Next', 'Następna'),
      breakIn: t('in', 'za'),
      breakIsNow: t('is still going', 'trwa'),
      buttonStartLongBreak: t(
        'Start a long break now',
        'Zacznij długą przewę teraz'
      ),
      buttonStopProtection: t('Stop protection', 'Wstrzymaj ochronę'),
      buttonSettings: t('Settings', 'Ustawienia'),
    }))
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
    async getNextBreakDate(): Promise<Date> {
      const {
        lastSchedulerJobDate,
        lastSchedulerJobLength,
      } = await rendererGetBreakData.ask({})
      console.log('resived ipc ')
      return addSeconds(parseISO(lastSchedulerJobDate), lastSchedulerJobLength)
    },
    async nextBreakIn(): Promise<string> {
      let nextBreakDate = this.nextBreakDate
      if (!this.nextBreakDate) {
        nextBreakDate = await this.getNextBreakDate()
        this.nextBreakDate = nextBreakDate
      }
      if (nextBreakDate) {
        if (nextBreakDate.getTime() < new Date().getTime()) {
          this.isBreakNow = true
        }
        console.log('new Date()', new Date(), 'nextBreakDate', nextBreakDate)
        return formatDistanceStrict(new Date(), nextBreakDate, {
          roundingMethod: 'floor',
        })
      }
      return ''
    },
    breakName(isLong: boolean): string {
      return isLong ? this.$tGlobal('breakLong') : this.$tGlobal('breakShort')
    },
  },
})
</script>
