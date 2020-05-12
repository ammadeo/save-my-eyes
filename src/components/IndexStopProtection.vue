<template>
  <div>
    <div class=" flex justify-end items-center">
      <p
        class="font-display selection-darker text-sm tracking-wide mr-2 uppercase text-secondary-400"
      >
        Stop protection
      </p>
      <ButtonRoundable
        icon="pause"
        @click="showStopProtection = !showStopProtection"
      ></ButtonRoundable>
    </div>
    <BaseCard
      v-show="showStopProtection"
      class="col-start-1 col-end-4 row-start-1 row-end-4 right-0 top-0 z-10 m-4"
      @mouseleave.native="showStopProtection = false"
    >
      <ContentStopProtection @close="closeWindow()" />
    </BaseCard>
  </div>
</template>

<script lang="ts">
import ContentStopProtection from '../components/ContentStopProtection.vue'
import ButtonRoundable from '../components/ButtonRoundable.vue'
import BaseCard from '../components/BaseCard.vue'

import Vue from 'vue'
// import mixins from 'vue-typed-mixins'

export default Vue.extend({
  components: {
    ButtonRoundable,
    BaseCard,
    ContentStopProtection,
  },
  data() {
    return {
      showStopProtection: false,
    }
  },
})
</script>
