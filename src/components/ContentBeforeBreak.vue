<template>
  <div class="flex flex-col text-secondary-100 py-6 px-4">
    <h1 class="text-xl font-display uppercase mb-2">save my eyes</h1>
    <p class="mb-2">Short break starting in 3 seconds</p>
    <div class="h-8 w-full mb-6">
      <BaseProgressbar :min="0" :max="100" :value="10" />
    </div>
    <p class="mb-2">You've already skiped 3 times</p>
    <ButtonIcon icon="skip" content="Skip for 5 minutes"></ButtonIcon>
  </div>
</template>

<script lang="ts">
import BaseProgressbar from './BaseProgressbar.vue'
import ButtonIcon from './ButtonIcon.vue'
import Vue from 'vue'
// import mixins from 'vue-typed-mixins'

export default Vue.extend({
  components: {
    BaseProgressbar,
    ButtonIcon,
  },
})
</script>
