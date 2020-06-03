<template>
  <p class="font-preset-info mb-8 first-letter:capitalize">
    {{ breakInfo }}
  </p>
</template>

<script lang="ts">
import { formatDistanceStrict, differenceInMinutes } from 'date-fns'
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
  },
  beforeDestroy() {
    const timeAfterInterval = this.timeAfterInterval
    if (timeAfterInterval) clearInterval(timeAfterInterval)
  },
  computed: {
    breakTime(): string {
      return formatDistanceStrict(this.startDate, this.endDate, {
        roundingMethod: 'floor',
      })
    },
    breakType(): string {
      const type = this.long ? 'long' : 'short'
      return `${type} break`
    },

    breakInfo(): string {
      if (this.finished) {
        return `${this.breakType} has ended ${this.timeAfterBreakInfo}`
      }

      return `take a ${this.breakType} for ${this.breakTime}`
    },
  },
})
</script>
