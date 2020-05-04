<template funtional>
  <p class="font-preset-info text-center">
    {{ title }}
  </p>
</template>

<script lang="ts">
// import { Lang } from '../utils/mixins/i18n'
import { mapState, Store } from '@/store'
import { Languages } from '@/store/i18n'
import mixins from 'vue-typed-mixins'

export default mixins(Store).extend({
  computed: mapState({
    title(state) {
      const lang = this.$lang as Languages
      return state.i18n.ideas.title[lang]
    },
  }),
})
</script>
