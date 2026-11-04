<script setup lang="ts">
import { ref, useId } from "vue";
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

const titleId = useId();
const closeButton = ref<InstanceType<typeof ButtonRoundable>>();
/** Callers move focus into the card when they open it, so the keyboard lands on the card it just opened. */
defineExpose({ focus: () => (closeButton.value?.$el as HTMLElement | undefined)?.focus() });
</script>

<template>
  <!-- Non-modal: the cover behind stays usable, Escape closes like the close button. -->
  <BaseCard :absolute="absolute" role="dialog" :aria-labelledby="titleId" @keydown.esc.stop="emit('close')">
    <div class="mb-4 flex items-center justify-between gap-2">
      <h2 :id="titleId" class="text-headline text-label first-letter:uppercase">{{ title }}</h2>
      <ButtonRoundable ref="closeButton" :label="closeLabel || tl('close')" @click="emit('close')" />
    </div>
    <slot />
  </BaseCard>
</template>
