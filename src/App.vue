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
    const lang = getUserSettingsStore().get('lang')
    if (lang) code = lang
    this.$store.commit('i18n/setLang', code)
  },
})
</script>
