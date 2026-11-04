<script setup lang="ts">
import { computed, onUnmounted, ref } from "vue";
import { formatDistanceStrict } from "date-fns";
import appIcon from "@/assets/app-icon.png";
import { useCountdown } from "@/composables/useCountdown";
import { dateLocale, lang, t, useI18n } from "@/i18n";

const props = withDefaults(defineProps<{ long?: boolean; autoStartMs?: number }>(), {
  long: false,
  autoStartMs: 5000,
});
const emit = defineEmits<{ break: []; skip: []; wait: [] }>();

const { t: tl, tg } = useI18n({
  contentStart: t("start a break now", "rozpocznij przerwę teraz"),
  contentWait: t("wait", "zaczekaj chwilę"),
  contentSkip: t("skip a break", "pomiń przerwę"),
  contentBase: t("will start", "zacznie się"),
  statusWaiting: t("when you're ready", "kiedy zechcesz"),
  statusStarting: t("in 5 seconds", "za 5 sekund"),
  waitingPrefix: t("You're waiting for", "Czekasz już"),
});

const start = Date.now();
const waiting = ref(false);
const waitingFrom = ref(0);
const waitingInfo = ref("");
let waitingTimer: ReturnType<typeof setInterval> | undefined;

const countdown = useCountdown(start, start + props.autoStartMs, () => {
  if (!waiting.value) emit("break");
});
const percent = computed(() => (countdown.elapsed.value / countdown.total.value) * 100);

const status = computed(
  () => `${props.long ? tg("breakLong") : tg("breakShort")} ${tl("contentBase")} ${waiting.value ? tl("statusWaiting") : tl("statusStarting")}`,
);

function updateWaitingInfo() {
  const now = Date.now();
  if (now - waitingFrom.value < 60_000) return;
  let info = formatDistanceStrict(waitingFrom.value, now, { roundingMethod: "floor", locale: dateLocale.value });
  if (lang.value === "pl" && info.includes("minuta")) info = "minutę";
  waitingInfo.value = info;
}

function onPrimary() {
  if (waiting.value) return emit("break");
  waiting.value = true;
  countdown.stop();
  waitingFrom.value = Date.now();
  waitingTimer = setInterval(updateWaitingInfo, 60_000);
  emit("wait");
}

onUnmounted(() => clearInterval(waitingTimer));
</script>

<template>
  <article class="banner" :class="{ 'is-waiting': waiting }" aria-live="polite">
    <img class="banner-icon" :src="appIcon" alt="" />
    <div class="banner-body">
      <h1 class="banner-title text-headline">{{ tg("title") }}</h1>
      <p class="banner-text first-letter:uppercase">{{ status }}</p>
      <p v-show="waitingInfo" class="banner-sub">
        {{ tl("waitingPrefix") }} <span class="font-medium">{{ waitingInfo }}</span>
      </p>
      <div class="banner-actions">
        <div
          v-show="!waiting"
          class="glass-progress banner-progress"
          role="progressbar"
          :aria-valuenow="Math.round(percent)"
          aria-valuemin="0"
          aria-valuemax="100"
        >
          <div class="glass-progress-bar" :style="{ width: `${percent}%` }" />
        </div>
        <button v-show="waiting" type="button" class="glass-button" @click="emit('skip')">
          <span class="cap">{{ tl("contentSkip") }}</span>
        </button>
        <button type="button" class="glass-button" :class="{ 'is-primary': waiting }" @click="onPrimary">
          <span class="cap">{{ waiting ? tl("contentStart") : tl("contentWait") }}</span>
        </button>
      </div>
    </div>
  </article>
</template>

<style scoped>
/* No background: the native glass paints the card (18px native corners). */
.banner {
  box-sizing: border-box;
  display: flex;
  gap: 12px;
  height: 100vh;
  padding: 14px;
  border-radius: var(--radius-panel);
  color: var(--label);
}
.banner-icon {
  width: 32px;
  height: 32px;
  flex-shrink: 0;
}
.banner-body {
  display: flex;
  flex: 1;
  min-width: 0;
  flex-direction: column;
}
.banner-title {
  margin: 0;
}
.banner-text {
  margin: 2px 0 0;
}
.banner-sub {
  margin: 2px 0 0;
  color: var(--label-secondary);
}
.banner-actions {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 8px;
  margin-top: auto;
}
.banner-progress {
  flex: 1;
}
.cap {
  display: inline-block;
}
.cap::first-letter {
  text-transform: uppercase;
}

/* After a minute of waiting the card breathes a faint sage tint over the glass. */
.is-waiting {
  animation: banner-pulse 1s ease-in 60s infinite alternate;
}
@keyframes banner-pulse {
  to {
    background: color-mix(in oklch, var(--accent) 14%, transparent);
  }
}
@media (prefers-reduced-motion: reduce) {
  .is-waiting {
    animation: none;
  }
}
</style>
