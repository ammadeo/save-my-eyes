import { state, mutations } from '../store/i18n'
import vue from 'vue'
import vuex from 'vuex'

vue.use(vuex)

export const i18nStore = new vuex.Store({
  modules: {
    i18n: {
      state,
      mutations,
    },
  },
})
