<template>
  <p class="font-preset-info mb-8">
    {{ breakInfo }}
  </p>
</template>

<script lang="ts">
import { formatDistanceStrict } from 'date-fns'

import Vue from 'vue'
export default Vue.extend({
  props: {
    startDate: {
      required: true,
      type: Date as new () => Date
    },
    endDate: {
      required: true,
      type: Date as new () => Date
    },
    long: {
      type: Boolean,
      default: false
    }
  },
  computed: {
    breakTime(): string {
      return formatDistanceStrict(this.startDate, this.endDate, {
        roundingMethod: 'floor'
      })
    },
    breakType(): string {
      const type = this.long ? 'long' : 'short'
      return `${type} break`
    },
    breakInfo(): string {
      return `Take a ${this.breakType} for ${this.breakTime}`
    }
  }
})
</script>
