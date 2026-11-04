import { computed, onScopeDispose, ref, toValue, watch, type MaybeRefOrGetter } from "vue";

/**
 * Date-based countdown (replaces the animejs tween). Progress is derived from
 * `Date.now()` on a 250 ms interval, so it stays correct if the webview is throttled
 * or hidden. `onDone` fires once when `end` is reached.
 */
export function useCountdown(
  start: MaybeRefOrGetter<number>,
  end: MaybeRefOrGetter<number>,
  onDone?: () => void,
  tickMs = 250,
) {
  const now = ref(Date.now());
  const total = computed(() => Math.max(0, toValue(end) - toValue(start)));
  const elapsed = computed(() => Math.min(total.value, Math.max(0, now.value - toValue(start))));
  const remaining = computed(() => total.value - elapsed.value);
  const done = computed(() => remaining.value <= 0);

  let id: ReturnType<typeof setInterval> | undefined = setInterval(() => (now.value = Date.now()), tickMs);
  const stop = () => {
    if (id !== undefined) clearInterval(id);
    id = undefined;
  };

  let fired = false;
  watch(
    done,
    (isDone) => {
      if (isDone && !fired) {
        fired = true;
        stop();
        onDone?.();
      }
    },
    { immediate: true, flush: "post" },
  );

  onScopeDispose(stop);
  return { now, total, elapsed, remaining, done, stop };
}
