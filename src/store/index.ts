import Vue from 'vue'
import Vuex, { createHelpers } from 'vuex-typescript-interface'

import { i18n, I18n } from './i18n'

Vue.use(Vuex)

interface Store {
  modules: {
    i18n: I18n
  }
}

export default new Vuex.Store<Store>({
  modules: {
    i18n,
  },
})

export { Store } from '@/utils/mixins/store'

export const { mapState, mapGetters, mapMutations, mapActions } = createHelpers<
  Store
>()
