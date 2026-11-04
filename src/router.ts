import { createRouter, createWebHashHistory } from "vue-router";

declare module "vue-router" {
  interface RouteMeta {
    /** `cover`: full-screen glass cover; `window`: menu or before-break card. */
    surface: "window" | "cover";
  }
}

export const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: "/menu", component: () => import("./views/MenuView.vue"), meta: { surface: "window" } },
    { path: "/before-break", component: () => import("./views/BeforeBreakView.vue"), meta: { surface: "window" } },
    { path: "/break", component: () => import("./views/BreakView.vue"), meta: { surface: "cover" } },
    { path: "/blank", component: () => import("./views/BlankView.vue"), meta: { surface: "cover" } },
    { path: "/:pathMatch(.*)*", redirect: "/break" },
  ],
});

router.afterEach((to) => {
  document.documentElement.dataset.surface = to.meta.surface ?? "cover";
});
