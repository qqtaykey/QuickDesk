<template>
  <div class="device-list-page" v-loading="loading">
    <div class="page-header">
      <h2>{{ t('nav.devices') }}</h2>
      <div class="header-actions">
        <el-button :icon="Download" size="small" @click="handleExport">{{ t('common.export') }}</el-button>
        <el-button type="primary" :icon="Refresh" size="small" @click="loadDevices">{{ t('common.refresh') }}</el-button>
      </div>
    </div>

    <!-- Filters -->
    <el-card shadow="never" class="filter-card">
      <div class="filter-bar">
        <el-input
          v-model="filters.search"
          :placeholder="t('devices.searchPlaceholder')"
          clearable
          style="width: 240px"
          @clear="handleSearch"
          @keyup.enter="handleSearch"
        >
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>
        <el-select v-model="filters.os" :placeholder="t('devices.filterOS')" clearable style="width: 140px" @change="handleFilter">
          <el-option label="Windows" value="Windows" />
          <el-option label="macOS" value="macOS" />
          <el-option label="Linux" value="Linux" />
          <el-option label="Unknown" value="Unknown" />
        </el-select>
        <el-select v-model="filters.online" :placeholder="t('devices.filterOnline')" clearable style="width: 140px" @change="handleFilter">
          <el-option :label="t('devices.online')" value="true" />
          <el-option :label="t('devices.offline')" value="false" />
        </el-select>
        <el-button :icon="Search" @click="handleSearch">{{ t('common.search') }}</el-button>
      </div>
    </el-card>

    <!-- Table -->
    <el-card shadow="never" style="margin-top: 16px">
      <el-table
        :data="devices"
        stripe
        style="width: 100%"
        size="small"
        @sort-change="handleSortChange"
        @row-click="handleRowClick"
        row-class-name="clickable-row"
      >
        <el-table-column prop="device_id" :label="t('devices.deviceId')" width="110" sortable="custom" />
        <el-table-column prop="device_uuid" label="UUID" min-width="180" show-overflow-tooltip />
        <el-table-column :label="t('devices.os')" min-width="120" sortable="custom" prop="os">
          <template #default="{ row }">
            {{ row.os }}{{ row.os_version ? ' ' + row.os_version : '' }}
          </template>
        </el-table-column>
        <el-table-column prop="app_version" :label="t('devices.appVersion')" width="110" sortable="custom" />
        <el-table-column :label="t('devices.status')" width="90" sortable="custom" prop="online">
          <template #default="{ row }">
            <el-tag :type="row.online ? 'success' : 'info'" size="small">
              {{ row.online ? t('devices.online') : t('devices.offline') }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column :label="t('devices.lastSeen')" width="170" sortable="custom" prop="last_seen">
          <template #default="{ row }">
            {{ formatDate(row.last_seen) }}
          </template>
        </el-table-column>
        <el-table-column :label="t('devices.createdAt')" width="170" sortable="custom" prop="created_at">
          <template #default="{ row }">
            {{ formatDate(row.created_at) }}
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination-bar">
        <el-pagination
          v-model:current-page="pagination.page"
          v-model:page-size="pagination.size"
          :page-sizes="[20, 50, 100]"
          :total="pagination.total"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="loadDevices"
          @current-change="loadDevices"
        />
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Refresh, Search, Download } from '@element-plus/icons-vue'
import { getDevices } from '../api/admin_device.js'
import { exportCSV } from '../utils/export.js'

const { t } = useI18n()
const router = useRouter()
const loading = ref(false)
const devices = ref([])

const filters = reactive({
  search: '',
  os: '',
  online: ''
})

const pagination = reactive({
  page: 1,
  size: 20,
  total: 0
})

const sort = reactive({
  field: 'created_at',
  order: 'desc'
})

function formatDate(dateStr) {
  if (!dateStr) return '-'
  return new Date(dateStr).toLocaleString('zh-CN')
}

async function loadDevices() {
  loading.value = true
  try {
    const data = await getDevices({
      page: pagination.page,
      size: pagination.size,
      sort: sort.field,
      order: sort.order,
      search: filters.search,
      os: filters.os,
      online: filters.online
    })
    devices.value = data.items || []
    pagination.total = data.total || 0
  } catch (e) {
    ElMessage.error(t('common.loadFailed') + ': ' + e.message)
  } finally {
    loading.value = false
  }
}

function handleSearch() {
  pagination.page = 1
  loadDevices()
}

function handleFilter() {
  pagination.page = 1
  loadDevices()
}

function handleSortChange({ prop, order }) {
  sort.field = prop || 'created_at'
  sort.order = order === 'ascending' ? 'asc' : 'desc'
  loadDevices()
}

function handleRowClick(row) {
  router.push(`/devices/${row.device_id}`)
}

function handleExport() {
  const columns = [
    { key: 'device_id', label: 'Device ID' },
    { key: 'device_uuid', label: 'UUID' },
    { key: 'os', label: 'OS' },
    { key: 'app_version', label: 'Version' },
    { key: 'online', label: 'Online' },
    { key: 'last_seen', label: 'Last Seen' },
    { key: 'created_at', label: 'Created At' }
  ]
  exportCSV(columns, devices.value, 'devices.csv')
}

onMounted(loadDevices)
</script>

<style scoped>
.device-list-page {
  width: 100%;
  padding: 20px;
  box-sizing: border-box;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.page-header h2 {
  margin: 0;
  font-size: 24px;
  font-weight: 600;
  color: #303133;
}

.header-actions {
  display: flex;
  gap: 8px;
}

.filter-card {
  border-radius: 8px;
}

.filter-bar {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
  align-items: center;
}

.pagination-bar {
  display: flex;
  justify-content: flex-end;
  margin-top: 16px;
}

:deep(.clickable-row) {
  cursor: pointer;
}

:deep(.clickable-row:hover td) {
  color: var(--el-color-primary);
}
</style>
