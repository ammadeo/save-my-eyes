import Vue from 'vue'
import {
  Languages,
  I18nComponent,
  Translate,
  translate,
  I18nGlobal,
  TranslateResult,
} from '@/store/i18n'

interface Data {
  $lang: I18nComponent
}

export const Lang = Vue.extend({
  computed: {
    $langGlobal(): I18nGlobal {
      return this.$store.state?.i18n?.global
    },
    $langLanguage(): Languages {
      return this.$store.state?.i18n?.lang ?? 'en'
    },
  },
  data(): Data {
    return {
      $lang: {},
    }
  },
  methods: {
    $useI18n(generator: (translate: Translate) => I18nComponent) {
      this.$lang = generator(translate)
    },
    $t(id: string): string {
      const $lang = this.$lang
      if (id in $lang) return $lang[id][this.$langLanguage]

      throw new Error('id: ' + id + ', has not been founded in $lang')
    },
    $tGlobal(id: keyof I18nGlobal): string {
      const $langGlobal = this.$langGlobal

      if ((id as keyof I18nGlobal) in $langGlobal)
        return $langGlobal[id as keyof I18nGlobal][this.$langLanguage]
      throw new Error('id: ' + id + ', has not been founded in $langGlobal')
    },
  },
})
