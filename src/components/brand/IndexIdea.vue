<script setup lang="ts">
import { computed } from "vue";
import BaseCard from "./BaseCard.vue";
import ContentDonation from "./ContentDonation.vue";
import { pick, t, useI18n, type Translation } from "@/i18n";
import windowImg from "@/assets/images/window.svg";
import plantsImg from "@/assets/images/plants.svg";
import blinkImg from "@/assets/images/blink.svg";
import mindfulnessImg from "@/assets/images/mindfulness.svg";
import outsideImg from "@/assets/images/outside.svg";
import workoutImg from "@/assets/images/workout.svg";

interface Idea {
  title: Translation;
  img: { src: string; alt: Translation };
  content: Translation;
}

const props = defineProps<{ long: boolean; finished: boolean; forceCloseLock: boolean }>();

const { t: tl } = useI18n({ title: t("Try this break idea", "Zainspiruj się") });

const longIdeas: Idea[] = [
  {
    title: t("Do some exercises", "Poćwicz chwilę"),
    img: { src: workoutImg, alt: t("Woman dancing", "Tańcząca kobieta") },
    content: t(
      "Few minutes of workout will help you relax from sitting position",
      "Kilka minut ćwiczeń pomoże ci się zrelaksować",
    ),
  },
  {
    title: t("Go outside", "Wyjdź na świeże powietrze"),
    img: { src: outsideImg, alt: t("Woman walk through a forest", "Kobieta idzie przez las") },
    content: t(
      "Go out to a park or a forest. Being close to nature will help you relax",
      "Pójdź na spacer do parku. Kontakt z naturą pomoże ci się zrelaksować",
    ),
  },
  {
    title: t("Relax a bit", "Zrelaksuj się"),
    img: {
      src: mindfulnessImg,
      alt: t("Woman meditating in front of ancient temple", "Kobieta medytuje przed świątynią"),
    },
    content: t(
      "Do what you do to relax. It could be drinking tea, meditating or whatever you like. But remember not to use your phone or computer now",
      "Zrób to co zwykle, gdy potrzebujesz się odprężyć. Przykładowo wypij herbatę, bądź pomedytuj. Pamiętaj, żeby nie używać do tego komputera, ani telefonu",
    ),
  },
];

const shortIdeas: Idea[] = [
  {
    title: t("Look out the window", "Wyjrzyj przez okno"),
    img: { src: windowImg, alt: t("Woman looks out the window", "Kobieta spogląda przez okno") },
    content: t(
      "Look far away through a window to help your eyes relax",
      "Patrzenie w dal pomoże Ci uniknąć krótkowzroczności",
    ),
  },
  {
    title: t("Look at plants", "Popatrz na rośliny"),
    img: { src: plantsImg, alt: t("Man is sitting in front of flowers", "Mężczyzna siedzi przy kwiatach") },
    content: t(
      "Green plants will help relax your eyes",
      "Spojrzenie na rośliny pomoże Ci zrelaksować oczy i odprężyć umysł",
    ),
  },
  {
    title: t("Blink your eyes", "Pomrugaj oczami"),
    img: { src: blinkImg, alt: t("Man looks at the darkness", "Mężczyzna patrzy w ciemność") },
    content: t("Blink few times to clean your eyes", "Mrugnij kilka razy, aby oczyścić oczy"),
  },
];

// One random idea per break type (re-rolled only if `long` changes, as in legacy).
const card = computed(() => {
  const ideas = props.long ? longIdeas : shortIdeas;
  return ideas[Math.floor(Math.random() * ideas.length)];
});
const showDonation = computed(() => props.long && props.finished);
</script>

<template>
  <div>
    <Transition name="fade" appear>
      <p
        v-show="!showDonation"
        class="selection-darker mb-4 font-display text-lg text-secondary-200 duration-300"
        :class="finished ? [] : ['delay-500']"
      >
        {{ tl("title") }}
      </p>
    </Transition>

    <Transition name="slide" appear mode="out-in">
      <BaseCard
        v-if="showDonation"
        key="donation-card"
        class="slide-leave-left max-w-3xl delay-300 duration-500"
        data-testid="donation-card"
      >
        <ContentDonation :force-close-lock="forceCloseLock" />
      </BaseCard>
      <BaseCard v-else key="inspiration-card" class="slide-leave-left max-w-3xl delay-100 duration-500">
        <div class="m-4 flex">
          <img class="mr-4 h-32 md:h-40 lg:h-48" :src="card.img.src" :alt="pick(card.img.alt)" data-testid="idea-img" />
          <div class="flex flex-col">
            <h3 class="font-preset-card-title mb-2 text-secondary-50" data-testid="idea-title">{{ pick(card.title) }}</h3>
            <p class="mb-4 text-lg text-secondary-100" data-testid="idea-content">{{ pick(card.content) }}</p>
          </div>
        </div>
      </BaseCard>
    </Transition>
  </div>
</template>
