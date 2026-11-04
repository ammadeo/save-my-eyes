import { beforeEach, describe, expect, test, vi } from "vitest";
import { fireEvent, render } from "@testing-library/vue";
import Component from "./ContentMenu.vue";
import { getBreakState, getCalendarStatus, type BreakState, type CalendarStatus } from "@/bridge";

vi.mock("@/bridge", () => ({
  getBreakState: vi.fn(),
  getCalendarStatus: vi.fn(),
  on: vi.fn(async () => () => {}),
}));

const state = (patch: Partial<BreakState> = {}): BreakState => ({
  breakIndex: 1,
  isLong: false,
  phase: "idle",
  scheduledAt: new Date(Date.now() + 20 * 60 * 1000).toISOString(),
  lengthSecs: 20,
  startedAt: null,
  heldForMeeting: false,
  ...patch,
});

const calendar = (patch: Partial<CalendarStatus> = {}): CalendarStatus => ({
  enabled: true,
  access: "granted",
  meeting: null,
  syncedAt: null,
  ...patch,
});

beforeEach(() => {
  vi.mocked(getBreakState).mockResolvedValue(state());
  vi.mocked(getCalendarStatus).mockResolvedValue(calendar());
});

describe("components/mac/ContentMenu.vue", () => {
  test("has next break time info", async () => {
    const { findByText } = render(Component);
    expect(await findByText("Next short break in")).toBeVisible();
    expect(await findByText("19 minutes")).toBeVisible();
  });

  test("names a long break that is going on", async () => {
    vi.mocked(getBreakState).mockResolvedValue(state({ isLong: true, phase: "active" }));
    const { findByText, queryByText } = render(Component);
    expect(await findByText("long break is still going")).toBeVisible();
    expect(queryByText("19 minutes")).toBeNull();
  });

  test("says when a break waits for a meeting", async () => {
    vi.mocked(getBreakState).mockResolvedValue(state({ heldForMeeting: true }));
    const { findByText } = render(Component);
    expect(await findByText("Waiting for your meeting to end")).toBeVisible();
  });

  test("replaces the countdown with the call going on", async () => {
    const until = new Date(Date.now() + 30 * 60 * 1000);
    vi.mocked(getBreakState).mockResolvedValue(state({ heldForMeeting: true }));
    vi.mocked(getCalendarStatus).mockResolvedValue(
      calendar({ meeting: { title: "Design review", until: until.toISOString() } }),
    );
    const { findByText, queryByText } = render(Component);
    expect(await findByText("Design review")).toBeVisible();
    const hh = String(until.getHours()).padStart(2, "0");
    const mm = String(until.getMinutes()).padStart(2, "0");
    expect(await findByText(`· until ${hh}:${mm}`)).toBeVisible();
    expect(await findByText("Breaks paused until the end of your call")).toBeVisible();
    expect(await findByText("Your next break is scheduled after the meeting")).toBeVisible();
    expect(queryByText("Next short break in")).toBeNull();
    expect(queryByText("Waiting for your meeting to end")).toBeNull();
  });

  test("has start a long break now button", async () => {
    const { getByText, emitted } = render(Component);
    await fireEvent.click(getByText("start a long break now", { exact: false }));
    expect(emitted().run[0]).toStrictEqual(["start-long-break"]);
  });

  test("has stop protection button", async () => {
    const { getByText, emitted } = render(Component);
    await fireEvent.click(getByText("stop protection", { exact: false }));
    expect(emitted().run[0]).toStrictEqual(["open-stop-protection"]);
  });

  test("has settings button", async () => {
    const { getByText, emitted } = render(Component);
    await fireEvent.click(getByText("settings", { exact: false }));
    expect(emitted().run[0]).toStrictEqual(["open-settings"]);
  });

  test("has quit button", async () => {
    const { getByText, emitted } = render(Component);
    await fireEvent.click(getByText("quit save my eyes", { exact: false }));
    expect(emitted().run[0]).toStrictEqual(["quit"]);
  });
});
