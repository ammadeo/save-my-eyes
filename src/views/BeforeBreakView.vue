<script setup lang="ts">
import { onMounted, ref } from "vue";
import ContentBeforeBreak from "@/components/mac/ContentBeforeBreak.vue";
import { closeWindow, getBreakState, startBreak } from "@/bridge";
import { useWindowFit } from "@/composables/useWindowFit";
import { log } from "@/log";

const long = ref(false);
let started = false;
const card = ref<InstanceType<typeof ContentBeforeBreak>>();
const { track: fitWindow } = useWindowFit();

onMounted(async () => {
  fitWindow(card.value?.$el);
  try {
    long.value = (await getBreakState()).isLong;
  } catch {
    // keep "short"
  }
});

async function start() {
  if (started) return;
  started = true;
  try {
    await startBreak(); // Rust closes this window and opens the break + covers
  } catch (error) {
    log.warn("start_break failed", error);
    started = false;
  }
}

// While the phase is 'before', closing this window counts as Skip on the Rust side.
const skip = () => closeWindow();
</script>

<template>
  <ContentBeforeBreak ref="card" :long="long" @break="start" @skip="skip" />
</template>
