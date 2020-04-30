<template>
  <div class="flex items-center w-full min-w-full relative self-start">
    <template v-if="timeLeft > 0">
      <p
        class="font-display flex-grow-0 flex-shrink-0 font-bold text-secondary-100 leading-none pr-6 text-3xl"
      >
        {{ timeLeftInfo }}
      </p>
      <div
        class="bg-secondary-300 flex-1 shadow-inner rounded-full overflow-hidden max-w-6xl h-12"
      >
        <BaseTile
          role="progressbar"
          :aria-valuenow="100 - timeLeftPercent"
          aria-valuemin="0"
          aria-valuemax="100"
          color="primary-400"
          class="anime-progress rounded-full shadow-sm w-full h-full"
          :style="{ transform: `translateX(-${timeLeftPercent}%)` }"
        ></BaseTile>
      </div>
    </template>
  </div>
</template>

<script lang="ts">
import anime from 'animejs'
import { format, addMilliseconds } from 'date-fns'
import BaseTile from './BaseTile.vue'
import {
  AutoBorderClasses,
  AutoColorClasses
} from '../utils/mixins/autoClasses'
import mixins from 'vue-typed-mixins'

export default mixins(AutoBorderClasses, AutoColorClasses).extend({
  components: {
    BaseTile
  },
  props: {
    startDate: {
      required: true,
      type: Date
    },
    endDate: {
      required: true,
      type: Date
    }
  },
  data() {
    return {
      anime: undefined,
      timePassedObj: { timePassed: 0 }
    } as {
      anime?: anime.AnimeInstance
      timePassedObj: { timePassed: number }
    }
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
    timeLeftPercent(): number {
      return (this.timeLeft / this.allTime) * 100
    }
  },
  mounted() {
    const allTime = this.allTime
    this.anime = this.createTimer(allTime, () => {
      this.$emit('finished')
    })
  },
  methods: {
    createTimer(allTime: number, completeHandler: () => void) {
      const timePassedObj = this.timePassedObj
      return anime({
        targets: timePassedObj,
        timePassed: allTime,
        autoplay: true,
        duration: allTime,
        easing: 'linear',
        round: 10,
        complete: completeHandler
      })
    }
  },
  beforeDestroy() {
    const anime = this.anime
    if (anime) anime.pause()
  }
})
</script>
