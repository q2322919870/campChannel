<template>
  <div class="notification-page">
    <div class="page-header">
      <h1>通知中心</h1>
      <button class="read-all-btn" @click="markAllRead" v-if="hasUnread">全部已读</button>
    </div>
    <div class="notifications-list">
      <div
        v-for="notif in notifications"
        :key="notif.id"
        class="notification-item"
        :class="{ unread: !notif.isRead }"
        @click="markRead(notif)"
      >
        <div class="notif-icon" :style="{ background: getIconBg(notif.type) }">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
        </div>
        <div class="notif-body">
          <div class="notif-title">{{ notif.title }}</div>
          <div class="notif-content">{{ notif.content }}</div>
          <div class="notif-time">{{ notif.time }}</div>
        </div>
        <div v-if="!notif.isRead" class="notif-dot"></div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { api } from '../api/client'

interface Notif { id: number; type: string; title: string; content: string; time: string; isRead: boolean }
const notifications = ref<Notif[]>([])
const hasUnread = computed(() => notifications.value.some(n => !n.isRead))

async function fetchNotifications() {
  try {
    const res = await api.get('/notifications/unread')
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      notifications.value = res.data.data.map((n: any) => ({
        id: n.id,
        type: n.type || 'system',
        title: n.title || '通知',
        content: n.content || '',
        time: n.createTime || '',
        isRead: n.isRead === 1,
      }))
    }
  } catch (e) {}
}

async function markAllRead() {
  try {
    await api.post('/notifications/read-all')
    notifications.value.forEach(n => n.isRead = true)
  } catch (e) {}
}

async function markRead(notif: Notif) {
  if (notif.isRead) return
  try {
    await api.post(`/notifications/${notif.id}/read`)
    notif.isRead = true
  } catch (e) {}
}

function getIconBg(type: string) {
  const colors: Record<string, string> = {
    friend_request: 'linear-gradient(135deg, #4A9BD9, #F5C6D0)',
    like: 'linear-gradient(135deg, #FF7F7F, #F2B5D4)',
    comment: 'linear-gradient(135deg, #6BCB9E, #F4A460)',
    system: 'linear-gradient(135deg, #7C9FCB, #CBA6F7)',
    friend_approved: 'linear-gradient(135deg, #4ADE80, #6BCB9E)',
  }
  return colors[type] || colors.system
}

onMounted(() => { fetchNotifications() })
</script>

<style scoped>
.notification-page { max-width: 720px; margin: 0 auto; }
.page-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; }
.page-header h1 { font-size: 28px; font-weight: 700; }
.read-all-btn { padding: 8px 20px; border-radius: 10px; border: 1px solid var(--primary); background: none; color: var(--primary); font-size: 13px; font-weight: 600; cursor: pointer; transition: all 0.2s; }
.read-all-btn:hover { background: rgba(124,159,203,0.1); }
.notifications-list { display: flex; flex-direction: column; gap: 8px; }
.notification-item { display: flex; align-items: flex-start; gap: 14px; padding: 16px; background: var(--surface); border: 1px solid var(--outline-variant); border-radius: 14px; cursor: pointer; transition: all 0.2s; }
.notification-item:hover { border-color: var(--primary); }
.notification-item.unread { border-left: 3px solid var(--primary); }
.notif-icon { width: 40px; height: 40px; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.notif-body { flex: 1; }
.notif-title { font-size: 14px; font-weight: 600; margin-bottom: 4px; }
.notif-content { font-size: 13px; color: var(--on-surface-variant); margin-bottom: 4px; }
.notif-time { font-size: 11px; color: var(--on-surface-variant); }
.notif-dot { width: 8px; height: 8px; border-radius: 50%; background: var(--primary); margin-top: 14px; flex-shrink: 0; }
</style>
