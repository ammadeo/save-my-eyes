<template>
  <router-view />
</template>

<script lang="ts">
import { getUserSettingsStore } from '@/background/db'
import Vue from 'vue'
import { rendererEmitLanguage } from '@/background/ipc'
import { verbose } from 'electron-log'
import { isProdBuild } from './background/env'

export default Vue.extend({
  beforeMount() {
    if (!isProdBuild) verbose('render app: before mount init')
    let code = navigator.language
    if (!isProdBuild) verbose('lang code', code)
    const store = getUserSettingsStore()
    const lang = store.get('lang')
    if (lang) code = lang
    this.$store.commit('i18n/setLang', code)
    this.listenToLang()

    const sounds = store.get('sounds')
    this.$store.commit('setSounds', sounds)
    if (!isProdBuild) verbose('render app: before mount finished')
  },
  methods: {
    listenToLang() {
      rendererEmitLanguage
        .listen()
        .then(({ lang }) => {
          console.log('ipc changed lang')
          this.$store.commit('i18n/setLang', lang)
          this.listenToLang()
        })
        .catch((e) => console.error(e))
    },
  },
})
</script>
