import vue from 'vue'
export const Lang = vue.extend({
  computed: {
    lang() {
      return this.$store.state.i18n.lang
    }
  }
})
