import Vue from 'vue'
import VueRouter, { RouteConfig } from 'vue-router'
import Index from '../views/Index.vue'
import Tray from '../views/Tray.vue'

Vue.use(VueRouter)

const routes: Array<RouteConfig> = [
  {
    path: '/',
    name: 'Index',
    component: Index
  },
  {
    path: '/tray',
    name: 'Tray',
    component: Tray
  }
]

const router = new VueRouter({
  routes
})

export default router
