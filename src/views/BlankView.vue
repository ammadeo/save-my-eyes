<script setup lang="ts">
import { ref } from "vue";
import BlankBreakButton from "@/components/brand/BlankBreakButton.vue";
import HeaderTitle from "@/components/brand/HeaderTitle.vue";
import { endBreak } from "@/bridge";
import { useEvent } from "@/composables/useEvent";
import { t, useI18n } from "@/i18n";
import { log } from "@/log";

const { t: tl } = useI18n({
  content: t("Wait for break to end", "Poczekaj na koniec przerwy"),
  contentFinished: t("Break has ended", "Przerwa zakończyła się"),
});

const finished = ref(false);
useEvent("break-ended", () => (finished.value = true));

const end = () => endBreak().catch((error) => log.warn("end_break failed", error));
</script>

<template>
  <main class="relative flex h-screen items-center justify-center p-cover">
    <div class="flex flex-col items-center gap-3 text-center">
      <HeaderTitle />
      <p class="text-large-title text-label" aria-live="polite">{{ finished ? tl("contentFinished") : tl("content") }}</p>
    </div>
    <BlankBreakButton :finished="finished" @click="end" />
  </main>
</template>
