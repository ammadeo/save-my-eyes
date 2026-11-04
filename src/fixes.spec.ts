import { describe, expect, test } from "vitest";
import type { Settings } from "./bridge";
import { draftFromSettings, fixMessage, settingsFromDraft } from "./fixes";

const base = (patch: Partial<Settings["calendar"]> = {}): Settings => ({
  breaks: { every: 20 * 60, short: { last: 20 }, long: { last: 5 * 60, every: 3 } },
  sounds: { ui: true, voice: true },
  calendar: { enabled: true, graceSecs: 60, ...patch },
  lang: "en",
});

const withGrace = (calendarGrace: number, from = base()) =>
  settingsFromDraft({ ...draftFromSettings(from), calendarGrace }, from);

describe("fixes.ts calendarGrace", () => {
  test("round-trips through the draft", () => {
    const s = base({ graceSecs: 300 });
    expect(draftFromSettings(s).calendarGrace).toBe(300);
    const { settings, fixes } = settingsFromDraft(draftFromSettings(s), s);
    expect(settings.calendar).toEqual({ enabled: true, graceSecs: 300 });
    expect(fixes).toEqual([]);
  });

  test("clamps above 15 minutes", () => {
    const { settings, fixes } = withGrace(1000);
    expect(settings.calendar.graceSecs).toBe(900);
    expect(fixes).toEqual([{ code: "calendarGrace", from: 1000, to: 900 }]);
  });

  test("snaps to whole minutes", () => {
    expect(withGrace(90).settings.calendar.graceSecs).toBe(120);
    expect(withGrace(89).settings.calendar.graceSecs).toBe(60);
    expect(withGrace(89).fixes).toEqual([{ code: "calendarGrace", from: 89, to: 60 }]);
  });

  test("clamps below zero, keeps zero without a fix", () => {
    expect(withGrace(-30).settings.calendar.graceSecs).toBe(0);
    const { settings, fixes } = withGrace(0);
    expect(settings.calendar.graceSecs).toBe(0);
    expect(fixes).toEqual([]);
  });

  test("keeps `enabled` from base (the toggle applies outside the draft)", () => {
    const off = base({ enabled: false });
    expect(withGrace(180, off).settings.calendar).toEqual({ enabled: false, graceSecs: 180 });
  });

  test("fix message renders in both languages", () => {
    const fix = { code: "calendarGrace" as const, from: 1000, to: 900 };
    // formatSeconds joins number and unit with a no-break space
    const plain = (s: string) => s.replace(/\u00a0/g, " ");
    expect(plain(fixMessage(fix, "en", 1200))).toBe("Fixing pause after a call from 17 min. to 15 min.");
    expect(plain(fixMessage(fix, "pl", 1200))).toBe("Naprawiam wstrzymanie po rozmowie z 17 min. na 15 min.");
  });
});
