<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref, watch } from "vue";
import ContentMenu from "@/components/mac/ContentMenu.vue";
import type { RunKey } from "@/components/mac/types";
import ContentStopProtection from "@/components/mac/ContentStopProtection.vue";
import MenuSettings from "@/components/mac/MenuSettings.vue";
import { closeWindow, openUrl, quitApp, setNextBreak, setWindowHeight } from "@/bridge";
import { t, useI18n } from "@/i18n";
import { log } from "@/log";

type Pane = "menu" | "settings" | "stop-protection";

const { t: tl, tg } = useI18n({
  settings: t("Settings", "Ustawienia"),
  stopProtection: t("Stop protection", "Wstrzymaj ochronę"),
  back: t("Back", "Wstecz"),
});

// Dev aid: `#/menu?pane=settings` opens straight at a pane (see SME_DEV_OPEN_MENU).
const initialPane = new URLSearchParams(location.hash.split("?")[1] ?? "").get("pane");
const pane = ref<Pane>(initialPane === "settings" || initialPane === "stop-protection" ? initialPane : "menu");
const direction = ref<"pane-forward" | "pane-back">("pane-forward");
const title = computed(() =>
  pane.value === "settings" ? tl("settings") : pane.value === "stop-protection" ? tl("stopProtection") : tg("title"),
);

/** The window grows and shrinks with its pane so no pane floats in empty glass. */
const paneHeight: Record<Pane, number> = { menu: 352, settings: 500, "stop-protection": 300 };

function open(next: Pane) {
  direction.value = next === "menu" ? "pane-back" : "pane-forward";
  pane.value = next;
}
watch(pane, (p) => setWindowHeight(paneHeight[p]), { immediate: true });

async function run(key: RunKey) {
  try {
    switch (key) {
      case "start-long-break":
        await setNextBreak({ inSecs: 0, forceType: "long", skipBeforeBreak: true });
        return closeWindow();
      case "open-stop-protection":
        return open("stop-protection");
      case "open-settings":
        return open("settings");
      case "coffee":
        return openUrl("https://buymeacoffee.com/ammadeo");
      case "quit":
        return quitApp();
    }
  } catch (error) {
    log.error(`menu: ${key} failed`, error);
  }
}

function onKey(event: KeyboardEvent) {
  if (event.key === "Escape") closeWindow();
}
onMounted(() => window.addEventListener("keydown", onKey));
onUnmounted(() => window.removeEventListener("keydown", onKey));
</script>

<template>
  <div class="menu-window">
    <!-- Overlay title bar: native traffic lights sit at the top-left of this strip. -->
    <header class="toolbar" data-tauri-drag-region>
      <button
        v-if="pane !== 'menu'"
        type="button"
        class="glass-button is-plain back"
        :aria-label="tl('back')"
        @click="open('menu')"
      >
        <svg viewBox="0 0 10 16" width="8" height="13" aria-hidden="true">
          <path d="M8.5 1.5 2 8l6.5 6.5" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
        </svg>
      </button>
      <h1 class="toolbar-title text-headline" data-tauri-drag-region>{{ title }}</h1>
    </header>
    <main class="content">
      <Transition :name="direction" mode="out-in">
        <ContentMenu v-if="pane === 'menu'" key="menu" @run="run" />
        <MenuSettings v-else-if="pane === 'settings'" key="settings" />
        <ContentStopProtection v-else key="stop-protection" @close="closeWindow()" />
      </Transition>
    </main>
  </div>
</template>

<style scoped>
/* No background: the native glass paints the window. */
.menu-window {
  display: flex;
  flex-direction: column;
  height: 100vh;
}
.toolbar {
  position: relative;
  flex-shrink: 0;
  height: 52px;
  display: flex;
  /* Align with the default Overlay traffic lights (centred ~16 px from the top). */
  align-items: flex-start;
  padding-top: 4px;
  padding-left: 78px; /* traffic lights */
  padding-right: 16px;
  box-sizing: border-box;
}
.toolbar-title {
  position: absolute;
  top: 4px;
  left: 50%;
  transform: translateX(-50%);
  margin: 0;
  line-height: 24px;
  color: var(--label);
  white-space: nowrap;
}
.back {
  width: 28px;
  padding: 0;
}
.content {
  flex: 1;
  overflow-y: auto;
  overflow-x: hidden;
  padding: 0 16px 16px;
}
</style>
