<template>
  <!-- Login page: full screen, no layout -->
  <router-view v-if="isLoginPage" />

  <!-- Admin layout with sidebar -->
  <el-container v-else class="app-container">
    <el-aside width="200px" class="app-aside">
      <div class="logo">
        <h2>QuickDesk</h2>
        <span class="subtitle">管理后台</span>
      </div>
      <el-menu
        :default-active="activeMenu"
        router
        class="app-menu"
      >
        <el-menu-item index="/preset">
          <el-icon><Setting /></el-icon>
          <span>预设管理</span>
        </el-menu-item>
      </el-menu>
      <div class="aside-footer">
        <el-button text class="logout-btn" @click="handleLogout">
          <el-icon><SwitchButton /></el-icon>
          <span>退出登录</span>
        </el-button>
      </div>
    </el-aside>
    <el-container>
      <el-header class="app-header">
        <h3>{{ currentTitle }}</h3>
      </el-header>
      <el-main class="app-main">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { logout } from './api/auth.js'

const route = useRoute()
const router = useRouter()
const activeMenu = computed(() => route.path)
const currentTitle = computed(() => route.meta?.title || '')
const isLoginPage = computed(() => route.name === 'Login')

function handleLogout() {
  logout()
  router.push('/login')
}
</script>

<style>
html, body, #app {
  margin: 0;
  padding: 0;
  height: 100%;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

.app-container {
  height: 100vh;
}

.app-aside {
  background: #1d1e1f;
  border-right: 1px solid #303133;
  display: flex;
  flex-direction: column;
}

.logo {
  padding: 20px 16px;
  border-bottom: 1px solid #303133;
  text-align: center;
}

.logo h2 {
  margin: 0;
  color: #409eff;
  font-size: 20px;
}

.logo .subtitle {
  color: #909399;
  font-size: 12px;
}

.app-menu {
  border-right: none;
  background: transparent;
  flex: 1;
}

.app-menu .el-menu-item {
  color: #c0c4cc;
}

.app-menu .el-menu-item:hover {
  background: #262727;
}

.app-menu .el-menu-item.is-active {
  color: #409eff;
  background: #262727;
}

.aside-footer {
  padding: 12px 16px;
  border-top: 1px solid #303133;
}

.logout-btn {
  color: #909399 !important;
  width: 100%;
  justify-content: flex-start;
}

.logout-btn:hover {
  color: #c0c4cc !important;
}

.app-header {
  display: flex;
  align-items: center;
  border-bottom: 1px solid #e4e7ed;
  background: #fff;
}

.app-header h3 {
  margin: 0;
  font-size: 16px;
  color: #303133;
}

.app-main {
  background: #f5f7fa;
}
</style>
