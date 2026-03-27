<template>
  <div class="admin-user-page">
    <div class="page-header">
      <h2>{{ t('adminUser.title') }}</h2>
      <el-button type="primary" size="small" @click="showCreateDialog" :icon="Plus">
        {{ t('adminUser.addAdmin') }}
      </el-button>
    </div>

    <el-card shadow="never" class="table-card">
      <el-table :data="adminUsers" stripe style="width: 100%" v-loading="loading" size="small">
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column prop="username" :label="t('adminUser.username')" min-width="120" />
        <el-table-column prop="email" :label="t('adminUser.email')" min-width="150" show-overflow-tooltip />
        <el-table-column prop="role" :label="t('adminUser.role')" width="100">
          <template #default="{ row }">
            <el-tag :type="row.role === 'super_admin' ? 'danger' : 'primary'" size="small">
              {{ row.role === 'super_admin' ? t('adminUser.roleSuperAdmin') : t('adminUser.roleAdmin') }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="status" :label="t('common.status')" width="80">
          <template #default="{ row }">
            <el-tag :type="row.status ? 'success' : 'info'" size="small">
              {{ row.status ? t('common.enabled') : t('common.disabled') }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="last_login" :label="t('adminUser.lastLogin')" min-width="150">
          <template #default="{ row }">
            {{ formatDate(row.last_login) }}
          </template>
        </el-table-column>
        <el-table-column prop="created_at" :label="t('adminUser.createdAt')" min-width="150">
          <template #default="{ row }">
            {{ formatDate(row.created_at) }}
          </template>
        </el-table-column>
        <el-table-column :label="t('common.operation')" width="150" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" size="small" text @click="showEditDialog(row)">
              {{ t('common.edit') }}
            </el-button>
            <el-button type="danger" size="small" text @click="handleDelete(row)" :disabled="row.role === 'super_admin'">
              {{ t('common.delete') }}
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <div v-if="adminUsers.length === 0 && !loading" class="empty-state">
        <el-empty :description="t('adminUser.noAdmins')" />
      </div>
    </el-card>

    <!-- 创建/编辑对话框 -->
    <el-dialog v-model="dialogVisible" :title="isEdit ? t('adminUser.editAdmin') : t('adminUser.addAdmin')" width="500px" destroy-on-close>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="80px">
        <el-form-item :label="t('adminUser.username')" prop="username">
          <el-input v-model="form.username" :placeholder="t('adminUser.usernamePlaceholder')" />
        </el-form-item>
        <el-form-item :label="t('adminUser.password')" prop="password" v-if="!isEdit">
          <el-input v-model="form.password" type="password" :placeholder="t('adminUser.passPlaceholder')" show-password />
        </el-form-item>
        <el-form-item :label="t('adminUser.password')" prop="password" v-else>
          <el-input v-model="form.password" type="password" :placeholder="t('adminUser.passwordHint')" show-password />
        </el-form-item>
        <el-form-item :label="t('adminUser.email')" prop="email">
          <el-input v-model="form.email" :placeholder="t('adminUser.emailPlaceholder')" />
        </el-form-item>
        <el-form-item :label="t('adminUser.role')" prop="role">
          <el-select v-model="form.role" :placeholder="t('adminUser.rolePlaceholder')" style="width: 100%">
            <el-option :label="t('adminUser.roleAdmin')" value="admin" />
            <el-option :label="t('adminUser.roleSuperAdmin')" value="super_admin" />
          </el-select>
        </el-form-item>
        <el-form-item :label="t('common.status')" prop="status" v-if="isEdit">
          <el-switch v-model="form.status" :active-text="t('common.enabled')" :inactive-text="t('common.disabled')" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">{{ t('common.cancel') }}</el-button>
        <el-button type="primary" @click="handleSubmit" :loading="submitting">
          {{ isEdit ? t('common.save') : t('common.create') }}
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import { getAdminUsers, createAdminUser, updateAdminUser, deleteAdminUser } from '../api/admin.js'

const { t } = useI18n()

const loading = ref(false)
const submitting = ref(false)
const dialogVisible = ref(false)
const isEdit = ref(false)
const formRef = ref(null)
const adminUsers = ref([])

const form = ref({
  id: null,
  username: '',
  password: '',
  email: '',
  role: 'admin',
  status: true
})

const rules = computed(() => ({
  username: [
    { required: true, message: t('adminUser.usernameRequired'), trigger: 'blur' },
    { min: 3, max: 50, message: t('adminUser.usernameLength'), trigger: 'blur' }
  ],
  password: [
    { required: !isEdit.value, message: t('adminUser.passRequired'), trigger: 'blur' },
    { min: 6, message: t('adminUser.passLength'), trigger: 'blur' }
  ],
  role: [
    { required: true, message: t('adminUser.roleRequired'), trigger: 'change' }
  ]
}))

function formatDate(dateStr) {
  if (!dateStr) return '-'
  try {
    return new Date(dateStr).toLocaleString('zh-CN')
  } catch {
    return dateStr
  }
}

async function loadAdminUsers() {
  loading.value = true
  try {
    const data = await getAdminUsers()
    adminUsers.value = data.users || []
  } catch (e) {
    ElMessage.error(t('adminUser.loadFailed') + ': ' + e.message)
  } finally {
    loading.value = false
  }
}

function showCreateDialog() {
  isEdit.value = false
  form.value = {
    id: null,
    username: '',
    password: '',
    email: '',
    role: 'admin',
    status: true
  }
  dialogVisible.value = true
}

function showEditDialog(row) {
  isEdit.value = true
  form.value = {
    id: row.id,
    username: row.username,
    password: '',
    email: row.email,
    role: row.role,
    status: row.status
  }
  dialogVisible.value = true
}

async function handleSubmit() {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return

  submitting.value = true
  try {
    if (isEdit.value) {
      const updateData = {
        username: form.value.username,
        email: form.value.email,
        role: form.value.role,
        status: form.value.status
      }
      if (form.value.password) {
        updateData.password = form.value.password
      }
      await updateAdminUser(form.value.id, updateData)
      ElMessage.success(t('adminUser.updated'))
    } else {
      await createAdminUser({
        username: form.value.username,
        password: form.value.password,
        email: form.value.email,
        role: form.value.role
      })
      ElMessage.success(t('adminUser.created'))
    }
    dialogVisible.value = false
    loadAdminUsers()
  } catch (e) {
    ElMessage.error(e.message)
  } finally {
    submitting.value = false
  }
}

async function handleDelete(row) {
  try {
    await ElMessageBox.confirm(
      t('adminUser.confirmDelete', { name: row.username }),
      t('adminUser.confirmDeleteTitle'),
      {
        confirmButtonText: t('common.confirm'),
        cancelButtonText: t('common.cancel'),
        type: 'warning'
      }
    )
    await deleteAdminUser(row.id)
    ElMessage.success(t('adminUser.deleted'))
    loadAdminUsers()
  } catch (e) {
    if (e !== 'cancel') {
      ElMessage.error(e.message)
    }
  }
}

onMounted(loadAdminUsers)
</script>

<style scoped>
.admin-user-page {
  width: 100%;
  padding: 0 16px;
  box-sizing: border-box;
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

.table-card {
  width: 100%;
}

.empty-state {
  padding: 40px 0;
  text-align: center;
}
</style>
