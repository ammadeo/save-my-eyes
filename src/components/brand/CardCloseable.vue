<script setup lang="ts">
import BaseCard from "./BaseCard.vue";
import ButtonRoundable from "./ButtonRoundable.vue";

import { t, useI18n } from "@/i18n";

const { t: tl } = useI18n({ close: t("Close", "Zamknij") });
withDefaults(defineProps<{ absolute?: boolean; title?: string; closeLabel?: string }>(), {
  absolute: false,
  title: "save my eyes",
  closeLabel: "",
});
const emit = defineEmits<{ close: [] }>();
</script>

<template>
  <BaseCard :absolute="absolute">
    <div class="mb-4 flex items-center justify-between gap-2">
      <p class="text-headline text-label first-letter:uppercase">{{ title }}</p>
      <ButtonRoundable :label="closeLabel || tl('close')" @click="emit('close')" />
    </div>
    <slot />
  </BaseCard>
</template>
