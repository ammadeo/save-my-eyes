/**
 * Reactive copy of the Rust-owned settings. Loaded once in main.ts before mount and
 * kept in sync through the `settings-changed` event.
 */
import { reactive } from "vue";
import { getSettings, on, type Settings } from "./bridge";
import { setLang } from "./i18n";

export const defaultSettings = (): Settings => ({
  breaks: { every: 20 * 60, short: { last: 20 }, long: { last: 5 * 60, every: 3 } },
  sounds: { ui: true, voice: true },
  calendar: { enabled: false, graceSecs: 60 },
  lang: typeof navigator !== "undefined" && navigator.language.toLowerCase().startsWith("pl") ? "pl" : "en",
});

/** Inclusive ranges the Rust side clamps to. */
export const limits = {
  every: [60, 3600],
  shortLast: [1, 60],
  longLast: [60, 3600],
  longEvery: [1, 30],
  calendarGrace: [0, 900],
} as const;

export const settings = reactive<Settings>(defaultSettings());

export function applySettings(next: Settings) {
  settings.breaks.every = next.breaks.every;
  settings.breaks.short.last = next.breaks.short.last;
  settings.breaks.long.last = next.breaks.long.last;
  settings.breaks.long.every = next.breaks.long.every;
  settings.sounds.ui = next.sounds.ui;
  settings.sounds.voice = next.sounds.voice;
  settings.lang = next.lang;
  settings.calendar.enabled = next.calendar?.enabled ?? false;
  settings.calendar.graceSecs = next.calendar?.graceSecs ?? 60;
  setLang(next.lang);
}

export const cloneSettings = (s: Settings): Settings => JSON.parse(JSON.stringify(s));

/** Loads settings (defaults when the command is missing) and subscribes to changes. */
export async function initSettings() {
  setLang(settings.lang);
  try {
    applySettings(await getSettings());
  } catch {
    // bridge already logged; keep defaults
  }
  await on("settings-changed", applySettings);
}
