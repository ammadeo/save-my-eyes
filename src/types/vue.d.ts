import Vue from 'vue'
import {
  Languages,
  I18nComponent,
  Translate,
  I18nGlobal,
} from '@/store/i18n'
type TranslateFunction =  ((id: string, global: false) => string) | ((id: keyof I18nGlobal, global: true) => string)

declare module 'vue/types/vue' {
  interface Vue {
   $langGlobal: I18nGlobal;
   $langLanguage: Languages
   $lang: I18nComponent;
   $useI18n: (generator: (translate: Translate) => I18nComponent) => void;
   $t: (id: string) => string;
   $tGlobal: (id: keyof I18nGlobal) => string
  }
}
