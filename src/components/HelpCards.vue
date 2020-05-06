<template>
  <div class="flex w-full">
    <CardAbsolute
      v-for="({ title, img, content, link }, index) in cards"
      :key="'card' + index"
      color="secondary-500"
      class="flex-grow"
      :class="{ 'mr-4': index < cards.length - 1 }"
      data-testid="help-card"
      @focusin="emitChangeAutoFinishLock(true)"
      @focusout="emitChangeAutoFinishLock(false)"
    >
      <img
        class="h-24 md:h-32 lg:h-40 xl:h-48 my-4 mx-2"
        :src="img.src"
        :alt="img.alt[$lang]"
      />
      <h3 class="font-preset-card-title mb-4 text-secondary-50 mx-2">
        {{ title[$lang] }}
      </h3>
      <p class="mx-2 mb-4 text-lg text-secondary-100">{{ content[$lang] }}</p>
    </CardAbsolute>
  </div>
</template>

<script lang="ts">
import CardAbsolute from './CardAbsolute.vue'

import {
  AutoBorderClasses,
  AutoColorClasses,
} from '../utils/mixins/autoClasses'
import { Lang } from '@/utils/mixins/i18n'
import mixins from 'vue-typed-mixins'

import { Card } from '@/store/i18n'

export default mixins(AutoBorderClasses, AutoColorClasses, Lang).extend({
  components: {
    CardAbsolute,
  },
  computed: {
    cards(): Card {
      return this.$store.state.i18n.ideas.cards
    },
  },
  methods: {
    emitChangeAutoFinishLock(isAutoLock: boolean) {
      this.$emit('changeAutoFinishLock', isAutoLock)
    },
  },
})
</script>
