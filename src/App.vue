<template>
  <router-view />
</template>

<script lang="ts">
import { getUserSettingsStore } from '@/background/db'
import Vue from 'vue'

export default Vue.extend({
  beforeMount() {
    let code = navigator.language
    console.log('lang code', code)
    const store = getUserSettingsStore()
    const lang = store.get('lang')
    if (lang) code = lang
    this.$store.commit('i18n/setLang', code)

    const sounds = store.get('sounds')
    this.$store.commit('setSounds', sounds)
  },
})
</script>
