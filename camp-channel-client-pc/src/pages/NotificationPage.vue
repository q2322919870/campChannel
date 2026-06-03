<template>
  <div class="notification-page">
    <div class="page-header">
      <h1>通知中心</h1>
      <button class="read-all-btn" @click="markAllRead" v-if="hasUnread">全部已读</button>
    </div>

    <!-- Category Tabs -->
    <div class="tabs">
      <button
        v-for="tab in categories"
        :key="tab.value"
        class="tab"
        :class="{ active: activeCategory === tab.value }"
        @click="switchCategory(tab.value)"
      >
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path :d="tab.icon" />
        </svg>
        {{ tab.label }}
      </button>
    </div>

    <div class="notifications-list">
      <div v-if="isLoading" class="loading">
        <div class="spinner"></div>
      </div>
      <div v-else-if="notifications.length === 0" class="empty-state">
        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
          <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
          <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
        </svg>
        <p>暂无通知</p>
      </div>
      <div
        v-for="notif in notifications"
        :key="notif.id"
        class="notification-item"
        :class="{ unread: !notif.isRead }"
        @click="markRead(notif)"
      >
        <div class="notif-icon" :style="{ background: getIconBg(notif.type) }">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2" v-html="getIconSvg(notif.type)"></svg>
        </div>
        <div class="notif-body">
          <div class="notif-title">{{ notif.title }}</div>
          <div class="notif-content">{{ notif.content }}</div>
          <div class="notif-time">{{ formatTime(notif.createTime) }}</div>
        </div>
        <div v-if="!notif.isRead" class="notif-dot"></div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '../api/client'

const router = useRouter()

interface Notif {
  id: number
  type: string
  category: string
  title: string
  content: string
  createTime: string
  isRead: boolean
  relatedId?: string
}

const categories = [
  { value: '', label: '全部', icon: 'M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9M13.73 21a2 2 0 0 1-3.46 0' },
  { value: 'system', label: '系统', icon: 'M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z' },
  { value: 'interaction', label: '互动', icon: 'M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z' },
  { value: 'chat', label: '聊天', icon: 'M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z' },
]

const activeCategory = ref('')
const notifications = ref<Notif[]>([])
const isLoading = ref(false)
const hasUnread = computed(() => notifications.value.some(n => !n.isRead))

async function fetchNotifications() {
  isLoading.value = true
  try {
    const params: any = { page: 1, size: 50 }
    if (activeCategory.value) params.category = activeCategory.value
    const res = await api.get('/notifications/history', { params })
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      notifications.value = res.data.data.map((n: any) => ({
        id: n.id,
        type: n.type || 'system',
        category: n.category || 'system',
        title: n.title || '通知',
        content: n.content || '',
        createTime: n.createTime || '',
        isRead: n.isRead === 1,
        relatedId: n.relatedId || undefined,
      }))
    }
  } catch (e) {}
  isLoading.value = false
}

function switchCategory(cat: string) {
  activeCategory.value = cat
  fetchNotifications()
}

async function markAllRead() {
  try {
    await api.post('/notifications/read-all')
    notifications.value.forEach(n => n.isRead = true)
  } catch (e) {}
}

async function markRead(notif: Notif) {
  if (!notif.isRead) {
    try {
      await api.post(`/notifications/${notif.id}/read`)
      notif.isRead = true
    } catch (e) {}
  }
  if (notif.relatedId && ['mention', 'comment', 'like'].includes(notif.type)) {
    router.push({ name: 'PostDetail', params: { id: notif.relatedId } })
  }
}

function getIconBg(type: string) {
  const colors: Record<string, string> = {
    friend_request: 'linear-gradient(135deg, #4A9BD9, #F5C6D0)',
    like: 'linear-gradient(135deg, #FF7F7F, #F2B5D4)',
    comment: 'linear-gradient(135deg, #6BCB9E, #F4A460)',
    mention: 'linear-gradient(135deg, #7C3AED, #A78BFA)',
    system: 'linear-gradient(135deg, #7C9FCB, #CBA6F7)',
    friend_approved: 'linear-gradient(135deg, #4ADE80, #6BCB9E)',
    channel: 'linear-gradient(135deg, #0D9488, #5EEAD4)',
  }
  return colors[type] || colors.system
}

function getIconSvg(type: string): string {
  const icons: Record<string, string> = {
    like: '<path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/>',
    comment: '<path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>',
    mention: '<circle cx="12" cy="12" r="4"/><path d="M16 8v5a3 3 0 0 0 6 0v-1a10 10 0 1 0-3.92 7.94"/>',
    friend_request: '<path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8.5" cy="7" r="4"/><line x1="20" y1="8" x2="20" y2="14"/><line x1="23" y1="11" x2="17" y2="11"/>',
    friend_approved: '<path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8.5" cy="7" r="4"/><polyline points="17 11 19 13 23 9"/>',
    channel: '<path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>',
  }
  return icons[type] || '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>'
}

function formatTime(time: string) {
  if (!time) return ''
  const date = new Date(time)
  const now = new Date()
  const diff = now.getTime() - date.getTime()
  const minutes = Math.floor(diff / 60000)
  const hours = Math.floor(diff / 3600000)
  const days = Math.floor(diff / 86400000)
  
  if (minutes < 1) return '刚刚'
  if (minutes < 60) return `${minutes}分钟前`
  if (hours < 24) return `${hours}小时前`
  if (days < 7) return `${days}天前`
  return date.toLocaleDateString('zh-CN')
}

onMounted(() => { fetchNotifications() })
</script>

<style scoped>
.notification-page { max-width: 720px; margin: 0 auto; }
.page-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; }
.page-header h1 { font-size: 28px; font-weight: 700; }
.read-all-btn { padding: 8px 20px; border-radius: 10px; border: 1px solid var(--primary); background: none; color: var(--primary); font-size: 13px; font-weight: 600; cursor: pointer; transition: all 0.2s; }
.read-all-btn:hover { background: rgba(124,159,203,0.1); }

.tabs { display: flex; gap: 8px; margin-bottom: 20px; border-bottom: 1px solid var(--outline-variant); }
.tab {
  padding: 10px 16px;
  border: none;
  background: none;
  font-size: 14px;
  font-weight: 500;
  color: var(--on-surface-variant);
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 6px;
  position: relative;
  transition: color 0.2s;
}
.tab.active { color: var(--primary); }
.tab.active::after {
  content: '';
  position: absolute;
  bottom: -1px;
  left: 0;
  right: 0;
  height: 2px;
  background: var(--primary);
  border-radius: 2px;
}

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

.loading { display: flex; justify-content: center; padding: 40px; }
.spinner { width: 40px; height: 40px; border: 3px solid var(--outline-variant); border-top-color: var(--primary); border-radius: 50%; animation: spin 1s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }

.empty-state { text-align: center; padding: 60px; color: var(--on-surface-variant); }
.empty-state svg { margin-bottom: 12px; opacity: 0.3; }
</style>
