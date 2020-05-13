<template>
  <div>
    <transition name="fade" appear>
      <p
        class="mb-2 delay-500 duration-300 text-secondary-300 selection-darker font-display text-lg"
      >
        {{ title }}
      </p>
    </transition>

    <transition name="slide" appear>
      <BaseCard
        color="secondary-500"
        class="flex-grow delay-100 duration-500"
        data-testid="help-card"
        v-if="card"
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
    </transition>
  </div>
</template>

<script lang="ts">
import BaseCard from './BaseCard.vue'

import { Lang } from '@/utils/mixins/i18n'
import mixins from 'vue-typed-mixins'

import { Card } from '@/store/i18n'

export default mixins(Lang).extend({
  components: {
    BaseCard,
  },
  data() {
    return {
      ideaIndex: -1,
    }
  },
  beforeMount() {
    this.ideaIndex = this.random(2)
  },
  computed: {
    card(): Card | undefined {
      const ideaIndex = this.ideaIndex
      if (ideaIndex >= 0) return this.$store.state.i18n.ideas.cards[ideaIndex]
      return undefined
    },
    title(): string {
      return this.$store.state.i18n.ideas.title[this.$lang]
    },
  },
  methods: {
    emitChangeAutoFinishLock(isAutoLock: boolean) {
      this.$emit('changeAutoFinishLock', isAutoLock)
    },
    random(max: number) {
      return Math.floor(Math.random() * max)
    },
  },
})
</script>
