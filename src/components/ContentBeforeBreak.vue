<template>
  <div class="flex flex-col text-secondary-100 py-6 px-4">
    <h1 class="text-xl font-display uppercase mb-2">{{ $tGlobal('title') }}</h1>
    <p
      class="first-letter:uppercase"
      :class="waiting ? (waitingInfo ? [] : ['mb-4']) : ['mb-2']"
    >
      {{ breakName }} {{ $t('contentBase') }} {{ breakStatus }}
    </p>
    <transition name="fade">
      <p class="mb-4 first-letter:uppercase" v-show="waitingInfo">
        {{ $t('waitingPrefix') }}
        <span class="font-semibold">{{ waitingInfo }}</span>
      </p>
    </transition>
    <div class="h-8 w-full mb-6" v-show="!waiting">
      <ProgressbarIcon
        :min="0"
        :max="100"
        :value="timeLeftPercent"
        small
        icon="start"
      />
    </div>
    <ButtonIcon
      v-show="waiting"
      icon="skip"
      class="opacity-85 mb-6"
      content="Skip break"
      @click="$emit('skip')"
    ></ButtonIcon>
    <ButtonIcon
      :icon="breakIcon"
      :primary="waiting"
      :content="breakContent"
      @click="wait()"
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
  waitingFrom: Date
  waitingInterval?: NodeJS.Timeout
  waitingInfo: string
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
      waitingFrom: new Date(),
      waitingInterval: undefined,
      waitingInfo: '',
    }
  },
  beforeMount() {
    this.$useI18n((t) => ({
      contentStart: t('start break now', 'zacznij przerwę teraz'),
      contentWait: t('wait', 'zaczekaj chwilę'),
      contentBase: t('will start', 'zacznie się'),
      statusWaiting: t('when You ready', 'kiedy zechcesz'),
      statusStarting: t('in 5 seconds', 'za 5 sekund'),
      waitingPrefix: t("You're waiting for", 'Czekasz już'),
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
        this.startTimer()
      }
      this.waiting = true
    },
    pauseAnime() {
      const anime = this.anime
      if (anime) anime.pause()
    },
    startTimer() {
      this.waitingFrom = new Date()
      this.waitingInterval = setInterval(() => {
        let timeAgoInfo = this.timeAgoContent(this.waitingFrom, false)
        if (this.$langLanguage === 'pl' && timeAgoInfo.includes('minuta'))
          timeAgoInfo = 'minutę'
        this.waitingInfo = timeAgoInfo
      }, 60 * 1000)
    },
    stopTimer() {
      const waitingInterval = this.waitingInterval
      if (waitingInterval) clearInterval(waitingInterval)
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
    this.stopTimer()
  },
})
</script>
