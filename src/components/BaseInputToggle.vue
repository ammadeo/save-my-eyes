<template>
  <div class="flex">
    <base-button></base-button>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
// import mixins from 'vue-typed-mixins'
import BaseButton from '@/components/BaseButton.vue'

export default Vue.extend({
  components: {
    BaseButton,
  },
})
</script>
