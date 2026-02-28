<template>
  <div class="link-editor">
    <el-table :data="modelValue" border size="small" class="link-table">
      <el-table-column label="图标代码" width="130">
        <template #default="{ row }">
          <div class="icon-cell">
            <span v-if="row.icon" class="icon-preview" style="font-family: 'Segoe Fluent Icons'">
              {{ iconChar(row.icon) }}
            </span>
            <el-input v-model="row.icon" placeholder="e8f2" size="small" />
          </div>
        </template>
      </el-table-column>
      <el-table-column label="显示文字" min-width="200">
        <template #default="{ row }">
          <el-input v-model="row.text" placeholder="QQ交流群" size="small" />
        </template>
      </el-table-column>
      <el-table-column label="链接地址" min-width="280">
        <template #default="{ row }">
          <el-input v-model="row.url" placeholder="https://..." size="small" />
        </template>
      </el-table-column>
      <el-table-column label="操作" width="80" align="center">
        <template #default="{ $index }">
          <el-button type="danger" text size="small" @click="removeLink($index)">
            <el-icon><Delete /></el-icon>
          </el-button>
        </template>
      </el-table-column>
    </el-table>
    <el-button class="add-btn" text type="primary" @click="addLink">
      <el-icon><Plus /></el-icon>
      添加链接
    </el-button>
  </div>
</template>

<script setup>
const props = defineProps({
  modelValue: { type: Array, default: () => [] }
})
const emit = defineEmits(['update:modelValue'])

function iconChar(hex) {
  try {
    return String.fromCharCode(parseInt(hex, 16))
  } catch {
    return ''
  }
}

function addLink() {
  emit('update:modelValue', [...props.modelValue, { icon: '', text: '', url: '' }])
}

function removeLink(index) {
  const arr = [...props.modelValue]
  arr.splice(index, 1)
  emit('update:modelValue', arr)
}
</script>

<style scoped>
.link-editor {
  margin-bottom: 8px;
}

.link-table {
  margin-bottom: 8px;
}

.icon-cell {
  display: flex;
  align-items: center;
  gap: 6px;
}

.icon-preview {
  font-size: 16px;
  width: 20px;
  text-align: center;
  flex-shrink: 0;
}

.add-btn {
  margin-top: 4px;
}
</style>
