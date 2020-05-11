<template>
  <BaseCard :color="color">
    <div class="flex flex-col p-4">
      <div class="flex justify-between">
        <p v-show="!content" class="uppercase text-secondary-100 text-xl">
          save my eyes
        </p>
        <ButtonRoundable primary :content="content" @click="$emit('close')" />
      </div>
      <slot />
    </div>
  </BaseCard>
</template>

<script lang="ts">
import BaseCard from './BaseCard.vue'
import ButtonRoundable from './ButtonRoundable.vue'

import mixins from 'vue-typed-mixins'

export default mixins().extend({
  components: {
    BaseCard,
    ButtonRoundable,
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
