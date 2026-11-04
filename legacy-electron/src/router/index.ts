import Vue from 'vue'
import VueRouter, { RouteConfig } from 'vue-router'
import Index from '../views/index.vue'
import Menu from '../views/Menu.vue'
import Blank from '../views/Blank.vue'
import BeforeBreak from '../views/BeforeBreak.vue'

Vue.use(VueRouter)

const routes: Array<RouteConfig> = [
  {
    path: '/',
    name: 'Index',
    alias: '/index',
    component: Index,
  },
  {
    path: '/BeforeBreak',
    name: 'BeforeBreak',
    component: BeforeBreak,
  },
  {
    path: '/menu',
    name: 'Menu',
    component: Menu,
  },
  {
    path: '/blank',
    name: 'Blank',
    component: Blank,
  },
]

const router = new VueRouter({
  mode: 'hash',
  routes,
})

export default router
