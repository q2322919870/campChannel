<template>
  <div class="device-page">
    <h1 class="page-title">设备管理</h1>
    <div class="device-list">
      <div v-for="d in devices" :key="d.id" class="device-item">
        <div class="device-icon">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2" ry="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>
        </div>
        <div class="device-info">
          <div class="device-name">{{ d.deviceName || '未知设备' }}</div>
          <div class="device-meta">{{ d.ipAddress || '未知IP' }} · {{ d.loginTime || '' }}</div>
        </div>
        <span class="device-status" :class="{ active: d.isActive }">{{ d.isActive ? '当前' : '' }}</span>
        <button v-if="!d.isActive" class="logout-btn" @click="logoutDevice(d.id)">下线</button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { api } from '../api/client'

const devices = ref<any[]>([])

async function fetchDevices() {
  try {
    const res = await api.get('/users/devices')
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      devices.value = res.data.data.map((d: any, i: number) => ({
        ...d,
        isActive: i === 0,
      }))
    }
  } catch (e) {}
}

async function logoutDevice(id: number) {
  try {
    await api.post(`/users/devices/${id}/logout`)
    devices.value = devices.value.filter(d => d.id !== id)
  } catch (e) {}
}

onMounted(() => { fetchDevices() })
</script>

<style scoped>
.device-page { max-width: 640px; margin: 0 auto; }
.page-title { font-size: 24px; font-weight: 700; margin-bottom: 24px; }
.device-list { display: flex; flex-direction: column; gap: 8px; }
.device-item { display: flex; align-items: center; gap: 14px; padding: 16px; background: var(--card); border: 1px solid var(--border); border-radius: 14px; }
.device-icon { width: 44px; height: 44px; border-radius: 10px; background: var(--card); display: flex; align-items: center; justify-content: center; color: var(--primary); }
.device-info { flex: 1; }
.device-name { font-size: 14px; font-weight: 600; margin-bottom: 2px; }
.device-meta { font-size: 12px; color: var(--text-secondary); }
.device-status { font-size: 11px; padding: 2px 8px; border-radius: 6px; background: rgba(74,222,128,0.1); color: #4ade80; }
.device-status:empty { display: none; }
.logout-btn { padding: 6px 14px; border-radius: 8px; border: 1px solid rgba(255,107,107,0.3); background: rgba(255,107,107,0.05); color: #ff6b6b; font-size: 12px; cursor: pointer; }
</style>
