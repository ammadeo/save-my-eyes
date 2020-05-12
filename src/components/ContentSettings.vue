<template>
  <section class="flex-grow">
    <h3 class="hidden">
      Settings
    </h3>

    <SettingsSlider
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
    <SettingsSlider
      v-model="short.last"
      name="Short break will last"
      :forceLarge="forceLarge"
      :min="1"
      :center="30"
      :max="60"
      class="mb-6"
      suffix="sec."
    />
    <SettingsSlider
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
    <SettingsSlider
      v-model="long.last"
      name="Long break will last"
      :forceLarge="forceLarge"
      :min="1"
      :center="5"
      :max="60"
      :scale="60"
      class="mb-6"
      suffix="min."
    />
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
import SettingsSlider from './SettingsSlider.vue'

import { getUserSettingsStore } from '@/background/db'
import Vue from 'vue'
export default Vue.extend({
  components: {
    SettingsSlider,
  },
  props: {
    forceLarge: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
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
  watch: {
    changed(to: boolean) {
      if (to === true) {
        this.$emit('changed')
      }
    },
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
