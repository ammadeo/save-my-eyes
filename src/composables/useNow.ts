import { onScopeDispose, ref } from "vue";

/** A `Date.now()` ref refreshed on an interval; cleared with the owning scope. */
export function useNow(intervalMs = 1000) {
  const now = ref(Date.now());
  const id = setInterval(() => (now.value = Date.now()), intervalMs);
  onScopeDispose(() => clearInterval(id));
  return now;
}
