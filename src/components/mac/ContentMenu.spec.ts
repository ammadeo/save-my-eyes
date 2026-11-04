import { beforeEach, describe, expect, test, vi } from "vitest";
import { fireEvent, render } from "@testing-library/vue";
import Component from "./ContentMenu.vue";
import { getBreakState, type BreakState } from "@/bridge";

vi.mock("@/bridge", () => ({
  getBreakState: vi.fn(),
  on: vi.fn(async () => () => {}),
}));

const state = (patch: Partial<BreakState> = {}): BreakState => ({
  breakIndex: 1,
  isLong: false,
  phase: "idle",
  scheduledAt: new Date(Date.now() + 20 * 60 * 1000).toISOString(),
  lengthSecs: 20,
  startedAt: null,
  ...patch,
});

beforeEach(() => vi.mocked(getBreakState).mockResolvedValue(state()));

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
