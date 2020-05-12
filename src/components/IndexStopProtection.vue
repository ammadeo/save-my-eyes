<template>
  <div class="relative w-full">
    <div class=" flex justify-end items-center">
      <p
        class="font-display selection-darker text-sm tracking-wide mr-2 uppercase text-secondary-400"
      >
        Stop protection
      </p>
      <ButtonRoundable
        icon="pause"
        @click="setShowStopProtection(true)"
      ></ButtonRoundable>
    </div>
    <transition name="slide">
      <CardCloseable
        v-show="showStopProtection"
        absolute
        title="stop protection"
        class="right-0 top-0 z-30 max-h-screen-16 slide-enter-right lg:max-h-screen-24 xl:max-h-screen-32"
        @close="setShowStopProtection(false)"
      >
        <ContentStopProtection @close="$emit('run', 'closeWindow')" />
      </CardCloseable>
    </transition>
  </div>
</template>

<script lang="ts">
import ContentStopProtection from '../components/ContentStopProtection.vue'
import ButtonRoundable from '../components/ButtonRoundable.vue'
import CardCloseable from '../components/CardCloseable.vue'

import Vue from 'vue'
// import mixins from 'vue-typed-mixins'

export default Vue.extend({
  components: {
    ButtonRoundable,
    CardCloseable,
    ContentStopProtection,
  },
  data() {
    return {
      showStopProtection: false,
    }
  },
  methods: {
    setShowStopProtection(to: boolean) {
      this.$emit('changeAutoFinishLock', to)
      this.showStopProtection = to
    },
  },
})
</script>
