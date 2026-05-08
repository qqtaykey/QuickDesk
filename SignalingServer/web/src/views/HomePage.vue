<template>
  <div class="home-page" v-loading="loading">
    <div class="page-header">
      <h2>{{ t('dashboard.title') }}</h2>
      <el-button
        type="primary"
        size="small"
        @click="loadStats"
        :icon="Refresh"
      >
        {{ t('dashboard.refreshData') }}
      </el-button>
    </div>

    <!-- 概览卡片 -->
    <div class="overview-cards">
      <div class="overview-card purple">
        <div class="overview-icon">
          <el-icon><Monitor /></el-icon>
        </div>
        <div class="overview-content">
          <div class="overview-value">{{ overview.totalDevices }}</div>
          <div class="overview-label">{{ t('dashboard.totalDevices') }}</div>
          <div class="overview-desc">{{ t('dashboard.totalDevicesDesc') }}</div>
        </div>
      </div>
      <div class="overview-card blue">
        <div class="overview-icon">
          <el-icon><Connection /></el-icon>
        </div>
        <div class="overview-content">
          <div class="overview-value">{{ overview.totalConnections }}</div>
          <div class="overview-label">{{ t('dashboard.totalConnections') }}</div>
          <div class="overview-desc">{{ t('dashboard.totalConnectionsDesc') }}</div>
        </div>
      </div>
      <div class="overview-card green">
        <div class="overview-icon">
          <el-icon><Connection /></el-icon>
        </div>
        <div class="overview-content">
          <div class="overview-value">{{ overview.webSocketConnections }}</div>
          <div class="overview-label">{{ t('dashboard.wsConnections') }}</div>
          <div class="overview-desc">{{ t('dashboard.wsConnectionsDesc') }}</div>
        </div>
      </div>
      <div class="overview-card orange">
        <div class="overview-icon">
          <el-icon><DataLine /></el-icon>
        </div>
        <div class="overview-content">
          <div class="overview-value">{{ overview.apiRequests }}</div>
          <div class="overview-label">{{ t('dashboard.apiRequests') }}</div>
          <div class="overview-desc">{{ t('dashboard.apiRequestsDesc') }}</div>
        </div>
      </div>
    </div>

    <!-- 最近活动表格 -->
    <el-card class="activity-card" style="margin-top: 20px;">
      <template #header>
        <div class="card-header">
          <el-icon class="card-icon"><Timer /></el-icon>
          <span>{{ t('dashboard.recentActivity') }}</span>
          <el-button
            type="primary"
            size="small"
            @click="loadActivity"
            :icon="Refresh"
          >
            {{ t('common.refresh') }}
          </el-button>
        </div>
      </template>
      <el-table :data="activityList" stripe style="width: 100%" :row-class-name="rowClassName">
        <el-table-column prop="time" :label="t('dashboard.time')" width="180" />
        <el-table-column prop="deviceId" :label="t('dashboard.deviceId')" width="120" />
        <el-table-column prop="action" :label="t('dashboard.activity')" width="150" />
        <el-table-column prop="details" :label="t('dashboard.details')" show-overflow-tooltip />
        <el-table-column prop="status" :label="t('common.status')" width="100">
          <template #default="{ row }">
            <el-tag :type="row.status === 'success' ? 'success' : 'warning'" size="small">
              {{ row.status === 'success' ? t('common.success') : t('common.failed') }}
            </el-tag>
          </template>
        </el-table-column>
      </el-table>
      <div v-if="activityList.length === 0 && !loading" class="empty-state">
        <el-empty :description="t('dashboard.noActivity')" />
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { ElMessage } from 'element-plus'
import { Monitor, Connection, Timer, Refresh, DataLine } from '@element-plus/icons-vue'
import { getStats, getSystemStatus, getConnectionStatus, getActivity } from '../api/stats.js'

const { t } = useI18n()
const loading = ref(false)

const overview = ref({
  totalDevices: 0,
  totalConnections: 0,
  webSocketConnections: 0,
  apiRequests: 0
})

const stats = ref({
  totalDevices: 0,
  onlineDevices: 0,
  offlineDevices: 0,
  onlineRate: 0
})

