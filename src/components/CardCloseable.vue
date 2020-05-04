<template>
  <BaseCard class="p-4" :color="color">
    <div class="flex justify-between">
      <p v-show="!content" class="uppercase text-xl">save my eyes</p>
      <ButtonClose :content="content" @click="$emit('close')" />
    </div>
    <slot />
  </BaseCard>
</template>

<script lang="ts">
import BaseCard from './BaseCard.vue'
import ButtonClose from './ButtonClose.vue'

import mixins from 'vue-typed-mixins'

export default mixins().extend({
  components: {
    BaseCard,
    ButtonClose,
  },
  props: {
    color: {
      type: String,
      default: 'secondary-800',
    },
    content: {
      type: String,
      required: false,
    },
  },
})
</script>
