/**
 * Two languages, ~100 strings, no plurals: a ref and a lookup are enough (no vue-i18n).
 * The language comes from settings (`lang`), see settings.ts.
 */
import { computed, ref } from "vue";
import { pl as plLocale, enGB } from "date-fns/locale";
import type { Lang } from "./bridge";

export interface Translation {
  en: string;
  pl: string;
}

/** Builds one bilingual entry. */
export const t = (en = "", pl = ""): Translation => ({ en, pl });
export const translate = t;

export const lang = ref<Lang>("en");

/** `pl`, `pl-PL`, `PL_pl` → 'pl'; anything else → 'en' (fixes the legacy `pl-PL` → en bug). */
export function setLang(code: string | null | undefined) {
  lang.value = code?.toLowerCase().startsWith("pl") ? "pl" : "en";
}

export const globalDict = {
  title: t("Save My Eyes", "Save My Eyes"),
  breakLong: t("long break", "długa przerwa"),
  breakShort: t("short break", "krótka przerwa"),
  timeAgoContentAgo: t("ago", "temu"),
  settingsSave: t("Save changes", "Zapisz zmiany"),
  secondsSuffix: t("sec.", "sek."),
  minutesSuffix: t("min.", "min."),
};

export type GlobalKey = keyof typeof globalDict;

/** Reads a translation in the current language (reactive when used in render/computed). */
export const pick = (entry: Translation) => entry[lang.value];

export const tg = (key: GlobalKey) => pick(globalDict[key]);

export function useI18n<D extends Record<string, Translation>>(dict: D) {
  return {
    t: (key: keyof D) => pick(dict[key]),
    tg,
    lang,
  };
}

/** date-fns locale for the current language. */
export const dateLocale = computed(() => (lang.value === "pl" ? plLocale : enGB));
