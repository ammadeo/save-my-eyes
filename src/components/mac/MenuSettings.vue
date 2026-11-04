<script setup lang="ts">
import { onUnmounted, ref } from "vue";
import MacSliderRow from "./MacSliderRow.vue";
import MenuCalendar from "./MenuCalendar.vue";
import { openUrl } from "@/bridge";
import { useSettingsForm } from "@/composables/useSettingsForm";
import { uiRanges } from "@/fixes";
import { useI18n } from "@/i18n";
import { settingsDict } from "@/settingsDict";

const { t, tg } = useI18n(settingsDict);
const { draft, changed, saving, save, reset } = useSettingsForm();

type Notice = { kind: "saved" | "fixed" | "failed"; lines: string[] };
const notice = ref<Notice>();
let timer: ReturnType<typeof setTimeout> | undefined;

async function onSave() {
  const result = await save();
  notice.value = {
    kind: !result.ok ? "failed" : result.messages.length ? "fixed" : "saved",
    lines: result.messages,
  };
  clearTimeout(timer);
  timer = setTimeout(() => (notice.value = undefined), 2500 + result.messages.length * 3000);
}
onUnmounted(() => clearTimeout(timer));
</script>

<template>
  <form class="settings-pane" @submit.prevent="onSave">
    <div>
      <h2 class="mac-section-title">{{ t("breaks") }}</h2>
      <div class="mac-group">
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
    </div>

    <MenuCalendar />

    <div class="mac-group">
      <label class="mac-row">
        <span class="grow">{{ t("soundUi") }}</span>
        <input v-model="draft.soundsUi" v-bind="{ switch: '' }" type="checkbox" role="switch" class="mac-switch" />
      </label>
      <label class="mac-row">
        <span class="grow">{{ t("language") }}</span>
        <select v-model="draft.lang" class="mac-popup">
          <option value="en">English</option>
          <option value="pl">Polski</option>
        </select>
      </label>
    </div>

    <div class="actions">
      <p v-if="notice" class="notice" :class="`is-${notice.kind}`" role="status">
        <strong>{{ notice.kind === "failed" ? t("saveFailed") : notice.kind === "fixed" ? t("fixing") : t("saved") }}</strong>
        <span v-for="line in notice.lines" :key="line" class="block">{{ line }}</span>
      </p>
      <span v-else class="grow" />
      <button type="button" class="mac-button" :disabled="!changed || saving" @click="reset">{{ t("revert") }}</button>
      <button type="submit" class="mac-button is-default" :disabled="!changed || saving">{{ tg("settingsSave") }}</button>
    </div>

    <p class="credits">
      {{ t("createdBy") }}
      <a href="https://ammadeo.dev" @click.prevent="openUrl('https://ammadeo.dev')">{{ t("author") }}</a>
      · {{ t("thanksTo") }}
      <a href="https://undraw.co/" @click.prevent="openUrl('https://undraw.co/')">Katerina Limpitsouni</a>
      {{ t("thanksFor") }}
    </p>
  </form>
</template>

<style scoped>
.settings-pane {
  display: flex;
  flex-direction: column;
  gap: 14px;
}
.mac-popup {
  font: inherit;
}
.actions {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  min-height: 24px;
}
.notice {
  flex: 1;
  margin: 0;
  padding: 6px 8px;
  border-radius: 6px;
  font-size: 11px;
  background: var(--mac-fill);
}
.notice.is-fixed,
.notice.is-failed {
  background: var(--mac-warning-bg);
  color: var(--mac-warning-label);
}
.credits {
  margin: 0 10px;
  font-size: 11px;
  color: var(--mac-label-secondary);
}
.credits a {
  color: var(--mac-accent);
  text-decoration: none;
}
.credits a:hover {
  text-decoration: underline;
}
</style>
