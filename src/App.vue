<template>
  <router-view />
</template>

<script lang="ts">
import { getUserSettingsStore } from '@/background/db'
import Vue from 'vue'
import { rendererEmitLanguage } from '@/background/ipc'

export default Vue.extend({
  beforeMount() {
    let code = navigator.language
    console.log('lang code', code)
    const store = getUserSettingsStore()
    const lang = store.get('lang')
    if (lang) code = lang
    this.$store.commit('i18n/setLang', code)
    this.listenToLang()

    const sounds = store.get('sounds')
    this.$store.commit('setSounds', sounds)
  },
  methods: {
    listenToLang() {
      rendererEmitLanguage.listen().then(({ lang }) => {
        console.log('ipc changed lang')
        this.$store.commit('i18n/setLang', lang)
        this.listenToLang()
      })
    },
  },
})
</script>
