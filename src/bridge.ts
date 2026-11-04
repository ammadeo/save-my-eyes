/**
 * The only module that talks to Tauri. Components import from here, tests mock it.
 *
 * Commands reject when the Rust side does not implement them (e.g. the Phase 0 spike)
 * or when the page runs outside Tauri (browser preview). Each failing command is
 * logged once; callers catch and keep their defaults.
 */
import { invoke } from "@tauri-apps/api/core";
import { listen, type UnlistenFn } from "@tauri-apps/api/event";
import { getCurrentWindow, LogicalSize } from "@tauri-apps/api/window";
import { openUrl as tauriOpenUrl } from "@tauri-apps/plugin-opener";
import { log } from "./log";

export type Lang = "en" | "pl";

export interface Settings {
  breaks: {
    every: number;
    short: { last: number };
    long: { last: number; every: number };
  };
  sounds: { ui: boolean; voice: boolean };
  lang: Lang;
}

export type FixCode = "shortEvery" | "shortLast" | "longEvery" | "longLast";

export interface Fix {
  code: FixCode;
  from: number;
  to: number;
}

export type Phase = "idle" | "before" | "active";

export interface BreakState {
  breakIndex: number;
  isLong: boolean;
  phase: Phase;
  scheduledAt: string | null;
  lengthSecs: number;
  startedAt: string | null;
}

export interface NextBreakOptions {
  inSecs?: number;
  forceType?: "long" | "short";
  skipBeforeBreak?: boolean;
  keepWindows?: boolean;
}

export interface Events {
  "settings-changed": Settings;
  "break-state": BreakState;
  "break-ended": Record<string, never>;
}

const isTauri = () => typeof window !== "undefined" && "__TAURI_INTERNALS__" in window;

const failed = new Set<string>();

async function call<T>(cmd: string, args?: Record<string, unknown>): Promise<T> {
  try {
    if (!isTauri()) throw new Error("not running inside Tauri");
    return await invoke<T>(cmd, args);
  } catch (error) {
    if (!failed.has(cmd)) {
      failed.add(cmd);
      log.warn(`bridge: ${cmd} failed, keeping defaults`, error);
    }
    throw error;
  }
}

export const getSettings = () => call<Settings>("get_settings");
export const setSettings = (settings: Settings) =>
  call<{ settings: Settings; fixes: Fix[] }>("set_settings", { settings });
export const getBreakState = () => call<BreakState>("get_break_state");
export const setNextBreak = (opts: NextBreakOptions = {}) =>
  call<BreakState>("set_next_break", { opts });
export const startBreak = () => call<BreakState>("start_break");
export const notifyBreakEnded = () => call<void>("notify_break_ended");
export const endBreak = () => call<BreakState>("end_break");
export const quitApp = () => call<void>("quit_app");

/** Closes the calling window via Rust; falls back to the window API if the command is missing. */
export async function closeWindow(): Promise<void> {
  try {
    await call<void>("close_window");
  } catch {
    if (isTauri()) await getCurrentWindow().close().catch(() => {});
  }
}

/** Resizes the calling window to `height` logical px, keeping its width (no-op outside Tauri). */
export async function setWindowHeight(height: number): Promise<void> {
  if (!isTauri()) return;
  try {
    const w = getCurrentWindow();
    const scale = await w.scaleFactor();
    const { width } = (await w.innerSize()).toLogical(scale);
    await w.setSize(new LogicalSize(width, height));
  } catch (error) {
    log.warn("bridge: setWindowHeight failed", error);
  }
}

export async function openUrl(url: string): Promise<void> {
  if (!isTauri()) {
    window.open(url, "_blank", "noopener");
    return;
  }
  try {
    await tauriOpenUrl(url);
  } catch (error) {
    log.warn("bridge: openUrl failed", error);
  }
}

/** Subscribes to a Rust event. Returns an unlisten function (no-op outside Tauri). */
export async function on<K extends keyof Events>(
  event: K,
  handler: (payload: Events[K]) => void,
): Promise<UnlistenFn> {
  if (!isTauri()) return () => {};
  try {
    return await listen<Events[K]>(event, (e) => handler(e.payload));
  } catch (error) {
    log.warn(`bridge: listen ${event} failed`, error);
    return () => {};
  }
}
