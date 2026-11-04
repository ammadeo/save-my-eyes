import { createApp } from "vue";
import App from "./App.vue";
import { router } from "./router";
import { initSettings } from "./settings";
import "./css/main.css";

// Density hint for the window kind, set before anything mounts.
document.documentElement.dataset.surface = /^#\/(menu|before-break)\b/.test(location.hash) ? "window" : "cover";

// Settings first (inventory risk #5): views read them synchronously.
await initSettings();

createApp(App).use(router).mount("#app");
