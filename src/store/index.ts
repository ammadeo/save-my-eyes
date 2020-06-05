import Vue from 'vue'
import Vuex, { StoreOptions } from 'vuex'

import { i18n, I18n } from './i18n'

Vue.use(Vuex)

export type RootStore = {
  sounds: {
    ui: boolean
    voice: boolean
  }
}

const store: StoreOptions<RootStore> = {
  modules: {
    i18n,
  },
  state: {
    sounds: {
      ui: true,
      voice: true
    }
  },
  mutations: {
    setSounds(state, to){
      state.sounds = to
    }
  }
}

export default new Vuex.Store<RootStore>(store)
