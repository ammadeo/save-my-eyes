<template>
  <section class="flex-grow">
    <h3 class="hidden">
      Settings
    </h3>

    <BaseInputRange
      v-model="every"
      name="Take a short break every"
      :forceLarge="forceLarge"
      :min="1"
      :center="15"
      :max="60"
      :scale="60"
      suffix="min."
      class="mb-2 mt-2"
    />
    <BaseInputRange
      v-model="short.last"
      name="Short break will last"
      :forceLarge="forceLarge"
      :min="1"
      :center="30"
      :max="60"
      class="mb-6"
      suffix="sec."
    />
    <BaseInputRange
      v-model="long.every"
      name="Take a long break every"
      :forceLarge="forceLarge"
      :min="every / 60"
      :center="(every * 3) / 60"
      :max="(every * 10) / 60"
      :scale="60 / every"
      :step="every / 60"
      :additional-validator="
        (value) =>
          value % (every / 60) === 0
            ? true
            : `You have to set value that can be devided to ${every /
                60} min. parts`
      "
      class="mb-2"
      suffix="min."
    />
    <BaseInputRange
      v-model="long.last"
      name="Long break will last"
      :forceLarge="forceLarge"
      :min="1"
      :center="5"
      :max="60"
      :scale="60"
      class="mb-4"
      suffix="min."
    />
    <p class="font-display mb-1  text-secondary-100">
      Sounds
    </p>
    <ButtonToggleLabeled
      :on="sounds.ui"
      @toggle="setSounds($event)"
      stateOn="Playing sounds"
      stateOff="Muting sounds"
      class="mb-4"
    >
      <template #iconOn>
        <BaseIcon class="h-4" icon="sound" />
      </template>
      <template #iconOff>
        <BaseIcon class="h-4" icon="mute" />
      </template>
    </ButtonToggleLabeled>
    <p class="font-display mb-1  text-secondary-100">
      Language
    </p>
    <ButtonToggleLabeled
      :on="lang === 'en'"
      @toggle="setLang($event)"
      stateOn="Zmień na Polski (Polish)"
      stateOff="Change to English (Angielski)"
      class="mb-6"
    >
      <template #iconOn>
        <p class="text-secondary-100">EN</p>
      </template>
      <template #iconOff>
        <p class="text-secondary-100">PL</p>
      </template>
    </ButtonToggleLabeled>
    <h3 class="font-preset-card-title mb-1  text-secondary-100">
      Credentials
    </h3>
    <p class=" mb-2 text-lg text-secondary-100">
      Created by <span>Amadeusza Chomiak</span>
    </p>
    <p class=" mb-2 text-lg text-secondary-100">
      Thanks to
      <a
        href="https://undraw.co/"
        hreflang="en"
        target="_blank"
        rel="noopener noreferrer"
        class="underline font-bold"
        >Katerina Limpitsouni</a
      >
      for awesome drawings
    </p>
  </section>
</template>

<script lang="ts">
import BaseInputRange from './BaseInputRange.vue'
import BaseIcon from './BaseIcon.vue'
import ButtonToggleLabeled from './ButtonToggleLabeled.vue'

import { getUserSettingsStore } from '@/background/db'
import Vue from 'vue'
import { Languages } from '../store/i18n'

interface Data {
  every: number
  short: {
    last: number
  }
  long: {
    last: number
    every: number
  }
  sounds: {
    ui: boolean
    voice: boolean
  }
  lang: Languages
  changed: boolean
}

export default Vue.extend({
  components: {
    BaseInputRange,
    ButtonToggleLabeled,
    BaseIcon,
  },
  props: {
    forceLarge: {
      type: Boolean,
      default: false,
    },
  },
  data(): Data {
    return {
      every: 15 * 60,
      short: {
        last: 30,
      },
      long: {
        last: 5 * 60,
        every: 3,
      },
      sounds: {
        ui: true,
        voice: true,
      },
      lang: 'en',
      changed: false,
    }
  },
  watch: {
    changed(to: boolean) {
      if (to === true) {
        this.$emit('changed')
      }
    },
  },
  beforeMount() {
    const store = getUserSettingsStore()
    const breaks = store.get('breaks')
    const sounds = store.get('sounds')
    const lang = store.get('lang')
    const { every, short, long } = breaks
    if (every && short && long && sounds && lang) {
      this.every = every
      this.short = short
      this.long = long
      this.sounds = sounds
      this.lang = lang

      this.$watch(
        () => {
          const { last: longLast, every: longEvery } = this.long
          return [
            this.every,
            this.short.last,
            longLast,
            longEvery,
            this.sounds.ui,
            this.lang,
          ]
        },
        () => {
          this.changed = true
        }
      )
    }
  },
  beforeDestroy() {
    this.setStore()
  },
  methods: {
    setStore() {
      const { every, short, long, sounds, lang } = this
      if (!this.changed) return

      getUserSettingsStore().set({
        breaks: {
          every,
          short,
          long,
        },
        sounds,
        lang,
      })
    },
    setLang(to: boolean) {
      const lang: Languages = to ? 'en' : 'pl'
      this.lang = lang
      this.$store.commit('i18n/setLang', lang)
    },
    setSounds(to: boolean) {
      this.sounds.ui = to
      this.$store.commit('setSounds', { ui: to, voice: true })
    },
  },
})
</script>
