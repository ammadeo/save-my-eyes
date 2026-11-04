<script setup lang="ts">
import { onMounted, ref } from "vue";
import HeaderTitle from "@/components/brand/HeaderTitle.vue";
import IndexIdea from "@/components/brand/IndexIdea.vue";
import IndexSettings from "@/components/brand/IndexSettings.vue";
import IndexStopProtection from "@/components/brand/IndexStopProtection.vue";
import IndexTimerButton from "@/components/brand/IndexTimerButton.vue";
import TimerClock from "@/components/brand/TimerClock.vue";
import TimerInfo from "@/components/brand/TimerInfo.vue";
import { endBreak, getBreakState, notifyBreakEnded } from "@/bridge";
import { t, useI18n } from "@/i18n";
import { log } from "@/log";
import { settings } from "@/settings";
import { playBreakSound } from "@/sound";

const { t: tl } = useI18n({
  loading: t("We're loading a timer. You can start your break now", "Nakręcamy zegar. Możesz już zacząć przerwę"),
});

const startDate = ref(new Date());
const endDate = ref(new Date());
const long = ref(false);
const ready = ref(false);
const finished = ref(false);
const closing = ref(false);
// Locks (legacy index.vue): an open card pauses the auto-finish; unsaved settings also block closing.
const autoFinishLock = ref(false);
const forceCloseLock = ref(false);
const startCloseLock = ref(true);

function setLocks(to: boolean, forceClose = false) {
  autoFinishLock.value = to;
  if (forceClose || !to) forceCloseLock.value = forceClose ? to : false;
}

onMounted(async () => {
  let isLong = false;
  let lengthSecs = settings.breaks.short.last;
  let startedAt = Date.now();
  try {
    const state = await getBreakState();
    isLong = state.isLong;
    lengthSecs = state.lengthSecs;
    if (state.startedAt) startedAt = Date.parse(state.startedAt);
  } catch {
    // spike / preview: a short break from now with the configured length
  }
  long.value = isLong;
  startDate.value = new Date(startedAt);
  endDate.value = new Date(startedAt + lengthSecs * 1000);
  ready.value = true;
  startCloseLock.value = false;
  await playBreakSound(isLong);
});

async function close() {
  if (closing.value) return;
  closing.value = true;
  try {
    await endBreak();
  } catch (error) {
    log.warn("end_break failed", error);
    closing.value = false;
  }
}

async function onClockFinished() {
  finished.value = true;
  const waitForUser = autoFinishLock.value || long.value;
  if (!waitForUser) {
    await playBreakSound(long.value);
    await close();
    return;
  }
  await notifyBreakEnded().catch(() => {});
  await playBreakSound(long.value);
}
</script>

<template>
  <main
    v-show="!closing"
    class="grid h-screen grow grid-cols-base grid-rows-base overflow-hidden p-cover"
  >
    <HeaderTitle class="col-start-1 col-end-3 row-start-1" />
    <IndexStopProtection
      class="col-start-3 row-start-1"
      :disabled="forceCloseLock"
      @change-auto-finish-lock="setLocks($event)"
    />
    <p v-if="!ready" class="col-start-1 row-start-2 mt-16 max-w-[40ch] text-large-title text-label-secondary">{{ tl("loading") }}</p>
    <template v-else>
      <TimerInfo class="col-start-1 row-start-2 mt-16 mb-4" :long="long" :start-date="startDate" :end-date="endDate" :finished="finished" />
      <TimerClock
        class="col-start-1 row-start-3"
        :auto-finish="!long && !autoFinishLock"
        :start-date="startDate"
        :end-date="endDate"
        @finished="onClockFinished"
      />
      <IndexTimerButton
        class="col-start-3 row-start-3"
        :long="long"
        :finished="finished"
        :disabled="forceCloseLock || startCloseLock"
        @click="close"
      />
    </template>
    <IndexIdea class="col-start-1 row-start-4 self-end" :long="long" :finished="finished" :force-close-lock="forceCloseLock" />
    <IndexSettings
      class="col-start-3 row-start-4"
      @change-auto-finish-lock="setLocks($event)"
      @changed="setLocks(true, true)"
    />
  </main>
</template>
