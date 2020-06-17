import vue from 'vue'
import { rendererGetBreakData } from '@/background/ipc'

import { getUserSettingsStore } from '@/background/db'
import { differenceInMinutes } from 'date-fns'
import { formatDistanceStrict } from '@/utils/dateFnsI18n'

export const CheckIsLongBreak = vue.extend({
  methods: {
    async checkIsLongBreak() {
      const { breakIndex } = await rendererGetBreakData.ask({})
      const longBreakEvery = getUserSettingsStore().get('breaks').long.every
      const isLong = breakIndex % longBreakEvery === 0
      // console.log(
      //   'breakIndex',
      //   breakIndex,
      //   'longBreakEvery',
      //   longBreakEvery,
      //   'breakIndex % longBreakEvery',
      //   breakIndex % longBreakEvery
      // )
      return isLong
    },
  },
})

export const GetBreakTime = vue.extend({
  methods: {
    async getBreakTime(isLong: boolean) {
      const breaks = getUserSettingsStore().get('breaks')
      if (isLong) return breaks.long.last
      return breaks.short.last
    },
  },
})

export const TimeAgoContent = vue.extend({
  methods: {
    timeAgoContent(endDate: Date): string {
      const nowDate = new Date()
      if (differenceInMinutes(nowDate, endDate) >= 1) {
        const formattedDistance = formatDistanceStrict(endDate, new Date(), {
          roundingMethod: 'floor',
          addSuffix: true,
        })
        return `${formattedDistance}`
      }
      return ''
    },
  },
})
