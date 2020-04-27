<template funtional>
  <p class="font-preset-info text-center">
    {{ title }}
  </p>
</template>

<script>
import { Lang } from '../utils/mixins/i18n'
import { mapState } from 'vuex'
export default {
  mixins: [Lang],
  computed: mapState({
    title({ i18n }) {
      return i18n.ideas.title[this.lang]
    },
  }),
}
</script>
