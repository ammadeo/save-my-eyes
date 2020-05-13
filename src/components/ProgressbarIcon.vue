<template>
  <BaseProgressbar :min="min" :max="max" :value="value">
    <BaseIcon class="absolute top-0 right-0 h-4 my-2 mx-4" :icon="icon" />
  </BaseProgressbar>
</template>

<script lang="ts">
import BaseProgressbar from './BaseProgressbar.vue'
import BaseIcon from './BaseIcon.vue'
import Vue from 'vue'
// import mixins from 'vue-typed-mixins'

export default Vue.extend({
  components: {
    BaseProgressbar,
    BaseIcon,
  },
  props: {
    min: {
      type: Number,
      required: true,
    },
    max: {
      type: Number,
      required: true,
    },
    value: {
      type: Number,
      required: true,
    },
    icon: {
      type: String,
      required: true,
    },
  },
})
</script>
