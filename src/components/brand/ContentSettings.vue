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

    <div class="flex flex-col gap-4">
      <BaseInputRange
        v-model="draft.every"
        :name="t('inputShortEvery')"
        :force-large="forceLarge"
        :min="uiRanges.everyMin[0]"
        :max="uiRanges.everyMin[1]"
        :scale="60"
        :suffix="tg('minutesSuffix')"
      />
      <BaseInputRange
        v-model="draft.shortLast"
        :name="t('inputShortLast')"
        :force-large="forceLarge"
        :min="uiRanges.shortLastSec[0]"
        :max="uiRanges.shortLastSec[1]"
        :suffix="tg('secondsSuffix')"
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
      />
      <BaseInputRange
        v-model="draft.longLast"
        :name="t('inputLongLast')"
        :force-large="forceLarge"
        :min="uiRanges.longLastMin[0]"
        :max="uiRanges.longLastMin[1]"
        :scale="60"
        :suffix="tg('minutesSuffix')"
      />
    </div>

    <h4 class="mt-6 mb-2 text-footnote text-label-secondary">{{ t("sound") }}</h4>
    <ButtonToggleLabeled
      :on="draft.soundsUi"
      :state-on="t('soundUiOn')"
      :state-off="t('soundUiOff')"
      @toggle="draft.soundsUi = $event"
    >
      <template #iconOn><BaseIcon class="h-3.5" icon="sound" /></template>
      <template #iconOff><BaseIcon class="h-3.5" icon="mute" /></template>
    </ButtonToggleLabeled>

    <h4 class="mt-4 mb-2 text-footnote text-label-secondary">{{ t("language") }}</h4>
    <ButtonToggleLabeled
      :on="draft.lang === 'en'"
      :state-on="t('languageOn')"
      :state-off="t('languageOff')"
      @toggle="draft.lang = $event ? 'en' : 'pl'"
    />

    <h4 class="mt-6 mb-2 text-footnote text-label-secondary">{{ t("credentials") }}</h4>
    <p class="text-body text-label-secondary">
      {{ t("createdBy") }}
      <BaseLink href="https://ammadeo.dev">{{ t("author") }}</BaseLink>
    </p>
    <p class="mt-1 text-body text-label-secondary">
      {{ t("thanksTo") }}
      <BaseLink href="https://undraw.co/">Katerina Limpitsouni</BaseLink>
      {{ t("thanksFor") }}
    </p>
  </section>
</template>
