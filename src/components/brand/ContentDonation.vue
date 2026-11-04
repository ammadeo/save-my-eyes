<script setup lang="ts">
import { ref } from "vue";
import ButtonIcon from "./ButtonIcon.vue";
import appreciationImg from "@/assets/images/appreciation.svg";
import { endBreak, openUrl } from "@/bridge";
import { t, useI18n } from "@/i18n";

defineProps<{ forceCloseLock: boolean }>();

const { t: tl } = useI18n({
  imageAlt: t("Spread love", "Podziel się miłością"),
  title: t("Like what you see?", "Podoba Ci się aplikacja?"),
  description: t("Consider supporting development of this project", "Rozważ wsparcie rozwoju tego projektu"),
  link: t("Buy me a coffee", "Zamów mi kawę"),
  note: t("Will open your default browser", "Otworzy się w Twojej przeglądarce"),
});

const opened = ref(false);
async function openCoffee() {
  if (opened.value) return;
  opened.value = true;
  await openUrl("https://buymeacoffee.com/ammadeo");
  await endBreak().catch(() => {});
}
</script>

<template>
  <div class="flex items-center gap-5">
    <img class="h-32 w-auto shrink-0 lg:h-40" :src="appreciationImg" :alt="tl('imageAlt')" data-testid="idea-img" />
    <div class="flex max-w-[48ch] flex-col items-start gap-1">
      <h3 class="text-title-2 text-label" data-testid="idea-title">{{ tl("title") }}</h3>
      <p class="text-body text-label-secondary" data-testid="idea-content">{{ tl("description") }}</p>
      <ButtonIcon class="is-large mt-3" :disabled="forceCloseLock" icon="coffee" :content="tl('link')" @click="openCoffee" />
      <p class="mt-1 text-footnote text-label-secondary">{{ tl("note") }}</p>
    </div>
  </div>
</template>
