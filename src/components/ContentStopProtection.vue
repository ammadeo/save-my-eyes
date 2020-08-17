<template>
  <div class="flex-grow">
    <p class="mb-2 text-lg  text-secondary-100">
      {{ $t('stopFor') }}
    </p>
    <div class="flex mb-4 w-full">
      <BaseButton
        v-for="({ content, lenght }, index) in pauseLenghts"
        :key="'pause' + index"
        center
        class="flex-1 mr-2 last:mr-0"
        @click="pauseBreak(lenght)"
        data-testid="button-pause-break"
        ><p class="py-2 px-1">{{ content }}</p></BaseButton
      >
    </div>
    <p class="mb-2 text-lg  text-secondary-100">
      {{ $t('turnOffTitle') }}
    </p>
    <ButtonIcon
      primary
      class="mb-2 w-full"
      @click="closeApp()"
      :content="$t('turnOffContent')"
      icon="stop"
      data-testid="button-close-app"
    />
    <p class="text-secondary-200 text-center">
      {{ $t('turnOffInfo') }}
    </p>
  </div>
</template>

<script lang="ts">
import ButtonIcon from './ButtonIcon.vue'
import BaseButton from './BaseButton.vue'
import { rendererSetNextBreak, rendererCloseApp } from '@/background/ipc'
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
      await rendererSetNextBreak.ask({
        forceNextBreakIn: nextBreakIn,
        forceNextBreakType: 'long',
      })
      this.$emit('close')
    },
    async closeApp() {
      await rendererCloseApp.ask({})
    },
  },
  beforeMount() {
    this.$useI18n((t) => ({
      stopFor: t('Stop protection for', 'Wstrzymaj ochronę na'),
      turnOffTitle: t('Turn off protection', 'Wyłącz ochronę'),
      turnOffContent: t('for this session', 'podczas tej sesji'),
      turnOffInfo: t(
        'App will start again with your computer',
        'Aplikacja uruchomi się, gdy ponownie włączysz komputer'
      ),
      hour1: t('1 hour', '1 godzinę'),
      hour2: t('2 hours', '2 godziny'),
      hour3: t('3 hours', '3 godziny'),
    }))
  },
  computed: {
    pauseLenghts(): PauseLenght[] {
      return [
        {
          content: this.$t('hour1'),
          lenght: 60 * 60,
        },
        {
          content: this.$t('hour2'),
          lenght: 2 * 60 * 60,
        },
        {
          content: this.$t('hour3'),
          lenght: 3 * 60 * 60,
        },
      ]
    },
  },
})
</script>
