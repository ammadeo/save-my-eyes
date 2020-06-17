<template>
  <div>
    <transition name="fade" appear>
      <p
        class="mb-2 delay-500 duration-300 text-secondary-200 selection-darker font-display text-lg"
      >
        {{ $t('title') }}
      </p>
    </transition>

    <transition name="slide" appear>
      <BaseCard
        color="secondary-500"
        class="max-w-3xl delay-100 duration-500"
        v-if="card"
      >
        <div class="flex m-4">
          <img
            class="mr-4 h-32 md:h-40 lg:h-48"
            :src="card.img.src"
            :alt="card.img.alt[$langLanguage]"
          />
          <div class="flex flex-col">
            <h3 class="font-preset-card-title mb-2 text-secondary-50">
              {{ card.title[$langLanguage] }}
            </h3>
            <p class="mb-4 text-lg text-secondary-100">
              {{ card.content[$langLanguage] }}
            </p>
          </div>
        </div>
      </BaseCard>
    </transition>
  </div>
</template>

<script lang="ts">
import BaseCard from './BaseCard.vue'
import Vue from 'vue'
import { Card, translate } from '@/store/i18n'

// ? ideas cards images
import windowImg from '@/assets/images/window.svg'
import plantImg from '@/assets/images/plant.svg'
import eyesImg from '@/assets/images/eyes.svg'

export default Vue.extend({
  components: {
    BaseCard,
  },
  data() {
    return {
      ideaIndex: -1,
    }
  },
  beforeMount() {
    this.ideaIndex = this.random(3)
    this.$useI18n((t) => ({
      title: t('Try this break idea', 'Zainspiruj się'),
    }))
  },
  computed: {
    card(): Card | undefined {
      const ideaIndex = this.ideaIndex
      if (ideaIndex >= 0) return this.generateIdeas()[ideaIndex]
      return undefined
    },
  },
  methods: {
    random(max: number) {
      return Math.floor(Math.random() * max)
    },
    generateIdeas() {
      const t = translate
      return [
        {
          title: t('Look out the window', 'Wyjrzyj przez okno'),
          img: {
            src: windowImg,
            alt: t('Woman looks out the window'),
          },
          content: t(
            'Look far away through a window to help your eyes relax',
            'Patrzenie w dal pomoże Ci uniknąć krótko wzroczności'
          ),
          link: {
            src: t(''),
            content: t(''),
          },
        },
        {
          title: t('Look at a plant', 'Popatrz na rośliny'),
          img: {
            src: plantImg,
            alt: t('Woman is sitting in front of flowers'),
          },
          content: t(
            'Green plants will help relax your eyes',
            'Spojżenie na rośliny pomoże Ci zrelaksować oczy i odprężyć umysł'
          ),
          link: {
            src: t(''),
            content: t(''),
          },
        },
        {
          title: t('Blink your eyes', 'Pomrugaj oczami'),
          img: {
            src: eyesImg,
            alt: t('Face emoji is blinking its eyes'),
          },
          content: t(
            'Blink few times to clean your eyes',
            'Mrugnij kilka razy, aby oczyścić oczy'
          ),
          link: {
            src: t(''),
            content: t(''),
          },
        },
      ] as Card[]
    },
  },
})
</script>
