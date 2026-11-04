import { onMounted, onUnmounted } from "vue";
import { on, type Events } from "@/bridge";

/** Listens to a Rust event while the component is mounted. */
export function useEvent<K extends keyof Events>(event: K, handler: (payload: Events[K]) => void) {
  let unlisten: (() => void) | undefined;
  let alive = true;
  onMounted(async () => {
    const off = await on(event, handler);
    if (alive) unlisten = off;
    else off();
  });
  onUnmounted(() => {
    alive = false;
    unlisten?.();
  });
}
