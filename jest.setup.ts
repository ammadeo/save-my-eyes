import '@testing-library/jest-dom'
import vuex from 'vuex'
import Vue from 'vue'
import { Lang } from './src/utils/mixins/i18n'
Vue.use(vuex)
Vue.mixin(Lang)
