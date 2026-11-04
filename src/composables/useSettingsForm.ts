import { computed, reactive, ref, watch } from "vue";
import { setNextBreak, setSettings, type Fix } from "@/bridge";
import {
  draftFromSettings,
  fixLongEvery,
  FixNumber,
  fixMessage,
  settingsFromDraft,
  type SettingsDraft,
} from "@/fixes";
import { lang } from "@/i18n";
import { applySettings, cloneSettings, settings } from "@/settings";
import { log } from "@/log";

export interface SaveResult {
  ok: boolean;
  fixes: Fix[];
  messages: string[];
}

/**
 * Settings form shared by the menu window and the break-screen card. Nothing is
 * persisted until `save()` (no save-on-unmount, inventory risk #4).
 */
export function useSettingsForm() {
  const draft = reactive<SettingsDraft>(draftFromSettings(settings));
  const baseline = ref(JSON.stringify(draftFromSettings(settings)));
  const saving = ref(false);

  const changed = computed(() => JSON.stringify(draft) !== baseline.value);

  function reset() {
    Object.assign(draft, draftFromSettings(settings));
    baseline.value = JSON.stringify(draftFromSettings(settings));
  }

  // Another window saved: follow it unless the user is editing here.
  watch(
    () => JSON.stringify(settings),
    () => {
      if (!changed.value && !saving.value) reset();
    },
  );

  // Keep the long-break interval a multiple of the short-break interval.
  watch(
    () => draft.every,
    (every) => {
      draft.longEvery = fixLongEvery(new FixNumber(draft.longEvery), every).value;
    },
  );

  async function save(): Promise<SaveResult> {
    const { settings: next, fixes } = settingsFromDraft(draft, cloneSettings(settings));
    saving.value = true;
    try {
      const result = await setSettings(next);
      applySettings(result.settings);
      reset();
      const all = [...fixes, ...result.fixes];
      await setNextBreak({ keepWindows: true }).catch((error) => log.warn("reschedule failed", error));
      return {
        ok: true,
        fixes: all,
        messages: all.map((f) => fixMessage(f, lang.value, result.settings.breaks.every)),
      };
    } catch {
      return { ok: false, fixes, messages: fixes.map((f) => fixMessage(f, lang.value, next.breaks.every)) };
    } finally {
      saving.value = false;
    }
  }

  return { draft, changed, saving, save, reset };
}
