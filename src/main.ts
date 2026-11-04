import { createApp } from "vue";
import App from "./App.vue";
import { router } from "./router";
import { initSettings } from "./settings";
import "./css/main.css";

// Paint the right window surface before anything mounts (no brand flash in the menu).
document.documentElement.dataset.surface = /^#\/(menu|before-break)\b/.test(location.hash) ? "mac" : "brand";

// Settings first (inventory risk #5): views read them synchronously.
await initSettings();

createApp(App).use(router).mount("#app");
