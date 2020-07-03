<template>
  <div
    class="flex items-center w-full min-w-full relative self-start transition-opacity duration-1000 ease-in"
    :class="timeLeft <= 0 ? ['opacity-25'] : []"
  >
    <p
      class="font-body flex-grow-0 flex-shrink-0 font-semibold text-secondary-100 leading-none pr-6 text-3xl"
    >
      {{ timeLeftInfo }}
    </p>
    <div class="h-12 w-full">
      <ProgressbarIcon
        color="primary-400"
        :min="0"
        :max="100"
        :value="timePercentage"
        :icon="icon"
      />
    </div>
  </div>
</template>

<script lang="ts">
import { addMilliseconds } from 'date-fns'
import { format } from '@/utils/dateFnsI18n'
import ProgressbarIcon from './ProgressbarIcon.vue'
import { CreateTimer } from '@/utils/mixins/createTimer'
import mixins from 'vue-typed-mixins'

export default mixins(CreateTimer).extend({
  components: {
    ProgressbarIcon,
  },
  props: {
    startDate: {
      required: true,
      type: Date,
    },
    endDate: {
      required: true,
      type: Date,
    },
    autoFinish: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    allTime(): number {
      const endDate = (this.endDate as unknown) as Date
      const startDate = (this.startDate as unknown) as Date
      return endDate.getTime() - startDate.getTime()
    },
    timeLeft(): number {
      return this.allTime - this.timePassedObj.timePassed
    },
    timeLeftInfo(): string {
      const timeLeft = this.timeLeft
      const helperDate = addMilliseconds(new Date(0), timeLeft)
      return format(helperDate, 'mm : ss')
    },
    timePercentage(): number {
      return (this.timePassedObj.timePassed / this.allTime) * 100
    },
    icon(): string {
      return this.autoFinish ? 'finish' : ''
    },
  },
  mounted() {
    const allTime = this.allTime
    this.anime = this.createTimer(allTime, () => {
      this.$emit('finished')
    })
  },
  beforeDestroy() {
    const anime = this.anime
    if (anime) anime.pause()
  },
})
</script>
