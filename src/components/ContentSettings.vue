<template>
  <section class="flex-grow">
    <h3 class="hidden">
      {{ $t('settings') }}
    </h3>

    <BaseInputRange
      v-model="every"
      :name="$t('inputShortEvery')"
      :forceLarge="forceLarge"
      :min="5"
      :max="30"
      :scale="60"
      suffix="min."
      class="mb-2 mt-2"
    />
    <BaseInputRange
      v-model="short.last"
      :name="$t('inputShortLast')"
      :forceLarge="forceLarge"
      :min="5"
      :max="60"
      class="mb-6"
      :suffix="$t('secondsSuffix')"
    />
    <BaseInputRange
      v-model="long.every"
      :name="$t('inputLongEvery')"
      :forceLarge="forceLarge"
      :min="every / 60"
      :max="120"
      :scale="60"
      :step="every / 60"
      class="mb-2"
      suffix="min."
    />
    <BaseInputRange
      v-model="long.last"
      :name="$t('inputLongLast')"
      :forceLarge="forceLarge"
      :min="1"
      :max="60"
      :scale="60"
      class="mb-4"
      suffix="min."
    />
    <p class="font-display mb-1  text-secondary-100">
      {{ $t('sound') }}
    </p>
    <ButtonToggleLabeled
      :on="sounds.ui"
      @toggle="setSounds($event)"
      :stateOn="$t('soundUiOn')"
      :stateOff="$t('soundUiOff')"
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
      {{ $t('language') }}
    </p>
    <ButtonToggleLabeled
      :on="lang === 'en'"
      @toggle="setLang($event)"
      :stateOn="$t('languageOn')"
      :stateOff="$t('languageOff')"
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
      {{ $t('credentials') }}
    </h3>
    <p class=" mb-2 text-lg text-secondary-100">
      {{ $t('createdBy') }}
      <span> {{ $t('author') }} </span>
    </p>
    <p class=" mb-2 text-lg text-secondary-100">
      {{ $t('thanksTo') }}
      <a
        href="https://undraw.co/"
        hreflang="en"
        target="_blank"
        rel="noopener noreferrer"
        class="underline font-semibold"
        >Katerina Limpitsouni</a
      >
      {{ $t('thanksFor') }}
    </p>
  </section>
</template>

<script lang="ts">
import BaseInputRange from './BaseInputRange.vue'
import BaseIcon from './BaseIcon.vue'
import ButtonToggleLabeled from './ButtonToggleLabeled.vue'

import { getUserSettingsStore } from '@/background/db'
import { rendererEmitLanguage as emitLanguage } from '@/background/ipc'
import Vue from 'vue'
import { Languages } from '../store/i18n'
import { FixLog } from '@/types/settings'
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
    $langLanguage(to: Languages) {
      this.lang = to
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
      this.long = { last: long.last, every: long.every * every }
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
    this.$useI18n((t) => ({
      settings: t('Settings', 'Ustawienia'),
      inputShortEvery: t('Take a short break every', 'Zrób krótką przerwę co'),
      inputShortLast: t(
        'Short break will last',
        'Krótka przerwa będzie trwała'
      ),
      inputLongEvery: t('Take a long break every', 'Zrób długą przerwę co'),
      inputLongLast: t('Long break will last', 'Długa przerwa będzie trwała'),
      sound: t('Sound', 'Dźwięk'),
      soundUiOn: t('Playing sounds', 'Odtwarzam dźwięki'),
      soundUiOff: t('Muting sounds', 'Wyciszam dźwięki'),
      language: t('Language', 'Język'),
      languageOn: t('English (Angielski)'),
      languageOff: t('', 'Polski (Polish)'),
      credentials: t('Credentials', 'Podziękowania'),
      createdBy: t('Created by', 'Stworzona przez'),
      author: t('Amadeus Chomiak', 'Amadeusza Chomiaka'),
      thanksTo: t('Thanks to', 'Dzięki'),
      thanksFor: t('for awesome drawings', 'za świetne rysunki'),
      secondsSuffix: t('sec.', 'sek.'),
    }))
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
          long: {
            every: this.longBreakEveryToClosest(long.every),
            last: long.last,
          },
        },
        sounds,
        lang,
      })
    },
    longBreakEveryToClosest(everyInMinutes: number): number {
      const every = this.every
      const longBreakEvery = Math.round(everyInMinutes / every)
      if (longBreakEvery !== everyInMinutes / every)
        this.$emit('fixing', {
          code: 'longEvery',
          from: everyInMinutes,
          to: longBreakEvery * every,
        } as FixLog<number>)
      return longBreakEvery > 0 ? longBreakEvery : 1
    },
    setLang(to: boolean) {
      const lang: Languages = to ? 'en' : 'pl'
      this.lang = lang
      this.$store.commit('i18n/setLang', lang)
      emitLanguage.ask({ lang })
    },
    setSounds(to: boolean) {
      this.sounds.ui = to
      this.$store.commit('setSounds', { ui: to, voice: true })
    },
  },
})
</script>
