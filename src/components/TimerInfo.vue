<template>
  <p class="font-preset-info mb-8 first-letter:capitalize">
    {{ breakInfo }}
  </p>
</template>

<script lang="ts">
import { formatDistanceStrict } from '@/utils/dateFnsI18n'
import { TimeAgoContent } from '@/utils/mixins/breaks'
import mixins from 'vue-typed-mixins'

export default mixins(TimeAgoContent).extend({
  props: {
    startDate: {
      required: true,
      type: Date as new () => Date,
    },
    endDate: {
      required: true,
      type: Date as new () => Date,
    },
    long: {
      type: Boolean,
      default: false,
    },
    finished: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      timeAfterInterval: undefined,
      timeAfterBreakInfo: '',
    } as {
      timeAfterInterval?: NodeJS.Timeout
      timeAfterBreakInfo: string
    }
  },
  watch: {
    finished: {
      handler(val) {
        if (val === true) {
          this.timeAfterInterval = setInterval(() => {
            this.timeAfterBreakInfo = this.timeAgoContent(this.endDate)
          }, 60 * 1000)
        }
      },
    },
    $langLanguage: {
      handler() {
        this.timeAfterBreakInfo = this.timeAgoContent(this.endDate)
      },
    },
  },
  beforeDestroy() {
    const timeAfterInterval = this.timeAfterInterval
    if (timeAfterInterval) clearInterval(timeAfterInterval)
  },
  beforeMount() {
    const shortBreak = 'short break'
    const shortBreakPl = 'krótka przerwa'
    const longBreak = 'long break'
    const longBreakPl = 'długa przerwa'
    const hasEnded = 'has ended'
    const hasEndedPl = 'zakończyła się'
    const take = 'take a'
    const forTime = 'for'
    const forTimePl = 'przez'

    this.$useI18n((t) => ({
      shortBreakFinished: t(
        `${shortBreak} ${hasEnded}`,
        `${shortBreakPl} ${hasEndedPl}`
      ),
      longBreakFinished: t(
        `${longBreak} ${hasEnded}`,
        `${longBreakPl} ${hasEndedPl}`
      ),
      shortBreakStarted: t(
        `${take} ${shortBreak} ${forTime}`,
        `${shortBreakPl} ${forTimePl}`
      ),
      longBreakStarted: t(
        `${take} ${longBreak} ${forTime}`,
        `${longBreakPl} ${forTimePl}`
      ),
    }))
  },
  computed: {
    breakTime(): string {
      return formatDistanceStrict(this.startDate, this.endDate, {
        roundingMethod: 'floor',
      })
    },
    breakTypeId(): string {
      return this.long ? 'longBreak' : 'shortBreak'
    },
    breakInfo(): string {
      if (this.finished) {
        return `${this.$t(this.breakTypeId + 'Finished')} ${
          this.timeAfterBreakInfo
        }`
      }

      return `${this.$t(this.breakTypeId + 'Started')} ${this.breakTime}`
    },
  },
})
</script>
