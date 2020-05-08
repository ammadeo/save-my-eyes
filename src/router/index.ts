import Vue from 'vue'
import VueRouter, { RouteConfig } from 'vue-router'
import Index from '../views/Index.vue'
import Menu from '../views/Menu.vue'

Vue.use(VueRouter)

const routes: Array<RouteConfig> = [
  {
    path: '/',
    name: 'Index',
    component: Index,
  },
  {
    path: '/menu',
    name: 'Menu',
    component: Menu,
  },
]

const router = new VueRouter({
  mode: "hash",
  routes,
})

export default router
