<template funtional>
  <p class="font-preset-info text-center">
    {{ title }}
  </p>
</template>

<script lang="ts">
import { Lang } from '@/utils/mixins/i18n'
import mixins from 'vue-typed-mixins'

export default mixins(Lang).extend({
  computed: {
    title(): string {
      return this.$store.state.i18n.ideas.title[this.$lang]
    },
  },
})
</script>
