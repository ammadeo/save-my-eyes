import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";
import { fireEvent, render } from "@testing-library/vue";
import Component from "./ContentBeforeBreak.vue";

vi.mock("@/bridge", () => ({}));

beforeEach(() => vi.useFakeTimers());
afterEach(() => vi.useRealTimers());

describe("components/mac/ContentBeforeBreak.vue", () => {
  test("has skip button, shown once waiting", async () => {
    const { getByText, emitted } = render(Component);
    const skip = getByText("skip a break");
    expect(skip).not.toBeVisible();

    await fireEvent.click(getByText("wait"));
    expect(skip).toBeVisible();

    await fireEvent.click(skip);
    expect(emitted().skip).toHaveLength(1);
  });

  test("has working progressbar", async () => {
    const { getByRole } = render(Component);
    const progressbar = getByRole("progressbar");
    expect(progressbar).toBeVisible();
    expect(progressbar).toHaveAttribute("aria-valuenow", "0");

    await vi.advanceTimersByTimeAsync(1000);
    expect(progressbar).not.toHaveAttribute("aria-valuenow", "0");
  });

  test("has working status text", async () => {
    const { getByText } = render(Component);
    expect(getByText("short break will start in 5 seconds", { exact: false })).toBeVisible();

    await fireEvent.click(getByText("wait"));
    expect(getByText("short break will start when you're ready", { exact: false })).toBeVisible();
  });

  test("names a long break", () => {
    const { getByText } = render(Component, { props: { long: true } });
    expect(getByText("long break will start in 5 seconds", { exact: false })).toBeVisible();
  });

  test("has working wait and proceed button", async () => {
    const { getByText, emitted } = render(Component);

    await fireEvent.click(getByText("wait"));
    expect(emitted().wait).toHaveLength(1);

    await fireEvent.click(getByText("start a break now"));
    expect(emitted().break).toHaveLength(1);
  });

  test("starts the break by itself after 5 seconds", async () => {
    const { emitted } = render(Component);
    await vi.advanceTimersByTimeAsync(4900);
    expect(emitted().break).toBeUndefined();
    await vi.advanceTimersByTimeAsync(200);
    expect(emitted().break).toHaveLength(1);
  });

  test("waiting stops the auto start and shows the waiting time", async () => {
    const { getByText, emitted } = render(Component);
    await fireEvent.click(getByText("wait"));
    await vi.advanceTimersByTimeAsync(2 * 60_000 + 1000);
    expect(emitted().break).toBeUndefined();
    expect(getByText("2 minutes")).toBeVisible();
  });
});
