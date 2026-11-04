/**
 * Console wrapper. In dev it also forwards lines to the Vite server (`/__log`, see
 * vite.config.ts) so webview logs show up in the `tauri dev` terminal.
 */
type Level = "info" | "warn" | "error";

const label = () => (typeof location !== "undefined" ? location.hash || "#/" : "");

function forward(level: Level, args: unknown[]) {
  if (!import.meta.env.DEV || import.meta.env.MODE === "test") return;
  const text = args
    .map((a) => (a instanceof Error ? `${a.name}: ${a.message}` : typeof a === "string" ? a : safeJson(a)))
    .join(" ");
  fetch("/__log", { method: "POST", body: `${level} ${label()} ${text}` }).catch(() => {});
}

function safeJson(value: unknown) {
  try {
    return JSON.stringify(value);
  } catch {
    return String(value);
  }
}

export const log = {
  info: (...args: unknown[]) => {
    console.info(...args);
    forward("info", args);
  },
  warn: (...args: unknown[]) => {
    console.warn(...args);
    forward("warn", args);
  },
  error: (...args: unknown[]) => {
    console.error(...args);
    forward("error", args);
  },
};
