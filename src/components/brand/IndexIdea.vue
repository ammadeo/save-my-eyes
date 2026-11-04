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
      "A few minutes of workout will help you relax from sitting position",
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
    content: t("Blink a few times to clean your eyes", "Mrugnij kilka razy, aby oczyścić oczy"),
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
      <p v-show="!showDonation" class="mb-2 ml-4 text-footnote text-label-secondary">{{ tl("title") }}</p>
    </Transition>

    <Transition name="slide" appear mode="out-in">
      <BaseCard v-if="showDonation" key="donation-card" class="idea-card slide-leave-left max-w-[680px]" data-testid="donation-card">
        <ContentDonation :force-close-lock="forceCloseLock" />
      </BaseCard>
      <BaseCard v-else key="inspiration-card" class="idea-card slide-leave-left max-w-[680px]">
        <div class="flex items-center gap-5">
          <img
            class="h-32 w-auto shrink-0 lg:h-40"
            :src="card.img.src"
            :alt="pick(card.img.alt)"
            data-testid="idea-img"
          />
          <div class="flex max-w-[48ch] flex-col gap-1">
            <h3 class="text-title-2 text-label" data-testid="idea-title">{{ pick(card.title) }}</h3>
            <p class="text-body text-label-secondary" data-testid="idea-content">{{ pick(card.content) }}</p>
          </div>
        </div>
      </BaseCard>
    </Transition>
  </div>
</template>

<style scoped>
/* A calm, decelerating entrance (transitions.css owns the property; this only retimes it). */
.idea-card.slide-enter-active {
  transition-duration: 600ms;
  transition-delay: 150ms;
  transition-timing-function: cubic-bezier(0.16, 1, 0.3, 1);
}
</style>
