<template>
  <div class="flex w-full">
    <BaseCard
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
        :alt="img.alt[lang]"
      />
      <h3 class="font-preset-card-title mb-4 text-secondary-50 mx-2">
        {{ title[lang] }}
      </h3>
      <p class="mx-2 mb-4 text-lg text-secondary-100">{{ content[lang] }}</p>
    </BaseCard>
  </div>
</template>

<script>
import BaseCard from './BaseCard.vue'

import {
  AutoBorderClasses,
  AutoColorClasses,
} from '../utils/mixins/autoClasses'
import { Lang } from '../utils/mixins/i18n'
import { mapState } from 'vuex'
export default {
  components: {
    BaseCard,
  },
  mixins: [AutoBorderClasses, AutoColorClasses, Lang],
  computed: mapState({
    cards({ i18n }) {
      return i18n.ideas.cards
    },
  }),
  methods: {
    emitChangeAutoFinishLock(isAutoLock) {
      this.$emit('changeAutoFinishLock', isAutoLock)
    },
  },
}
</script>
