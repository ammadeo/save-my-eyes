import { beforeEach, describe, expect, test, vi } from "vitest";
import { fireEvent, render } from "@testing-library/vue";
import Component from "./MenuCalendar.vue";
import { getCalendarStatus, openCalendarPrivacy, setCalendarEnabled, type CalendarStatus } from "@/bridge";
import { setLang } from "@/i18n";

vi.mock("@/bridge", () => ({
  getCalendarStatus: vi.fn(),
  setCalendarEnabled: vi.fn(),
  openCalendarPrivacy: vi.fn(async () => {}),
  getSettings: vi.fn(),
  on: vi.fn(async () => () => {}),
}));

const status = (patch: Partial<CalendarStatus> = {}): CalendarStatus => ({
  enabled: false,
  access: "notDetermined",
  meeting: null,
  syncedAt: null,
  ...patch,
});

beforeEach(() => {
  setLang("en");
  vi.mocked(getCalendarStatus).mockResolvedValue(status());
  vi.mocked(setCalendarEnabled).mockReset();
});

describe("components/mac/MenuCalendar.vue", () => {
  test("turning it on asks Rust right away", async () => {
    vi.mocked(setCalendarEnabled).mockResolvedValue(status({ enabled: true, access: "granted" }));
    const { findByRole } = render(Component, { props: { modelValue: 60 } });
    const toggle = await findByRole("switch");
    expect(toggle).not.toBeChecked();
    await fireEvent.click(toggle);
    expect(setCalendarEnabled).toHaveBeenCalledWith(true);
    expect(await findByRole("switch")).toBeChecked();
  });

  test("explains denied access and links to Privacy settings", async () => {
    vi.mocked(getCalendarStatus).mockResolvedValue(status({ enabled: true, access: "denied" }));
    const { findByText } = render(Component, { props: { modelValue: 60 } });
    expect(await findByText("Save My Eyes has no access to your calendar.")).toBeVisible();
    await fireEvent.click(await findByText("Open Privacy Settings…"));
    expect(openCalendarPrivacy).toHaveBeenCalled();
  });

  test("asks again when on but access was never granted", async () => {
    vi.mocked(getCalendarStatus).mockResolvedValue(status({ enabled: true, access: "notDetermined" }));
    vi.mocked(setCalendarEnabled).mockResolvedValue(status({ enabled: true, access: "granted" }));
    const { findByText, queryByText } = render(Component, { props: { modelValue: 60 } });
    await fireEvent.click(await findByText("Allow…"));
    expect(setCalendarEnabled).toHaveBeenCalledWith(true);
    await vi.waitFor(() => expect(queryByText("Calendar access is needed.")).toBeNull());
  });

  test("hidden outside macOS", async () => {
    vi.mocked(getCalendarStatus).mockResolvedValue(status({ access: "unsupported" }));
    const { queryByRole } = render(Component, { props: { modelValue: 60 } });
    await vi.waitFor(() => expect(queryByRole("switch")).toBeNull());
  });

  test("pause-after-call slider shows minutes and emits seconds", async () => {
    const { findByLabelText, getByText, emitted } = render(Component, { props: { modelValue: 60 } });
    const slider = await findByLabelText("Pause breaks after a call ends");
    expect(slider).toHaveAttribute("min", "0");
    expect(slider).toHaveAttribute("max", "15");
    expect(slider).toHaveValue("1");
    expect(getByText("1 min.", { normalizer: (s) => s.replace(/\s+/g, " ").trim() })).toBeVisible();
    await fireEvent.update(slider, "5");
    expect(emitted("update:modelValue")).toEqual([[300]]);
    expect(setCalendarEnabled).not.toHaveBeenCalled();
  });

  test("pause-after-call slider reads Immediately at 0, in both languages", async () => {
    const { findByText, rerender } = render(Component, { props: { modelValue: 0 } });
    expect(await findByText("Immediately")).toBeVisible();
    setLang("pl");
    await rerender({ modelValue: 0 });
    expect(await findByText("Od razu")).toBeVisible();
    expect(await findByText("Wstrzymaj przerwy po zakończeniu rozmowy")).toBeVisible();
  });

  test("hint no longer promises a fixed minute", async () => {
    const { findByText } = render(Component, { props: { modelValue: 60 } });
    expect(await findByText(/waits until the event ends/)).toBeVisible();
  });
});
