<script setup lang="ts">
import { watch } from "vue";
import BaseInputRange from "./BaseInputRange.vue";
import BaseIcon from "../BaseIcon.vue";
import BaseLink from "./BaseLink.vue";
import ButtonToggleLabeled from "./ButtonToggleLabeled.vue";
import { useSettingsForm } from "@/composables/useSettingsForm";
import { uiRanges } from "@/fixes";
import { settingsDict } from "@/settingsDict";
import { useI18n } from "@/i18n";

withDefaults(defineProps<{ forceLarge?: boolean }>(), { forceLarge: false });
const emit = defineEmits<{ changed: [] }>();

const { t, tg } = useI18n(settingsDict);
const form = useSettingsForm();
const { draft } = form;

watch(form.changed, (to) => to && emit("changed"));

defineExpose({ save: form.save, changed: form.changed });
</script>

<template>
  <section class="grow">
    <h3 class="sr-only">{{ t("settings") }}</h3>

    <BaseInputRange
      v-model="draft.every"
      :name="t('inputShortEvery')"
      :force-large="forceLarge"
      :min="uiRanges.everyMin[0]"
      :max="uiRanges.everyMin[1]"
      :scale="60"
      :suffix="tg('minutesSuffix')"
      class="mt-2 mb-2"
    />
    <BaseInputRange
      v-model="draft.shortLast"
      :name="t('inputShortLast')"
      :force-large="forceLarge"
      :min="uiRanges.shortLastSec[0]"
      :max="uiRanges.shortLastSec[1]"
      :suffix="tg('secondsSuffix')"
      class="mb-6"
    />
    <BaseInputRange
      v-model="draft.longEvery"
      :name="t('inputLongEvery')"
      :force-large="forceLarge"
      :min="draft.every / 60"
      :max="uiRanges.longEveryMaxMin"
      :scale="60"
      :step="draft.every / 60"
      :suffix="tg('minutesSuffix')"
      class="mb-2"
    />
    <BaseInputRange
      v-model="draft.longLast"
      :name="t('inputLongLast')"
      :force-large="forceLarge"
      :min="uiRanges.longLastMin[0]"
      :max="uiRanges.longLastMin[1]"
      :scale="60"
      :suffix="tg('minutesSuffix')"
      class="mb-4"
    />

    <p class="mb-1 font-display text-secondary-100">{{ t("sound") }}</p>
    <ButtonToggleLabeled
      :on="draft.soundsUi"
      :state-on="t('soundUiOn')"
      :state-off="t('soundUiOff')"
      class="mb-4"
      @toggle="draft.soundsUi = $event"
    >
      <template #iconOn><BaseIcon class="h-4 text-secondary-100" icon="sound" /></template>
      <template #iconOff><BaseIcon class="h-4 text-secondary-100" icon="mute" /></template>
    </ButtonToggleLabeled>

    <p class="mb-1 font-display text-secondary-100">{{ t("language") }}</p>
    <ButtonToggleLabeled
      :on="draft.lang === 'en'"
      :state-on="t('languageOn')"
      :state-off="t('languageOff')"
      class="mb-6"
      @toggle="draft.lang = $event ? 'en' : 'pl'"
    >
      <template #iconOn><p class="text-secondary-100">EN</p></template>
      <template #iconOff><p class="text-secondary-100">PL</p></template>
    </ButtonToggleLabeled>

    <h3 class="font-preset-card-title mb-1 text-secondary-100">{{ t("credentials") }}</h3>
    <p class="mb-2 text-lg text-secondary-100">
      {{ t("createdBy") }}
      <BaseLink href="https://ammadeo.dev">{{ t("author") }}</BaseLink>
    </p>
    <p class="mb-2 text-lg text-secondary-100">
      {{ t("thanksTo") }}
      <BaseLink href="https://undraw.co/">Katerina Limpitsouni</BaseLink>
      {{ t("thanksFor") }}
    </p>
  </section>
</template>
