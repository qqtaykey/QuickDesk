import { createRouter, createWebHashHistory } from 'vue-router'
import { getToken } from '../api/auth.js'
import LoginPage from '../views/LoginPage.vue'
import PresetPage from '../views/PresetPage.vue'

const routes = [
  { path: '/login', name: 'Login', component: LoginPage, meta: { public: true } },
  { path: '/', redirect: '/preset' },
  { path: '/preset', name: 'Preset', component: PresetPage, meta: { title: '预设管理' } }
]

const router = createRouter({
  history: createWebHashHistory(),
  routes
})

router.beforeEach((to) => {
  if (!to.meta.public && !getToken()) {
    return '/login'
  }
})

export default router
