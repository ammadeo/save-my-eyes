<template funtional>
  <p class="font-preset-info text-center">
    {{ title }}
  </p>
</template>

<script lang="ts">
import { Lang } from '../utils/mixins/i18n'
import { mapState } from 'vuex'
import Vue from 'vue'
export default Vue.extend({
  mixins: [Lang],
  computed: mapState({
    title({ i18n }) {
      return i18n.ideas.title[this.lang]
    }
  })
})
</script>
