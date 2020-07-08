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
      @blur="updateLongEvery()"
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
      :suffix="$tGlobal('secondsSuffix')"
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
      <BaseLink href="https://undraw.co/">Katerina Limpitsouni</BaseLink>
      {{ $t('thanksFor') }}
    </p>
  </section>
</template>

<script lang="ts">
import BaseInputRange from './BaseInputRange.vue'
import BaseIcon from './BaseIcon.vue'
import BaseLink from './BaseLink.vue'
import ButtonToggleLabeled from './ButtonToggleLabeled.vue'
import { getUserSettingsStore } from '@/background/db'
import {
  FixLogCode,
  FixLog,
  FixSettings,
  TimeFormat,
  FixNumber,
} from '@/utils/db'
import { rendererEmitLanguage as emitLanguage } from '@/background/ipc'
import Vue from 'vue'
import { Languages } from '../store/i18n'
interface BreaksData {
  every: number
  short: {
    last: number
  }
  long: {
    last: number
    every: number
  }
}

interface SoundsData {
  ui: boolean
  voice: boolean
}

interface SettingsData {
  breaks: BreaksData
  sounds: SoundsData
  lang: Languages
}
interface Data extends BreaksData {
  changed: boolean
  sounds: SoundsData
  lang: Languages
}

export default Vue.extend({
  components: {
    BaseInputRange,
    ButtonToggleLabeled,
    BaseIcon,
    BaseLink,
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
        ] as [number, number, number, number, boolean, Languages]
      },
      () => {
        this.changed = true
      }
    )
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
    }))
  },
  beforeDestroy() {
    this.setStore()
  },
  methods: {
    setStore() {
      if (!this.changed) return
      const { data, log } = this.fixSettings(this)
      getUserSettingsStore().set(data)
      this.$emit('fixing', log)
    },
    updateLongEvery() {
      this.long.every = this.fixEvery(
        new FixNumber(this.long.every),
        this.every
      ).value
    },
    fixEvery(fix: FixNumber, every: number): ReturnType<FixNumber['val']> {
      return fix
        .round()
        .toClosest(every)
        .min(every)
        .max(120 * 60)
        .val()
    },
    fixSettings({
      every: originalEvery,
      short: originalShort,
      long: originalLong,
      sounds,
      lang,
    }: Data): {
      data: SettingsData
      log: FixLog[]
    } {
      const fixer = new FixSettings(this.$tGlobal, this.$langLanguage)
      const every = fixer.fix(
        originalEvery,
        (fix) =>
          fix
            .round()
            .min(5 * 60)
            .max(30 * 60)
            .val(),
        'shortEvery',
        'short break every',
        'czas między krótkimi przerwami'
      )
      const short = { last: 0 }
      short.last = fixer.fix(
        originalShort.last,
        (fix) =>
          fix
            .round()
            .min(5)
            .max(60)
            .val(),
        'shortLast',
        'short break length',
        'długość krótkiej przerwy'
      )
      const long = { last: 0, every: 0 }

      long.every = Math.round(
        fixer.fix(
          originalLong.every,
          (fix) => this.fixEvery(fix, every),
          'longEvery',
          'long break every',
          'czas między długimi przerwami'
        ) / every
      )
      long.last = fixer.fix(
        originalLong.last,
        (fix) =>
          fix
            .round()
            .min(60)
            .max(60 * 60)
            .val(),
        'longLast',
        'long break length',
        'długość długiej przerwy'
      )

      return {
        data: {
          breaks: {
            every,
            short,
            long,
          },
          sounds,
          lang,
        },
        log: fixer.log,
      }
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
