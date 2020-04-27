// ? ideas cards images
import windowImg from '../assets/images/window.svg'
import plantImg from '../assets/images/plant.svg'
import eyesImg from '../assets/images/eyes.svg'

// ? helpers
const translate = (en = '', pl = '') => ({
  en,
  pl
})
const t = translate

// ? translations
const generateI18n = () => ({
  settings: {
    title: t('App settings', 'Ustawienia')
  },
  app: {
    title: t('Save My Eyes', 'Uratuj Moje Oczy')
  },
  counter: {},
  breaks: {
    short: t('short break', 'długa przerwa'),
    long: t('long break', 'długa przerwa')
  },
  ideas: {
    title: t('Try one of those', 'Spróbuj jedną z tych'),
    cards: [
      {
        title: t('Look out the window', 'Rozejrzyj się przez okno'),
        img: {
          src: windowImg,
          alt: t('Woman looks out the window')
        },
        content: t('Look far away through a window to help your eyes relax'),
        link: {
          src: t(''),
          content: t('')
        }
      },
      {
        title: t('Look at a plant'),
        img: {
          src: plantImg,
          alt: t('Woman is sitting in front of flowers')
        },
        content: t('Green plants will help relax your eyes'),
        link: {
          src: t(''),
          content: t('')
        }
      },
      {
        title: t('Blink your eyes'),
        img: {
          src: eyesImg,
          alt: t('Face emoji is blinking its eyes')
        },
        content: t('Blink few times to clean your eyes'),
        link: {
          src: t(''),
          content: t('')
        }
      }
    ]
  }
})

export const state = () => ({
  lang: 'en',
  ...generateI18n()
})

export const mutations = {
  setLang(state, { code }) {
    state.lang = code === 'pl' ? 'pl' : 'en'
  }
}
