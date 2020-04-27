<template>
  <p class="font-preset-info mb-8">
    {{ breakInfo }}
  </p>
</template>

<script>
import { formatDistanceStrict } from 'date-fns'

export default {
  props: {
    startDate: {
      required: true,
      type: Date,
    },
    endDate: {
      required: true,
      type: Date,
    },
    long: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    breakTime() {
      return formatDistanceStrict(this.startDate, this.endDate, {
        roundingMethod: 'floor',
      })
    },
    breakType() {
      const type = this.long ? 'long' : 'short'
      return `${type} break`
    },
    breakInfo() {
      return `Take a ${this.breakType} for ${this.breakTime}`
    },
  },
}
</script>
