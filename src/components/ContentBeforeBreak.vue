<template>
  <div class="flex flex-col text-secondary-100 py-6 px-4">
    <h1 class="text-xl font-display uppercase mb-2">save my eyes</h1>
    <p :class="waiting ? ['mb-6'] : ['mb-2']">
      {{ breakName }} break will start {{ breakStatus }}
    </p>
    <div class="h-8 w-full mb-6" v-show="!waiting">
      <ProgressbarIcon
        :min="0"
        :max="100"
        :value="timeLeftPercent"
        icon="start"
      />
    </div>
    <!-- <p class="mb-2">You've already skiped 3 times</p> -->
    <ButtonIcon
      :class="waiting ? ['mb-4'] : []"
      :icon="breakIcon"
      :primary="waiting"
      :content="breakContent"
      @click="wait()"
    ></ButtonIcon>
    <ButtonIcon
      v-show="waiting"
      icon="skip"
      content="Skip break"
      @click="$emit('skip')"
    ></ButtonIcon>
  </div>
</template>

<script lang="ts">
import ProgressbarIcon from './ProgressbarIcon.vue'
import ButtonIcon from './ButtonIcon.vue'
import { CreateTimer } from '@/utils/mixins/createTimer'
import { CheckIsLongBreak } from '@/utils/mixins/breaks'
import mixins from 'vue-typed-mixins'

export default mixins(CreateTimer, CheckIsLongBreak).extend({
  components: {
    ProgressbarIcon,
    ButtonIcon,
  },
  data() {
    return {
      allTime: 5000,
      isLong: false,
      waiting: false,
    }
  },
  computed: {
    timeLeftPercent(): number {
      return (this.timePassedObj.timePassed / this.allTime) * 100
    },
    breakName(): string {
      return this.isLong ? 'Long' : 'Short'
    },
    breakIcon(): string {
      return this.waiting ? 'start' : 'pause'
    },
    breakContent(): string {
      return this.waiting ? 'start break now' : 'wait'
    },
    breakStatus(): string {
      return this.waiting ? 'when you ready' : 'in 5 seconds'
    },
  },
  methods: {
    wait() {
      if (this.waiting) {
        this.emitBreak()
      } else {
        this.pauseAnime()
      }
      this.waiting = true
    },
    pauseAnime() {
      const anime = this.anime
      if (anime) anime.pause()
    },
    emitBreak() {
      this.$emit('break')
    },
  },
  async mounted() {
    this.isLong = await this.checkIsLongBreak()
    setTimeout(() => {
      const allTime = this.allTime
      this.anime = this.createTimer(allTime, () => {
        this.emitBreak()
      })
    }, 500)
  },
  beforeDestroy() {
    this.pauseAnime()
  },
})
</script>
