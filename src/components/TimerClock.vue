<template>
  <div class="flex items-center w-full min-w-full relative self-start">
    <template v-if="timeLeft > 0">
      <p
        class="font-display flex-grow-0 flex-shrink-0 font-bold text-secondary-100 leading-none px-4 m-2 text-3xl"
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
    <template v-else>
      <!-- // todo add animation to show it on largew delay about 1 minute -->
      <p
        class="font-display flex-grow-0 flex-shrink-0 font-bold text-secondary-100 leading-none px-4 m-2 text-xl"
      >
        {{ breakOverdueInfo }}
      </p>
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
import Vue from 'vue'
export default Vue.extend({
  components: {
    BaseTile
  },
  mixins: [AutoBorderClasses, AutoColorClasses],
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
    }
  },
  computed: {
    allTime() {
      return this.endDate.getTime() - this.startDate.getTime()
    },
    timeLeft() {
      return this.allTime - this.timePassedObj.timePassed
    },
    timeLeftInfo() {
      const timeLeft = this.timeLeft
      const helperDate = addMilliseconds(new Date(0), timeLeft)
      return format(helperDate, 'mm : ss')
    },
    breakOverdueInfo() {
      const timeLeft = this.timeLeft
      const helperDate = addMilliseconds(new Date(0), timeLeft)
      return format(
        helperDate,
        "'Youre break have endded 'm ' minutes and ' s' seconds ago'"
      )
    },
    timeLeftPercent() {
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
    createTimer(allTime, completeHandler) {
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
  unmount() {
    this.anime.stop()
  }
})
</script>
