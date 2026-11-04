<script setup lang="ts">
import { watch } from "vue";
import BaseLink from "./BaseLink.vue";
import MacSliderRow from "@/components/mac/MacSliderRow.vue";
import { useSettingsForm } from "@/composables/useSettingsForm";
import { uiRanges } from "@/fixes";
import { settingsDict } from "@/settingsDict";
import { useI18n } from "@/i18n";

/** `save` asks the card to save and close, so the fix log shows in one place (IndexSettings). */
const emit = defineEmits<{ changed: []; save: [] }>();

const { t, tg } = useI18n(settingsDict);
const form = useSettingsForm();
const { draft, changed, saving, reset } = form;

watch(changed, (to) => to && emit("changed"));

defineExpose({ save: form.save, changed: form.changed });
</script>

<template>
  <form class="flex grow flex-col gap-3.5" @submit.prevent="emit('save')">
    <div class="glass-group">
      <MacSliderRow
        v-model="draft.every"
        :label="t('inputShortEvery')"
        :min="uiRanges.everyMin[0]"
        :max="uiRanges.everyMin[1]"
        :scale="60"
        :suffix="tg('minutesSuffix')"
      />
      <MacSliderRow
        v-model="draft.shortLast"
        :label="t('inputShortLast')"
        :min="uiRanges.shortLastSec[0]"
        :max="uiRanges.shortLastSec[1]"
        :suffix="tg('secondsSuffix')"
      />
      <MacSliderRow
        v-model="draft.longEvery"
        :label="t('inputLongEvery')"
        :min="draft.every / 60"
        :max="uiRanges.longEveryMaxMin"
        :step="draft.every / 60"
        :scale="60"
        :suffix="tg('minutesSuffix')"
      />
      <MacSliderRow
        v-model="draft.longLast"
        :label="t('inputLongLast')"
        :min="uiRanges.longLastMin[0]"
        :max="uiRanges.longLastMin[1]"
        :scale="60"
        :suffix="tg('minutesSuffix')"
      />
    </div>

    <div class="glass-group">
      <label class="glass-row">
        <span class="grow">{{ t("soundUi") }}</span>
        <input v-model="draft.soundsUi" v-bind="{ switch: '' }" type="checkbox" role="switch" class="glass-switch" />
      </label>
      <label class="glass-row">
        <span class="grow">{{ t("language") }}</span>
        <select v-model="draft.lang" class="glass-select">
          <option value="en">English</option>
          <option value="pl">Polski</option>
        </select>
      </label>
    </div>

    <div class="flex justify-end gap-2">
      <button type="button" class="glass-button" :disabled="!changed || saving" @click="reset">{{ t("revert") }}</button>
      <button type="submit" class="glass-button is-primary" :disabled="!changed || saving">{{ tg("settingsSave") }}</button>
    </div>

    <div class="mx-3 text-footnote text-label-secondary">
      <p>
        {{ t("createdBy") }}
        <BaseLink href="https://ammadeo.dev">{{ t("author") }}</BaseLink>
      </p>
      <p>
        {{ t("thanksTo") }}
        <BaseLink href="https://undraw.co/">Katerina Limpitsouni</BaseLink>
        {{ t("thanksFor") }}
      </p>
    </div>
  </form>
</template>
