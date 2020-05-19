<template>
  <div class="flex flex-col text-secondary-100 py-6 px-4">
    <h1 class="text-xl font-display uppercase mb-2">save my eyes</h1>
    <p class="mb-2">Short break starting in 5 seconds</p>
    <div class="h-8 w-full mb-6">
      <ProgressbarIcon
        :min="0"
        :max="100"
        :value="timeLeftPercent"
        icon="start"
      />
    </div>
    <!-- <p class="mb-2">You've already skiped 3 times</p> -->
    <ButtonIcon
      icon="skip"
      content="Skip for 5 minutes"
      @click.once="$emit('skip')"
    ></ButtonIcon>
  </div>
</template>

<script lang="ts">
import ProgressbarIcon from './ProgressbarIcon.vue'
import ButtonIcon from './ButtonIcon.vue'
import { CreateTimer } from '@/utils/mixins/createTimer'
import mixins from 'vue-typed-mixins'

export default mixins(CreateTimer).extend({
  components: {
    ProgressbarIcon,
    ButtonIcon,
  },
  data() {
    return {
      allTime: 5000,
    }
  },
  computed: {
    timeLeftPercent(): number {
      return (this.timePassedObj.timePassed / this.allTime) * 100
    },
  },
  mounted() {
    setTimeout(() => {
      const allTime = this.allTime
      this.anime = this.createTimer(allTime, () => {
        this.$emit('break')
      })
    }, 500)
  },
  beforeDestroy() {
    const anime = this.anime
    if (anime) anime.pause()
  },
})
</script>
