<template>
  <div>
    <transition name="fade" appear>
      <p
        v-show="!showDonation"
        class="mb-4 duration-300 text-secondary-200 selection-darker font-display text-lg"
        :class="finished ? [] : ['delay-500']"
      >
        {{ $t('title') }}
      </p>
    </transition>

    <transition name="slide" appear mode="out-in">
      <BaseCard
        v-if="showDonation"
        key="donation-card"
        class="slide-leave-left max-w-3xl duration-500 delay-300"
        data-testid="donation-card"
      >
        <ContentDonation :forceCloseLock="forceCloseLock" />
      </BaseCard>
      <BaseCard
        v-else-if="card"
        color="secondary-500"
        key="inspiration-card"
        class="max-w-3xl delay-100 duration-500 slide-leave-left"
      >
        <div class="flex m-4">
          <img
            class="mr-4 h-32 md:h-40 lg:h-48"
            :src="card.img.src"
            :alt="card.img.alt[$langLanguage]"
            data-testid="idea-img"
          />
          <div class="flex flex-col">
            <h3
              class="font-preset-card-title mb-2 text-secondary-50"
              data-testid="idea-title"
            >
              {{ card.title[$langLanguage] }}
            </h3>
            <p
              class="mb-4 text-lg text-secondary-100"
              data-testid="idea-content"
            >
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
import ContentDonation from './ContentDonation.vue'
import Vue from 'vue'
import { Idea, translate } from '@/store/i18n'

// ? ideas cards images
import windowImg from '@/assets/images/window.svg'
import plantsImg from '@/assets/images/plants.svg'
import blinkImg from '@/assets/images/blink.svg'
//* long ideas images
import mindfulnessImg from '@/assets/images/mindfulness.svg'
import outsideImg from '@/assets/images/outside.svg'
import workoutImg from '@/assets/images/workout.svg'

export default Vue.extend({
  components: {
    BaseCard,
    ContentDonation,
  },
  props: {
    long: {
      type: Boolean,
      required: true,
    },
    finished: {
      type: Boolean,
      required: true,
    },
    forceCloseLock: {
      type: Boolean,
      required: true,
    },
  },
  beforeMount() {
    this.$useI18n((t) => ({
      title: t('Try this break idea', 'Zainspiruj się'),
    }))
  },
  computed: {
    card(): Idea | undefined {
      return this.generateIdea(this.long)
    },
    showDonation(): boolean {
      return this.long && this.finished
    },
  },
  methods: {
    random(max: number) {
      return Math.floor(Math.random() * max)
    },
    generateIdea(long: boolean): Idea {
      const t = translate

      const ideas = long
        ? [
            {
              title: t('Do some exercises', 'Poćwicz chwilę'),
              img: {
                src: workoutImg,
                alt: t('Woman dancing', 'Tańcząca kobieta'),
              },
              content: t(
                'Few minutes of workout will help You relax from sitting position',
                'Kilka minut ćwiczeń pomoże ci się zrelaksować'
              ),
            },
            {
              title: t('Go outside', 'Wyjdź na świerze powietrze'),
              img: {
                src: outsideImg,
                alt: t(
                  'Woman walk through a forest',
                  'Kobieta idzie przez las'
                ),
              },
              content: t(
                'Go out to a park or a forest. Being close to nature will help you relax',
                'Pójdź na spacer do parku. Kontak z naturą pomoże ci się zrelaksować'
              ),
            },
            {
              title: t('Realax a bit', 'Zrelaksuj się'),
              img: {
                src: mindfulnessImg,
                alt: t(
                  'Woman meditating in front of ancient tample',
                  'Kobieta medytuja przed świątynią'
                ),
              },
              content: t(
                'Do what You do to relax. It could be drinking tea, meditating or wothever You like. But remember not to use Your phone or computer now',
                'Zrób to co zwykle, gdy potrzebujesz się odprężyć. Przykładowo wypij herbatę, bądź pomedytuj. Pamiętaj, żeby nie używać do tego komputera, ani telefonu'
              ),
            },
          ]
        : [
            // ? short break ideas
            {
              title: t('Look out the window', 'Wyjrzyj przez okno'),
              img: {
                src: windowImg,
                alt: t(
                  'Woman looks out the window',
                  'Kobieta spogląda przez okno'
                ),
              },
              content: t(
                'Look far away through a window to help your eyes relax',
                'Patrzenie w dal pomoże Ci uniknąć krótko wzroczności'
              ),
            },
            {
              title: t('Look at a plants', 'Popatrz na rośliny'),
              img: {
                src: plantsImg,
                alt: t(
                  'Man is sitting in front of flowers',
                  'Mężczyzna siedzi przy kwiatach'
                ),
              },
              content: t(
                'Green plants will help relax your eyes',
                'Spojżenie na rośliny pomoże Ci zrelaksować oczy i odprężyć umysł'
              ),
            },
            {
              title: t('Blink your eyes', 'Pomrugaj oczami'),
              img: {
                src: blinkImg,
                alt: t(
                  'Man looks at the darknes',
                  'Mężczyzna patrzy w ciemność'
                ),
              },
              content: t(
                'Blink few times to clean your eyes',
                'Mrugnij kilka razy, aby oczyścić oczy'
              ),
            },
          ]

      const index = this.random(ideas.length)

      return ideas[index]
    },
  },
})
</script>
