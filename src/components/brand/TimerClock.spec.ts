import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";
import { render } from "@testing-library/vue";
import Component from "./TimerClock.vue";

vi.mock("@/bridge", () => ({}));

const startDate = new Date(2020, 3, 1, 10, 10);
const endDate = new Date(2020, 3, 1, 10, 30);
const props = { startDate, endDate };

beforeEach(() => {
  vi.useFakeTimers();
  vi.setSystemTime(startDate);
});
afterEach(() => vi.useRealTimers());

describe("components/brand/TimerClock.vue", () => {
  test("has working progressbar", async () => {
    const { getByRole } = render(Component, { props });
    const progressbar = getByRole("progressbar");
    expect(progressbar).toBeVisible();
    const drawer = progressbar.children[0];
    expect(drawer).toHaveStyle("transform: translateX(-100%)");

    await vi.advanceTimersByTimeAsync(60_000);
    expect(drawer).not.toHaveStyle("transform: translateX(-100%)");
  });

  test("labels 20 minutes at start as 20 : 00 and counts down", async () => {
    const { getByText } = render(Component, { props });
    expect(getByText("20 : 00")).toBeVisible();
    await vi.advanceTimersByTimeAsync(61_000);
    expect(getByText("18 : 59")).toBeVisible();
  });

  test("sets progress bar aria attributes", () => {
    const { getByRole } = render(Component, { props });
    const progressbar = getByRole("progressbar");
    expect(progressbar).toHaveAttribute("aria-valuenow", "0");
    expect(progressbar).toHaveAttribute("aria-valuemin", "0");
    expect(progressbar).toHaveAttribute("aria-valuemax", "100");
  });

  test("emits finished once at the end", async () => {
    const { emitted, getByText } = render(Component, { props });
    await vi.advanceTimersByTimeAsync(20 * 60_000 - 500);
    expect(emitted().finished).toBeUndefined();
    await vi.advanceTimersByTimeAsync(5_000);
    expect(emitted().finished).toHaveLength(1);
    expect(getByText("00 : 00")).toBeVisible();
  });

  test("follows the wall clock, not mount time (break already running)", () => {
    vi.setSystemTime(new Date(2020, 3, 1, 10, 25));
    const { getByText, getByRole } = render(Component, { props });
    expect(getByText("05 : 00")).toBeVisible();
    expect(getByRole("progressbar")).toHaveAttribute("aria-valuenow", "75");
  });
});
