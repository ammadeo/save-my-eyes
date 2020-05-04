<template>
  <div class="flex-grow">
    <p class="mb-2 text-lg  text-secondary-100">
      Stop protection for
    </p>
    <div class="flex mb-4 w-full">
      <!-- // todo change to v-for -->
      <ButtonIcon
        class="mr-4 flex-1"
        @click="pauseBreak(60 * 60)"
        content="1 hour"
      ></ButtonIcon>
      <ButtonIcon
        class="mr-4 flex-1"
        @click="pauseBreak(2 * 60 * 60)"
        content="2 hours"
      ></ButtonIcon>
      <ButtonIcon
        class="flex-1"
        @click="pauseBreak(3 * 60 * 60)"
        content="3 hours"
      ></ButtonIcon>
    </div>
    <p class="mb-2 text-lg  text-secondary-100">
      Turn off protection
    </p>
    <ButtonIcon
      primary
      class="mb-2 w-full"
      @click="closeApp()"
      content="for this session"
    ></ButtonIcon>
    <p class="text-secondary-200 text-center">
      Will start again with your computer
    </p>
  </div>
</template>

<script lang="ts">
import ButtonIcon from './ButtonIcon.vue'
import { RunKey } from '@/types/menu'
import { rendererSetNextBreak, rendererCloseApp } from '@/background/ipc'
import { getUserSettingsStore } from '@/background/db'
import { formatDistanceStrict, addMinutes } from 'date-fns'
import Vue from 'vue'
export default Vue.extend({
  components: {
    ButtonIcon,
  },
  methods: {
    async pauseBreak(nextBreakIn: number) {
      await rendererSetNextBreak({ forceNextBreakIn: nextBreakIn })
      this.$emit('close')
    },
    async closeApp() {
      await rendererCloseApp()
    },
  },
})
</script>
