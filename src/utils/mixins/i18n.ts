import vue from 'vue'
import { Languages } from '@/store/i18n'

export const Lang = vue.extend({
  computed: {
    $lang(): Languages {
      return this.$store.state.i18n.lang
    },
  },
})
