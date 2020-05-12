<template>
  <div class="flex-grow">
    <p class="mb-2 text-lg  text-secondary-100">
      Stop protection for
    </p>
    <div class="flex mb-4 w-full">
      <!-- // todo change to v-for -->
      <BaseButton
        v-for="({ content, lenght }, index) in pauseLenghts"
        :key="'pause' + index"
        center
        class="flex-1 mr-2 last:mr-0"
        @click="pauseBreak(lenght)"
        ><p class="py-2 px-1">{{ content }}</p></BaseButton
      >
    </div>
    <p class="mb-2 text-lg  text-secondary-100">
      Turn off protection
    </p>
    <ButtonIcon
      primary
      class="mb-2 w-full"
      @click="closeApp()"
      content="for this session"
      icon="stop"
    />
    <p class="text-secondary-200 text-center">
      App will start again with your computer
    </p>
  </div>
</template>

<script lang="ts">
import ButtonIcon from './ButtonIcon.vue'
import BaseButton from './BaseButton.vue'
import { RunKey } from '@/types/menu'
import { rendererSetNextBreak, rendererCloseApp } from '@/background/ipc'
import { getUserSettingsStore } from '@/background/db'
import { formatDistanceStrict, addMinutes } from 'date-fns'
import Vue from 'vue'

interface PauseLenght {
  content: string
  lenght: number
}

export default Vue.extend({
  components: {
    ButtonIcon,
    BaseButton,
  },
  methods: {
    async pauseBreak(nextBreakIn: number) {
      await rendererSetNextBreak.ask({ forceNextBreakIn: nextBreakIn })
      this.$emit('close')
    },
    async closeApp() {
      await rendererCloseApp.ask({})
    },
  },
  computed: {
    pauseLenghts(): PauseLenght[] {
      return [
        {
          content: '1 hour',
          lenght: 60 * 60,
        },
        {
          content: '2 hours',
          lenght: 2 * 60 * 60,
        },
        {
          content: '3 hours',
          lenght: 3 * 60 * 60,
        },
      ]
    },
  },
})
</script>
