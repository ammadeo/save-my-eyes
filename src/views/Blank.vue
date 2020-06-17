<template funtional>
  <div class="flex justify-center items-center min-h-screen opacity-50">
    <div>
      <HeaderTitle class="flex justify-center text-center" />
      <p class="font-preset-info text-center">{{ $t('content') }}</p>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import HeaderTitle from '../components/HeaderTitle.vue'
export default Vue.extend({
  components: { HeaderTitle },
  beforeMount() {
    this.$useI18n((t) => {
      return {
        content: t('Wait for break to end', 'Poczekaj na koniec przerwy'),
      }
    })
  },
})
</script>
