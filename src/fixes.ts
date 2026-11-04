/**
 * Port of legacy utils/db.ts (FixNumber / FixSettings): clamps the settings form to the
 * ranges the UI offers and builds the bilingual "Fixing X from A to B" log.
 *
 * Every Fix uses the contract units: seconds, except `longEvery`, which is a count of
 * short breaks (as the Rust side reports it). Messages render `longEvery` as minutes.
 */
import type { Fix, FixCode, Lang, Settings } from "./bridge";
import { globalDict, t, type Translation } from "./i18n";

export class FixNumber {
  private value: number;
  constructor(private readonly original: number) {
    this.value = original;
  }
  min(minimum: number) {
    this.value = Math.max(this.value, minimum);
    return this;
  }
  max(maximum: number) {
    this.value = Math.min(this.value, maximum);
    return this;
  }
  round() {
    this.value = Math.round(this.value);
    return this;
  }
  toClosest(step: number) {
    this.value = Math.round(this.value / step) * step;
    return this;
  }
  val() {
    return { value: this.value, original: this.original, changed: this.value !== this.original };
  }
}

const names: Record<FixCode, Translation> = {
  shortEvery: t("short break every", "czas między krótkimi przerwami"),
  shortLast: t("short break length", "długość krótkiej przerwy"),
  longEvery: t("long break every", "czas między długimi przerwami"),
  longLast: t("long break length", "długość długiej przerwy"),
};

function formatSeconds(value: number, lang: Lang) {
  if (value > 60) return `${Math.round(value / 60)} min.`;
  return `${value} ${globalDict.secondsSuffix[lang]}`;
}

/** Bilingual log line for one fix. `every` (seconds) converts a `longEvery` count to time. */
export function fixMessage(fix: Fix, lang: Lang, every: number) {
  const scale = fix.code === "longEvery" ? every : 1;
  const from = formatSeconds(Math.round(fix.from * scale), lang);
  const to = formatSeconds(Math.round(fix.to * scale), lang);
  const name = names[fix.code][lang];
  return lang === "pl" ? `Naprawiam ${name} z ${from} na ${to}` : `Fixing ${name} from ${from} to ${to}`;
}

/** Form state in seconds; `longEvery` is the interval between long breaks in seconds. */
export interface SettingsDraft {
  every: number;
  shortLast: number;
  longEvery: number;
  longLast: number;
  soundsUi: boolean;
  lang: Lang;
}

/** UI ranges (legacy ContentSettings), tighter than the Rust clamps. */
export const uiRanges = {
  everyMin: [5, 30],
  shortLastSec: [5, 60],
  longEveryMaxMin: 120,
  longLastMin: [1, 60],
} as const;

export const draftFromSettings = (s: Settings): SettingsDraft => ({
  every: s.breaks.every,
  shortLast: s.breaks.short.last,
  longEvery: s.breaks.long.every * s.breaks.every,
  longLast: s.breaks.long.last,
  soundsUi: s.sounds.ui,
  lang: s.lang,
});

/** Snaps the long-break interval to a multiple of the short-break interval. */
export const fixLongEvery = (fix: FixNumber, every: number) =>
  fix.round().toClosest(every).min(every).max(uiRanges.longEveryMaxMin * 60).val();

export function settingsFromDraft(draft: SettingsDraft, base: Settings): { settings: Settings; fixes: Fix[] } {
  const fixes: Fix[] = [];
  const track = (code: FixCode, r: ReturnType<FixNumber["val"]>, scale = 1) => {
    if (r.changed) fixes.push({ code, from: r.original / scale, to: r.value / scale });
    return r.value;
  };

  const every = track(
    "shortEvery",
    new FixNumber(draft.every).round().min(uiRanges.everyMin[0] * 60).max(uiRanges.everyMin[1] * 60).val(),
  );
  const shortLast = track(
    "shortLast",
    new FixNumber(draft.shortLast).round().min(uiRanges.shortLastSec[0]).max(uiRanges.shortLastSec[1]).val(),
  );
  const longEverySecs = track("longEvery", fixLongEvery(new FixNumber(draft.longEvery), every), every);
  const longLast = track(
    "longLast",
    new FixNumber(draft.longLast)
      .round()
      .min(uiRanges.longLastMin[0] * 60)
      .max(uiRanges.longLastMin[1] * 60)
      .val(),
  );

  return {
    settings: {
      breaks: {
        every,
        short: { last: shortLast },
        long: { last: longLast, every: Math.round(longEverySecs / every) },
      },
      sounds: { ...base.sounds, ui: draft.soundsUi },
      lang: draft.lang,
      calendar: { ...base.calendar },
    },
    fixes,
  };
}
