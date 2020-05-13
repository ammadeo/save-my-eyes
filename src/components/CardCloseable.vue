<template>
  <BaseCard :absolute="absolute">
    <BaseFocusTrap active>
      <div class="flex flex-col p-4">
        <div class="flex justify-between">
          <p v-show="!content" class="uppercase text-secondary-100 text-xl">
            {{ title }}
          </p>
          <ButtonRoundable
            primary
            :class="buttonClasses"
            :content="content"
            @click="$emit('close')"
          />
        </div>
        <slot />
      </div>
    </BaseFocusTrap>
  </BaseCard>
</template>

<script lang="ts">
import BaseCard from './BaseCard.vue'
import ButtonRoundable from './ButtonRoundable.vue'
import BaseFocusTrap from './BaseFocusTrap.vue'

import mixins from 'vue-typed-mixins'

export default mixins().extend({
  components: {
    BaseCard,
    ButtonRoundable,
    BaseFocusTrap,
  },
  props: {
    absolute: {
      type: Boolean,
      default: false,
    },
    title: {
      type: String,
      default: 'save my eyes',
    },
    content: {
      type: String,
      required: false,
    },
  },
  computed: {
    buttonClasses(): string[] {
      return this.content ? ['w-full'] : []
    },
  },
})
</script>
