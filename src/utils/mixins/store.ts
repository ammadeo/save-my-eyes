import Vue from 'vue'
import store from '@/store'
import { Languages } from '@/store/i18n'

export const Store = Vue.extend({
  computed: {
    $storeTyped(): typeof store {
      return this.$store as typeof store
    },
    $lang(): Languages {
      return this.$storeTyped.state.i18n.lang
    }
  }
})
