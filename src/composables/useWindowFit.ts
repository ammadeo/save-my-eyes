import { onUnmounted } from "vue";
import { setWindowHeight } from "@/bridge";

/**
 * Keeps the native window as tall as its content: `track(el)` sizes the window to
 * `el` (+ `extra` px of chrome) now and whenever `el` resizes (a notice appears, a
 * Polish string wraps). Windows are anchored top-right, so they grow downwards.
 */
export function useWindowFit(extra = 0) {
  let observer: ResizeObserver | undefined;

  const fit = (el: Element | null | undefined) => {
    if (el instanceof HTMLElement) setWindowHeight(Math.ceil(el.offsetHeight) + extra);
  };

  const track = (el: Element | null | undefined) => {
    observer?.disconnect();
    observer = undefined;
    if (!(el instanceof HTMLElement)) return;
    if (typeof ResizeObserver !== "undefined") {
      observer = new ResizeObserver(() => fit(el));
      observer.observe(el);
    }
    fit(el);
  };

  onUnmounted(() => observer?.disconnect());
  return { fit, track };
}
