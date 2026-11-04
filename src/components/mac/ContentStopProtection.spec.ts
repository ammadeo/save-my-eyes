import { beforeEach, describe, expect, test, vi } from "vitest";
import { fireEvent, render, waitFor } from "@testing-library/vue";
import Component from "./ContentStopProtection.vue";
import { quitApp, setNextBreak } from "@/bridge";

vi.mock("@/bridge", () => ({
  setNextBreak: vi.fn(async () => ({})),
  quitApp: vi.fn(async () => {}),
}));

beforeEach(() => vi.clearAllMocks());

describe("components/mac/ContentStopProtection.vue", () => {
  test("has break timeout buttons", () => {
    const { getByText } = render(Component);
    for (const text of ["1 hour", "2 hours", "3 hours"]) expect(getByText(text)).toBeVisible();
  });

  test("has close app button", () => {
    const { getByText } = render(Component);
    expect(getByText("for this session", { exact: false })).toBeVisible();
  });

  test("has working close app button", async () => {
    const { getByTestId } = render(Component);
    await fireEvent.click(getByTestId("button-close-app"));
    expect(quitApp).toHaveBeenCalledTimes(1);
  });

  test("has working break timeout buttons", async () => {
    const { getAllByTestId, emitted } = render(Component);
    await fireEvent.click(getAllByTestId("button-pause-break")[0]);
    expect(setNextBreak).toHaveBeenCalledWith({ inSecs: 60 * 60, forceType: "long" });
    await waitFor(() => expect(emitted().close).toBeTruthy());

    await fireEvent.click(getAllByTestId("button-pause-break")[2]);
    expect(setNextBreak).toHaveBeenLastCalledWith({ inSecs: 3 * 60 * 60, forceType: "long" });
  });

  test("stays open when the command fails", async () => {
    vi.mocked(setNextBreak).mockRejectedValueOnce(new Error("no command"));
    vi.spyOn(console, "error").mockImplementation(() => {});
    const { getAllByTestId, emitted } = render(Component);
    await fireEvent.click(getAllByTestId("button-pause-break")[1]);
    await waitFor(() => expect(setNextBreak).toHaveBeenCalled());
    expect(emitted().close).toBeUndefined();
  });
});
