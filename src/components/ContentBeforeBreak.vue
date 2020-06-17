<template>
  <div class="flex flex-col text-secondary-100 py-6 px-4">
    <h1 class="text-xl font-display uppercase mb-2">{{ $tGlobal('title') }}</h1>
    <p class="mb-2 first-letter:uppercase">
      {{ breakName }} {{ $t('contentBase') }} {{ breakStatus }}
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
      :class="waiting ? ['mb-6'] : []"
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
import { TimeAgoContent } from '@/utils/mixins/breaks'

import mixins from 'vue-typed-mixins'

interface Data {
  allTime: number
  isLong: boolean
  waiting: boolean
  waitingFrom?: Date
}

export default mixins(CreateTimer, CheckIsLongBreak, TimeAgoContent).extend({
  components: {
    ProgressbarIcon,
    ButtonIcon,
  },
  data(): Data {
    return {
      allTime: 5000,
      isLong: false,
      waiting: false,
      waitingFrom: undefined,
    }
  },
  beforeMount() {
    this.$useI18n((t) => ({
      contentStart: t('start break now', 'zacznij przerwę teraz'),
      contentWait: t('wait', 'zaczekaj chwilę'),
      contentBase: t('will start', 'zacznie się'),
      statusWaiting: t('when You ready', 'kiedy zechcesz'),
      statusStarting: t('in 5 seconds', 'za 5 sekund'),
    }))
  },
  computed: {
    timeLeftPercent(): number {
      return (this.timePassedObj.timePassed / this.allTime) * 100
    },
    breakName(): string {
      return this.isLong
        ? this.$tGlobal('breakLong')
        : this.$tGlobal('breakShort')
    },
    breakIcon(): string {
      return this.waiting ? 'start' : 'pause'
    },
    breakContent(): string {
      return this.waiting ? this.$t('contentStart') : this.$t('contentWait')
    },
    breakStatus(): string {
      return this.waiting ? this.$t('statusWaiting') : this.$t('statusStarting')
    },
  },
  methods: {
    wait() {
      if (this.waiting) {
        this.emitBreak()
      } else {
        this.$emit('wait')
        this.pauseAnime()
      }
      this.waiting = true
    },
    pauseAnime() {
      const anime = this.anime
      if (anime) anime.pause()
    },
    startTimer() {
      this.waitingFrom = new Date()
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
