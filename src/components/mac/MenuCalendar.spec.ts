import { beforeEach, describe, expect, test, vi } from "vitest";
import { fireEvent, render } from "@testing-library/vue";
import Component from "./MenuCalendar.vue";
import { getCalendarStatus, openCalendarPrivacy, setCalendarEnabled, type CalendarStatus } from "@/bridge";

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
  vi.mocked(getCalendarStatus).mockResolvedValue(status());
  vi.mocked(setCalendarEnabled).mockReset();
});

describe("components/mac/MenuCalendar.vue", () => {
  test("turning it on asks Rust right away", async () => {
    vi.mocked(setCalendarEnabled).mockResolvedValue(status({ enabled: true, access: "granted" }));
    const { findByRole } = render(Component);
    const toggle = await findByRole("switch");
    expect(toggle).not.toBeChecked();
    await fireEvent.click(toggle);
    expect(setCalendarEnabled).toHaveBeenCalledWith(true);
    expect(await findByRole("switch")).toBeChecked();
  });

  test("explains denied access and links to Privacy settings", async () => {
    vi.mocked(getCalendarStatus).mockResolvedValue(status({ enabled: true, access: "denied" }));
    const { findByText } = render(Component);
    expect(await findByText("Save My Eyes has no access to your calendar.")).toBeVisible();
    await fireEvent.click(await findByText("Open Privacy Settings…"));
    expect(openCalendarPrivacy).toHaveBeenCalled();
  });

  test("asks again when on but access was never granted", async () => {
    vi.mocked(getCalendarStatus).mockResolvedValue(status({ enabled: true, access: "notDetermined" }));
    vi.mocked(setCalendarEnabled).mockResolvedValue(status({ enabled: true, access: "granted" }));
    const { findByText, queryByText } = render(Component);
    await fireEvent.click(await findByText("Allow…"));
    expect(setCalendarEnabled).toHaveBeenCalledWith(true);
    await vi.waitFor(() => expect(queryByText("Calendar access is needed.")).toBeNull());
  });

  test("hidden outside macOS", async () => {
    vi.mocked(getCalendarStatus).mockResolvedValue(status({ access: "unsupported" }));
    const { queryByRole } = render(Component);
    await vi.waitFor(() => expect(queryByRole("switch")).toBeNull());
  });
});
