<template>
  <BaseCard
    color="secondary-500"
    class="flex-grow"
    data-testid="help-card"
    @focusin="emitChangeAutoFinishLock(true)"
    @focusout="emitChangeAutoFinishLock(false)"
  >
    <div class="flex m-4">
      <img
        class="mr-4 h-32 md:h-40 lg:h-48"
        :src="card.img.src"
        :alt="card.img.alt[$lang]"
      />
      <div class="flex flex-col">
        <h3 class="font-preset-card-title mb-2 text-secondary-50">
          {{ card.title[$lang] }}
        </h3>
        <p class="mb-4 text-lg text-secondary-100">
          {{ card.content[$lang] }}
        </p>
      </div>
    </div>
  </BaseCard>
</template>

<script lang="ts">
import BaseCard from './BaseCard.vue'

import {
  AutoBorderClasses,
  AutoColorClasses,
} from '../utils/mixins/autoClasses'
import { Lang } from '@/utils/mixins/i18n'
import mixins from 'vue-typed-mixins'

import { Card } from '@/store/i18n'

export default mixins(AutoBorderClasses, AutoColorClasses, Lang).extend({
  components: {
    BaseCard,
  },
  computed: {
    card(): Card {
      return this.$store.state.i18n.ideas.cards[1]
    },
  },
  methods: {
    emitChangeAutoFinishLock(isAutoLock: boolean) {
      this.$emit('changeAutoFinishLock', isAutoLock)
    },
  },
})
</script>
