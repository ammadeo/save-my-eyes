import { computed } from "vue";
import { quitApp, setNextBreak } from "@/bridge";
import { t, useI18n } from "@/i18n";
import { log } from "@/log";

const dict = {
  stopFor: t("Stop protection for", "Wstrzymaj ochronę na"),
  turnOffTitle: t("Turn off protection", "Wyłącz ochronę"),
  turnOffContent: t("Turn off for this session", "Wyłącz podczas tej sesji"),
  turnOffInfo: t("App will start again with your computer", "Aplikacja uruchomi się, gdy ponownie włączysz komputer"),
  hour1: t("1 hour", "1 godzinę"),
  hour2: t("2 hours", "2 godziny"),
  hour3: t("3 hours", "3 godziny"),
};

/** Shared by the menu pane and the break-screen card. */
export function useStopProtection() {
  const i18n = useI18n(dict);
  const options = computed(() =>
    ([1, 2, 3] as const).map((hours) => ({ hours, label: i18n.t(`hour${hours}`) })),
  );

  /** The next break becomes a long one in `hours`; resolves true on success. */
  async function pause(hours: number) {
    try {
      await setNextBreak({ inSecs: hours * 3600, forceType: "long" });
      return true;
    } catch (error) {
      log.error("stop protection failed", error);
      return false;
    }
  }

  async function quit() {
    try {
      await quitApp();
    } catch (error) {
      log.error("quit failed", error);
    }
  }

  return { ...i18n, options, pause, quit };
}
