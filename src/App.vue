<template>
  <div class="font-body bg-secondary-600 h-screen flex flex-col">
    <router-view />
  </div>
</template>

<script lang="ts">
import { getUserSettingsStore } from '@/background/db'
import { Store } from '@/store'
import mixins from 'vue-typed-mixins'

export default mixins(Store).extend({
  beforeMount() {
    let code = navigator.language
    console.log('lang code', code)
    const lang = getUserSettingsStore().get('lang')
    if (lang) code = lang
    this.$storeTyped.commit('setLang', code)
  }
})
</script>
