import { Module } from 'vuex'
import { RootStore } from './index'

// ? helpers
export const translate = (en = '', pl = '') => ({
  en,
  pl,
})
const t = translate
export type TranslateResult = ReturnType<typeof translate>
export type Translate = typeof translate
export interface Idea {
  title: TranslateResult
  img: {
    src: string
    alt: TranslateResult
  }
  content: TranslateResult
  link?: {
    src: TranslateResult
    content: TranslateResult
  }
}

export type I18nComponent<
  Keys extends { [key: string]: TranslateResult } = {
    [key: string]: TranslateResult
  }
> = {
  [key in keyof Keys]: TranslateResult
}

// ? translations
const globalTranslations = {
  title: t('Save My Eyes', 'Save My Eyes'),
  breakLong: t('long break', 'długa przerwa'),
  breakShort: t('short break', 'krótka przerwa'),
  timeAgoContentAgo: t('ago', 'temu'),
  settingsSave: t('Save changes', 'Zapisz zmiany'),
}
type Global = typeof globalTranslations
interface GlobalObject {
  global: Global
}
export type I18nGlobal = I18nComponent<Global>
// const getterContext = (args: [any, any, any, any]) => moduleGetterContext(args, i18n)
// const actionContext = (context: any) => moduleActionContext(context, i18n)

export type Languages = 'pl' | 'en'

export interface I18n extends GlobalObject {
  lang: Languages
  global: Global
}

export const i18n: Module<I18n, RootStore> = {
  namespaced: true,
  state: {
    lang: 'en',
    global: globalTranslations,
  },
  mutations: {
    setLang(state, code: Languages) {
      state.lang = code === 'pl' ? 'pl' : 'en'
    },
  },
}
