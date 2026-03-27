import { createRouter, createWebHashHistory } from 'vue-router'
import RemotePage from '../views/RemotePage.vue'
import DevicesPage from '../views/DevicesPage.vue'
import AccountPage from '../views/AccountPage.vue'
import SettingsPage from '../views/SettingsPage.vue'
import AboutPage from '../views/AboutPage.vue'

const routes = [
  { path: '/', redirect: '/remote' },
  { path: '/remote', component: RemotePage },
  { path: '/devices', component: DevicesPage },
  { path: '/account', component: AccountPage },
  { path: '/settings', component: SettingsPage },
  { path: '/about', component: AboutPage },
]

export default createRouter({
  history: createWebHashHistory(),
  routes,
})
