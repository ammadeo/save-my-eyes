import Vue from 'vue'
import Vuex, { StoreOptions } from 'vuex'

import { i18n, I18n } from './i18n'

Vue.use(Vuex)

export type RootStore = {}

const store: StoreOptions<RootStore> = {
  modules: {
    i18n,
  },
}

export default new Vuex.Store<RootStore>(store)
