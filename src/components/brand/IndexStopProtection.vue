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
    <div class="flex items-center justify-end">
      <p
        class="selection-darker mr-2 font-display text-sm tracking-wide uppercase"
        :class="disabled ? ['cursor-not-allowed', 'text-secondary-500'] : ['text-secondary-400']"
      >
        {{ tl("title") }}
      </p>
      <ButtonRoundable icon="pause" :label="tl('title')" data-testid="pause-button" :disabled="disabled" @click="setOpen(true)" />
    </div>
    <Transition name="slide">
      <CardCloseable
        v-show="open && !disabled"
        absolute
        :title="tl('title')"
        class="slide-enter-right top-0 right-0 z-30 max-h-[calc(100vh-4rem)] lg:max-h-[calc(100vh-6rem)] xl:max-h-[calc(100vh-8rem)]"
        @close="setOpen(false)"
      >
        <div class="grow">
          <p class="mb-2 text-lg text-secondary-100">{{ stop.t("stopFor") }}</p>
          <div class="mb-4 flex w-full gap-2">
            <BaseButton v-for="option in stop.options.value" :key="option.hours" center class="flex-1" @click="pause(option.hours)">
              <p class="px-1 py-2">{{ option.label }}</p>
            </BaseButton>
          </div>
          <p class="mb-2 text-lg text-secondary-100">{{ stop.t("turnOffTitle") }}</p>
          <ButtonIcon primary class="mb-2 w-full" icon="stop" :content="stop.t('turnOffContent')" @click="stop.quit()" />
          <p class="text-center text-secondary-200">{{ stop.t("turnOffInfo") }}</p>
        </div>
      </CardCloseable>
    </Transition>
  </div>
</template>
