/** Inline SVG icons (`fill:currentColor`), replacing vue-svg-inline-loader. */
const raw = import.meta.glob<string>("./assets/icons/*.svg", { query: "?raw", eager: true, import: "default" });

export const icons: Record<string, string> = Object.fromEntries(
  Object.entries(raw).map(([path, svg]) => [
    path.replace(/^.*\/(.+)\.svg$/, "$1"),
    // drop the XML prolog/doctype; size comes from CSS
    svg.replace(/^[\s\S]*?(?=<svg)/, "").replace(/\s(width|height)="100%"/g, ""),
  ]),
);

export type IconName =
  | "close"
  | "coffee"
  | "finish"
  | "mute"
  | "pause"
  | "settings"
  | "skip"
  | "sound"
  | "start"
  | "stop";
