import { createRouter, createWebHashHistory } from "vue-router";

declare module "vue-router" {
  interface RouteMeta {
    /** `brand`: branded full-screen cover; `mac`: native-looking window. */
    surface: "brand" | "mac";
  }
}

export const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: "/menu", component: () => import("./views/MenuView.vue"), meta: { surface: "mac" } },
    { path: "/before-break", component: () => import("./views/BeforeBreakView.vue"), meta: { surface: "mac" } },
    { path: "/break", component: () => import("./views/BreakView.vue"), meta: { surface: "brand" } },
    { path: "/blank", component: () => import("./views/BlankView.vue"), meta: { surface: "brand" } },
    { path: "/:pathMatch(.*)*", redirect: "/break" },
  ],
});

router.afterEach((to) => {
  document.documentElement.dataset.surface = to.meta.surface ?? "brand";
});
