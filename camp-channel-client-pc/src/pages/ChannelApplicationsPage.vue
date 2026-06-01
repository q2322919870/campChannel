<template>
  <div class="channel-apps-page">
    <h1 class="page-title">频道申请处理</h1>
    <div v-if="loading" class="loading-state">加载中...</div>
    <div v-else-if="applications.length === 0" class="empty-state">暂无待处理的频道申请</div>
    <div v-else class="app-list">
      <div v-for="app in applications" :key="app.id" class="app-item">
        <div class="app-avatar">{{ (app.username || '?').charAt(0) }}</div>
        <div class="app-info">
          <div class="app-username">{{ app.username || '用户 #' + app.userId }}</div>
          <div class="app-channel">申请加入: {{ app.channelName || '频道 #' + app.channelId }}</div>
          <div class="app-time">{{ app.applyTime || '' }}</div>
        </div>
        <div class="app-actions">
          <button class="approve-btn" @click="handleApp(app.id, true)">同意</button>
          <button class="reject-btn" @click="handleApp(app.id, false)">拒绝</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { api } from '../api/client'

const loading = ref(false)
const applications = ref<any[]>([])

async function fetchApplications() {
  loading.value = true
  try {
    const res = await api.get('/channels/applications/pending')
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      applications.value = await Promise.all(res.data.data.map(async (app: any) => {
        try {
          const uRes = await api.get(`/users/${app.userId}`)
          if (uRes.data.code === 200) app.username = uRes.data.data.username || '用户'
        } catch {}
        return app
      }))
    }
  } catch {}
  finally { loading.value = false }
}

async function handleApp(appId: number, approved: boolean) {
  try {
    await api.post(`/channels/applications/${appId}/approve`, { approved })
    applications.value = applications.value.filter(a => a.id !== appId)
  } catch (e: any) {
    alert(e.response?.data?.message || '操作失败')
  }
}

onMounted(() => { fetchApplications() })
</script>

<style scoped>
.channel-apps-page { max-width: 640px; margin: 0 auto; }
.page-title { font-size: 24px; font-weight: 700; margin-bottom: 24px; }
.loading-state, .empty-state { text-align: center; padding: 60px 20px; color: var(--text-secondary); font-size: 15px; }
.app-list { display: flex; flex-direction: column; gap: 8px; }
.app-item { display: flex; align-items: center; gap: 14px; padding: 16px; background: var(--card); border: 1px solid var(--border); border-radius: 14px; }
.app-avatar { width: 40px; height: 40px; border-radius: 12px; background: linear-gradient(135deg, var(--primary), var(--accent)); display: flex; align-items: center; justify-content: center; font-size: 16px; font-weight: 700; color: #fff; flex-shrink: 0; }
.app-info { flex: 1; }
.app-username { font-size: 14px; font-weight: 600; margin-bottom: 2px; }
.app-channel { font-size: 12px; color: var(--text-secondary); margin-bottom: 2px; }
.app-time { font-size: 11px; color: var(--text-secondary); }
.app-actions { display: flex; gap: 6px; }
.app-actions button { padding: 6px 16px; border: none; border-radius: 8px; font-size: 12px; font-weight: 600; cursor: pointer; }
.approve-btn { background: rgba(74,222,128,0.15); color: #4ade80; }
.reject-btn { background: rgba(255,107,107,0.15); color: #ff6b6b; }
</style>
