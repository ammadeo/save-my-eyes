<template>
  <div class="flex-grow">
    <p class="mb-2 text-lg  text-secondary-100">
      Stop protection for
    </p>
    <div class="flex mb-4 w-full">
      <!-- // todo change to v-for -->
      <BaseButton class="mr-4 flex-1" @click="pauseBreak(60 * 60)"
        ><p>1 hour</p></BaseButton
      >
      <BaseButton class="mr-4 flex-1" @click="pauseBreak(2 * 60 * 60)"
        ><p>2 hours</p></BaseButton
      >
      <BaseButton class="flex-1" @click="pauseBreak(3 * 60 * 60)"
        ><p>3 hour</p></BaseButton
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
      Will start again with your computer
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
})
</script>
