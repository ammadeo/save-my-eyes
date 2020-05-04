<template>
  <div class="flex-grow">
    <img
      class="h-24 md:h-32 lg:h-40 xl:h-48 my-4 mx-2"
      :src="img.src"
      :alt="img.alt"
    />
    <h3 class="font-preset-card-title text-secondary-1000 mb-1 mx-2">
      Settings
    </h3>

    <SettingsSlider
      v-model="every"
      name="Take a short break every"
      :min="1"
      :center="15"
      :max="60"
      :scale="60"
      suffix="min."
      class="mb-2"
    />
    <SettingsSlider
      v-model="short.last"
      name="Short break will last"
      :min="1"
      :center="30"
      :max="60"
      class="mb-6"
      suffix="sec."
    />
    <SettingsSlider
      v-model="long.every"
      name="Take a long break every"
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
    <SettingsSlider
      v-model="long.last"
      name="Long break will last"
      :min="1"
      :center="5"
      :max="60"
      :scale="60"
      class="mb-6"
      suffix="min."
    />
    <h3 class="font-preset-card-title mb-1 mx-2 text-secondary-1000">
      Credentials
    </h3>
    <p class="mx-2 mb-2 text-lg text-secondary-1000 text-center">
      Created by <span>Amadeusza Chomiak</span>
    </p>
    <p class="mx-2 mb-4 text-lg text-secondary-1000 text-center">
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
  </div>
</template>

<script lang="ts">
import SettingsSlider from './SettingsSlider.vue'
import settingsImg from '@/assets/images/settings.svg'

import { getUserSettingsStore } from '@/background/db'
import Vue from 'vue'
export default Vue.extend({
  components: {
    SettingsSlider,
  },
  data() {
    return {
      img: {
        src: settingsImg,
        alt: '',
      },
      every: 15 * 60,
      short: {
        last: 30,
      },
      long: {
        last: 5 * 60,
        every: 3,
      },
      changed: false,
    }
  },
  beforeMount() {
    const breaks = getUserSettingsStore().get('breaks')
    const { every, short, long } = breaks
    if (every && short && long) {
      this.every = every
      this.short = short
      this.long = long

      this.$watch(
        () => {
          const { last: longLast, every: longEvery } = this.long
          return [this.every, this.short.last, longLast, longEvery]
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
      // todo implement setStore only if any value has changed
      const { every, short, long } = this
      if (!this.changed) return

      getUserSettingsStore().set({
        breaks: {
          every,
          short,
          long,
        },
        sounds: {
          ui: true,
          voice: true,
        },
      })
    },
  },
})
</script>
