<script setup lang="ts">
import { ref } from "vue";
import BaseButton from "./BaseButton.vue";
import ButtonIcon from "./ButtonIcon.vue";
import ButtonRoundable from "./ButtonRoundable.vue";
import CardCloseable from "./CardCloseable.vue";
import { useStopProtection } from "@/composables/useStopProtection";
import { t, useI18n } from "@/i18n";

withDefaults(defineProps<{ disabled?: boolean }>(), { disabled: false });
const emit = defineEmits<{ changeAutoFinishLock: [locked: boolean] }>();

const { t: tl } = useI18n({ title: t("Stop protection", "Wstrzymaj ochronę") });
const stop = useStopProtection();
const open = ref(false);

function setOpen(to: boolean) {
  emit("changeAutoFinishLock", to);
  open.value = to;
}

// Rust closes the break and covers when the next break is rescheduled.
const pause = (hours: number) => stop.pause(hours);
</script>

<template>
  <div class="relative w-full">
    <div class="flex items-center justify-end gap-2" :class="{ invisible: open && !disabled }">
      <p class="text-footnote" :class="disabled ? 'text-label-tertiary' : 'text-label-secondary'">{{ tl("title") }}</p>
      <ButtonRoundable icon="pause" :label="tl('title')" data-testid="pause-button" :disabled="disabled" @click="setOpen(true)" />
    </div>
    <Transition name="slide">
      <CardCloseable
        v-show="open && !disabled"
        absolute
        :title="tl('title')"
        class="slide-enter-right top-0 right-0 z-30 max-h-[calc(100vh-2*var(--spacing-cover))]"
        @close="setOpen(false)"
      >
        <div class="grow">
          <p class="mb-2 text-body text-label-secondary">{{ stop.t("stopFor") }}</p>
          <div class="flex w-full gap-2">
            <BaseButton
              v-for="option in stop.options.value"
              :key="option.hours"
              center
              class="hour-button is-large flex-1"
              @click="pause(option.hours)"
            >
              {{ option.label }}
            </BaseButton>
          </div>
          <p class="mt-6 mb-2 text-body text-label-secondary">{{ stop.t("turnOffTitle") }}</p>
          <ButtonIcon class="is-large is-destructive w-full" icon="stop" :content="stop.t('turnOffContent')" @click="stop.quit()" />
          <p class="mt-2 text-center text-footnote text-label-secondary">{{ stop.t("turnOffInfo") }}</p>
        </div>
      </CardCloseable>
    </Transition>
  </div>
</template>

<style scoped>
/* Three hour buttons share the card width; let them shrink below the default side padding. */
.glass-button.hour-button {
  min-width: 0;
  padding-inline: 6px;
}
</style>
