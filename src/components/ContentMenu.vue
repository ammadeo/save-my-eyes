<template>
  <div class="flex-grow">
    <p class="mb-4 text-lg uppercase text-secondary-200">
      next {{ nextBreakName }} in
      <span class="text-secondary-100">{{ nextBreakTime }}</span>
    </p>
    <ButtonIcon
      primary
      class="mb-8 w-full"
      @click="emitRun('start-long-break')"
      content="Start a long break now"
    ></ButtonIcon>
    <ButtonIcon
      class="mb-4 w-full"
      @click="emitRun('open-stop-protection')"
      content="Stop protection"
    ></ButtonIcon>
    <ButtonIcon
      class="mb-4 w-full"
      @click="emitRun('open-settings')"
      content="Settings"
    ></ButtonIcon>
  </div>
</template>

<script lang="ts">
import ButtonIcon from './ButtonIcon.vue'
import { RunKey } from '@/types/menu'
import { getUserSettingsStore } from '@/background/db'
import { formatDistanceStrict, addMinutes } from 'date-fns'
import { CheckIsLongBreak, GetBreakTime } from '@/utils/mixins/breaks'
import { lastSchedulerJobDate } from '@/background/store'

import mixins from 'vue-typed-mixins'
export default mixins(CheckIsLongBreak, GetBreakTime).extend({
  components: {
    ButtonIcon,
  },
  data() {
    return {
      nextBreakName: '',
      nextBreakTime: '',
    }
  },
  async beforeMount() {
    const isLong = await this.checkIsLongBreak()
    this.nextBreakName = this.breakName(isLong)

    this.nextBreakTime = await this.nextBreakIn(isLong)
  },
  methods: {
    emitRun(key: RunKey) {
      this.$emit('run', key)
    },
    async nextBreakDate(isLong: boolean): Promise<Date> {
      return addMinutes(
        lastSchedulerJobDate.value,
        await this.getBreakTime(isLong)
      )
    },
    async nextBreakIn(isLong: boolean): Promise<string> {
      return formatDistanceStrict(
        new Date(),
        await this.nextBreakDate(isLong),
        {
          roundingMethod: 'floor',
        }
      )
    },
    breakName(isLong: boolean): string {
      const name = isLong ? 'long' : 'short'
      return `${name} break`
    },
  },
})
</script>
