<template>
  <div class="users-page">
    <div class="page-header">
      <h2>{{ t('userMgmt.title') }}</h2>
      <el-button type="primary" @click="handleAdd">
        <el-icon><Plus /></el-icon>
        {{ t('userMgmt.addUser') }}
      </el-button>
    </div>

    <el-card class="users-card">
      <el-table
        :data="users"
        v-loading="loading"
        style="width: 100%"
        :header-cell-style="{ background: '#f5f7fa' }"
      >
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column prop="username" :label="t('userMgmt.username')" min-width="120" />
        <el-table-column prop="phone" :label="t('userMgmt.phone')" min-width="120" />
        <el-table-column prop="email" :label="t('userMgmt.email')" min-width="180" />
        <el-table-column prop="level" :label="t('userMgmt.level')" width="100">
          <template #default="{ row }">
            <el-tag :type="getLevelType(row.level)">{{ row.level }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="deviceCount" :label="t('userMgmt.deviceCount')" width="100" />
        <el-table-column prop="channelType" :label="t('userMgmt.channelType')" width="100">
          <template #default="{ row }">
            <el-tag :type="row.channelType === '全球' ? 'success' : 'warning'">
              {{ row.channelType === '全球' ? t('userMgmt.channelGlobal') : t('userMgmt.channelChina') }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="status" :label="t('common.status')" width="80">
          <template #default="{ row }">
            <el-switch
              v-model="row.status"
              @change="(val) => handleStatusChange(row, val)"
            />
          </template>
        </el-table-column>
        <el-table-column :label="t('common.operation')" width="180" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="handleEdit(row)">
              <el-icon><Edit /></el-icon>
              {{ t('common.edit') }}
            </el-button>
            <el-button link type="danger" @click="handleDelete(row)">
              <el-icon><Delete /></el-icon>
              {{ t('common.delete') }}
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-empty v-if="!loading && users.length === 0" :description="t('userMgmt.noUsers')" />
    </el-card>

    <!-- 新增/编辑对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="isEdit ? t('userMgmt.editUser') : t('userMgmt.addUser')"
      width="500px"
      destroy-on-close
    >
      <el-form
        ref="formRef"
        :model="form"
        :rules="rules"
        label-width="100px"
      >
        <el-form-item :label="t('userMgmt.username')" prop="username">
          <el-input v-model="form.username" :placeholder="t('userMgmt.usernamePlaceholder')" :disabled="isEdit" />
        </el-form-item>
        <el-form-item :label="t('userMgmt.phone')" prop="phone">
          <el-input v-model="form.phone" :placeholder="t('userMgmt.phonePlaceholder')" />
        </el-form-item>
        <el-form-item :label="t('userMgmt.email')" prop="email">
          <el-input v-model="form.email" :placeholder="t('userMgmt.emailPlaceholder')" />
        </el-form-item>
        <el-form-item :label="t('userMgmt.password')" prop="password" v-if="!isEdit">
          <el-input v-model="form.password" type="password" :placeholder="t('userMgmt.passwordPlaceholder')" show-password />
        </el-form-item>
        <el-form-item :label="t('userMgmt.password')" prop="password" v-else>
          <el-input v-model="form.password" type="password" :placeholder="t('userMgmt.passwordHint')" show-password />
        </el-form-item>
        <el-form-item :label="t('userMgmt.level')" prop="level">
          <el-select v-model="form.level" :placeholder="t('userMgmt.levelPlaceholder')" style="width: 100%">
            <el-option label="V1" value="V1" />
            <el-option label="V2" value="V2" />
            <el-option label="V3" value="V3" />
            <el-option label="V4" value="V4" />
            <el-option label="V5" value="V5" />
          </el-select>
        </el-form-item>
        <el-form-item :label="t('userMgmt.deviceCount')" prop="deviceCount">
          <el-input-number v-model="form.deviceCount" :min="0" style="width: 100%" />
        </el-form-item>
        <el-form-item :label="t('userMgmt.channelType')" prop="channelType">
          <el-select v-model="form.channelType" :placeholder="t('userMgmt.channelPlaceholder')" style="width: 100%">
            <el-option :label="t('userMgmt.channelGlobal')" value="全球" />
            <el-option :label="t('userMgmt.channelChina')" value="中国大陆" />
          </el-select>
        </el-form-item>
        <el-form-item :label="t('common.status')" prop="status">
          <el-switch v-model="form.status" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">{{ t('common.cancel') }}</el-button>
        <el-button type="primary" @click="handleSubmit" :loading="submitting">
          {{ t('common.confirm') }}
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Edit, Delete } from '@element-plus/icons-vue'
import { getUsers, createUser, updateUser, deleteUser } from '../api/users.js'

const { t } = useI18n()

const loading = ref(false)
const users = ref([])
const dialogVisible = ref(false)
const isEdit = ref(false)
const submitting = ref(false)
const formRef = ref(null)

const form = reactive({
  id: null,
  username: '',
  phone: '',
  email: '',
  password: '',
  level: 'V1',
  deviceCount: 0,
  channelType: '全球',
  status: true
})

const rules = computed(() => ({
  username: [{ required: true, message: t('userMgmt.usernameRequired'), trigger: 'blur' }],
  password: [{ required: !isEdit.value, message: t('userMgmt.passRequired'), trigger: 'blur' }]
}))

async function loadUsers() {
  loading.value = true
  try {
    const data = await getUsers()
    users.value = data.users || []
  } catch (e) {
    ElMessage.error(t('userMgmt.loadFailed') + ': ' + e.message)
  } finally {
    loading.value = false
  }
}

function getLevelType(level) {
  const types = { 'V1': '', 'V2': 'success', 'V3': 'warning', 'V4': 'danger', 'V5': 'info' }
  return types[level] || ''
}

function handleAdd() {
  isEdit.value = false
  Object.assign(form, {
    id: null,
    username: '',
    phone: '',
    email: '',
    password: '',
    level: 'V1',
    deviceCount: 0,
    channelType: '全球',
    status: true
  })
  dialogVisible.value = true
}

function handleEdit(row) {
  isEdit.value = true
  Object.assign(form, {
    id: row.id,
    username: row.username,
    phone: row.phone,
    email: row.email,
    password: '',
    level: row.level,
    deviceCount: row.deviceCount,
    channelType: row.channelType,
    status: row.status
  })
  dialogVisible.value = true
}

async function handleSubmit() {
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid) return

  submitting.value = true
  try {
    if (isEdit.value) {
      await updateUser(form.id, form)
      ElMessage.success(t('userMgmt.updated'))
    } else {
      await createUser(form)
      ElMessage.success(t('userMgmt.created'))
    }
    dialogVisible.value = false
    loadUsers()
  } catch (e) {
    ElMessage.error(e.message)
  } finally {
    submitting.value = false
  }
}

async function handleDelete(row) {
  try {
    await ElMessageBox.confirm(t('userMgmt.confirmDelete'), t('common.tip'), { type: 'warning' })
    await deleteUser(row.id)
    ElMessage.success(t('userMgmt.deleted'))
    loadUsers()
  } catch (e) {
    if (e !== 'cancel') {
      ElMessage.error(t('userMgmt.deleteFailed') + ': ' + e.message)
    }
  }
}

async function handleStatusChange(row, status) {
  try {
    await updateUser(row.id, { status })
    ElMessage.success(t('userMgmt.statusUpdated'))
  } catch (e) {
    ElMessage.error(t('userMgmt.statusFailed') + ': ' + e.message)
    row.status = !status
  }
}

onMounted(() => {
  loadUsers()
})
</script>

<style scoped>
.users-page {
  padding: 20px;
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
  color: #303133;
}

.users-card {
  min-height: 400px;
}
</style>
