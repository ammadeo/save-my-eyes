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
  <div class="m-4 flex">
    <img class="mr-4 w-48 md:w-56 lg:w-64" :src="appreciationImg" :alt="tl('imageAlt')" data-testid="idea-img" />
    <div class="flex flex-col">
      <h3 class="font-preset-card-title mb-2 text-secondary-50" data-testid="idea-title">{{ tl("title") }}</h3>
      <p class="mb-4 text-lg text-secondary-100" data-testid="idea-content">{{ tl("description") }}</p>
      <ButtonIcon primary :disabled="forceCloseLock" icon="coffee" :content="tl('link')" @click="openCoffee" />
      <p class="mt-1 self-center text-sm text-secondary-200">{{ tl("note") }}</p>
    </div>
  </div>
</template>