const systemStatus = ref({
  status: 'online',
  statusText: 'Running',
  uptime: '00:00:00',
  apiVersion: 'v1',
  dbStatus: 'connected',
  dbStatusText: 'Connected',
  cpu: '0%',
  memory: '0%',
  disk: '0%',
  network: 'Unknown',
  systemVersion: 'Unknown',
  ip: 'Unknown',
  uploadSpeed: 0,
  downloadSpeed: 0,
  uploadTotal: 0,
  downloadTotal: 0
})

const connectionStatus = ref({
  currentConnections: 0,
  todayConnections: 0,
  webSocketConnections: 0,
  apiRequests: 0
})

const activityList = ref([])

function rowClassName({ row }) {
  return row.status === 'success' ? 'success-row' : 'failed-row'
}

async function loadActivity() {
  loading.value = true
  try {
    const data = await getActivity()
    activityList.value = data.activity || []
    ElMessage.success(t('dashboard.activityUpdated'))
  } catch (e) {
    ElMessage.error(t('dashboard.activityFailed') + ': ' + e.message)
  } finally {
    loading.value = false
  }
}

async function loadStats() {
  loading.value = true
  try {
    const [statsData, systemData, connectionData] = await Promise.all([
      getStats(),
      getSystemStatus(),
      getConnectionStatus()
    ])
    stats.value = statsData
    systemStatus.value = systemData
    connectionStatus.value = connectionData
    updateOverview(systemData)
    ElMessage.success(t('dashboard.statsUpdated'))
  } catch (e) {
    ElMessage.error(t('dashboard.statsFailed') + ': ' + e.message)
  } finally {
    loading.value = false
  }
}

function updateOverview(systemData) {
  overview.value.totalDevices = stats.value.totalDevices || 0
  overview.value.totalConnections = connectionStatus.value.currentConnections || 0
  overview.value.webSocketConnections = connectionStatus.value.webSocketConnections || 0
  overview.value.apiRequests = connectionStatus.value.apiRequests || 0
}

let systemStatusTimer = null

async function refreshSystemStatus() {
  try {
    const [systemData, connectionData] = await Promise.all([
      getSystemStatus(),
      getConnectionStatus()
    ])
    systemStatus.value = systemData
    connectionStatus.value = connectionData
    updateOverview(systemData)
  } catch (e) {
    console.error('Failed to refresh system status:', e.message)
  }
}

function startSystemStatusAutoRefresh() {
  if (systemStatusTimer) clearInterval(systemStatusTimer)
  systemStatusTimer = setInterval(refreshSystemStatus, 5000)
}

function stopSystemStatusAutoRefresh() {
  if (systemStatusTimer) {
    clearInterval(systemStatusTimer)
    systemStatusTimer = null
  }
}

onMounted(() => {
  loadStats()
  loadActivity()
  startSystemStatusAutoRefresh()
})

onUnmounted(() => {
  stopSystemStatusAutoRefresh()
})
</script>

<style scoped>
.home-page {
  width: 100%;
  padding: 20px;
  box-sizing: border-box;
  overflow: hidden;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.page-header h2 {
  margin: 0;
  font-size: 24px;
  font-weight: 600;
  color: #303133;
}

.overview-cards {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
  margin-bottom: 20px;
}

.overview-card {
  display: flex;
  align-items: center;
  padding: 20px;
  border-radius: 12px;
  color: white;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  transition: all 0.3s ease;
}

.overview-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
}

.overview-card.purple {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.overview-card.blue {
  background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
}

.overview-card.green {
  background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
}

.overview-card.orange {
  background: linear-gradient(135deg, #fa709a 0%, #fee140 100%);
}

.overview-icon {
  width: 60px;
  height: 60px;
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 16px;
  font-size: 28px;
}

.overview-content {
  flex: 1;
}

.overview-value {
  font-size: 32px;
  font-weight: 700;
  margin-bottom: 4px;
}

.overview-label {
  font-size: 16px;
  font-weight: 500;
  margin-bottom: 4px;
  opacity: 0.95;
}

.overview-desc {
  font-size: 12px;
  opacity: 0.8;
}

.card-header {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 600;
}

.card-header .el-button {
  margin-left: auto;
}

.empty-state {
  padding: 40px 0;
  text-align: center;
}

@media (max-width: 1200px) {
  .overview-cards {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 768px) {
  .overview-cards {
    grid-template-columns: 1fr;
  }

  .home-page {
    padding: 12px;
  }
}
</style>
