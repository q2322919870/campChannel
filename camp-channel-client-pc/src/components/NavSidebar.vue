<template>
  <nav class="sidebar">
    <div class="sidebar-inner">
      <div class="nav-items">
        <div
          v-for="item in navItems"
          :key="item.path"
          class="nav-item"
          :class="{ active: isActive(item.path) }"
          @click="router.push(item.path)"
          :title="item.label"
        >
          <span class="nav-icon" v-html="item.icon"></span>
          <span v-if="item.path === '/chat' && unreadCount > 0" class="nav-badge">{{ unreadCount > 99 ? '99+' : unreadCount }}</span>
          <span v-if="item.path === '/channels/applications' && pendingAppCount > 0" class="nav-badge">{{ pendingAppCount }}</span>
        </div>
      </div>

      <div class="nav-bottom">
        <div
          class="nav-item"
          :class="{ active: route.path === '/settings' }"
          @click="router.push('/settings')"
          title="设置"
        >
          <span class="nav-icon">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/>
            </svg>
          </span>
        </div>

        <div class="nav-item" @click="handleLogout" title="退出登录">
          <span class="nav-icon">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
          </span>
        </div>

        <div class="nav-item user-avatar" @click="router.push('/profile')" title="个人中心">
          <img v-if="authStore.user?.avatar" :src="authStore.user.avatar" class="mini-avatar" />
          <span v-else>{{ displayName }}</span>
        </div>
      </div>
    </div>
  </nav>
</template>

<script setup lang="ts">
import { computed, ref, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { useThemeStore } from '../stores/theme'
import { api } from '../api/client'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const themeStore = useThemeStore()

const unreadCount = ref(0)
const pendingAppCount = ref(0)
let unreadInterval: any = null
let pendingAppInterval: any = null

async function fetchUnreadCount() {
  if (!authStore.isLoggedIn) return
  try {
    const res = await api.get('/chat/conversations')
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      unreadCount.value = res.data.data.reduce((sum: number, m: any) => sum + (m.unread || 0), 0)
    }
  } catch (e) {}
}

async function fetchPendingAppCount() {
  if (!authStore.isLoggedIn) return
  try {
    const res = await api.get('/channels/applications/pending/count')
    if (res.data.code === 200) pendingAppCount.value = res.data.data || 0
  } catch {}
}

onMounted(() => {
  fetchUnreadCount()
  fetchPendingAppCount()
  unreadInterval = setInterval(fetchUnreadCount, 30000)
  pendingAppInterval = setInterval(fetchPendingAppCount, 30000)
})

onUnmounted(() => {
  if (unreadInterval) clearInterval(unreadInterval)
  if (pendingAppInterval) clearInterval(pendingAppInterval)
})

function handleLogout() {
  authStore.logout()
  router.push('/login')
}

const displayName = computed(() => {
  const name = authStore.user?.username
  return name ? name.charAt(0).toUpperCase() : '?'
})

const navItems = computed(() => {
  const items = [
    { path: '/home', label: '首页', icon: '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>' },
    { path: '/channels/search', label: '发现', icon: '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polygon points="16.24 7.76 14.12 14.12 7.76 16.24 9.88 9.88 16.24 7.76"/></svg>' },
    { path: '/chat', label: '消息', icon: '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>' },
    { path: '/friends', label: '好友', icon: '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8.5" cy="7" r="4"/><polyline points="17 11 19 13 23 9"/></svg>' },
    { path: '/notifications', label: '通知', icon: '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>' },
    { path: '/tree-hole', label: '树洞', icon: '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2a10 10 0 0 1 10 10c0 5.52-4.48 10-10 10S2 17.52 2 12"/><path d="M12 2c3 3 4 7 4 10s-1 7-4 10"/><circle cx="12" cy="12" r="3"/></svg>' },
    { path: '/announcements', label: '公告', icon: '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 12h-4l-3 9L9 3l-3 9H2"/></svg>' },
    { path: '/channels/applications', label: '申请', icon: '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>' },
    { path: '/profile', label: '我的', icon: '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>' },
  ]
  if (authStore.isAdmin) {
    items.push({ path: '/admin', label: '管理', icon: '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>' })
  }
  return items
})

function isActive(path: string): boolean {
  if (path === '/home') return route.path === '/home' || route.path === '/' || route.path.startsWith('/post')
  if (path === '/channels/search') return route.path === '/channels/search'
  if (path === '/channels/applications') return route.path === '/channels/applications'
  if (path === '/chat') return route.path.startsWith('/chat')
  if (path === '/friends') return route.path.startsWith('/friends')
  if (path === '/tree-hole') return route.path === '/tree-hole'
  if (path === '/announcements') return route.path === '/announcements'
  return route.path === path
}
</script>

<style scoped>
.sidebar {
  position: fixed;
  left: 0;
  top: 0;
  width: 72px;
  height: 100vh;
  z-index: 100;
  background: rgba(15, 18, 25, 0.6);
  backdrop-filter: blur(24px);
  -webkit-backdrop-filter: blur(24px);
  border-right: 1px solid var(--border);
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 16px 0;
}

.sidebar-inner {
  display: flex;
  flex-direction: column;
  align-items: center;
  height: 100%;
  width: 100%;
}

.nav-items {
  flex: 0 1 auto;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
}

.nav-item {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  color: var(--text-secondary);
  transition: all 0.2s;
  position: relative;
}
.nav-item:hover { color: var(--text); background: var(--card); }
.nav-item.active { color: var(--primary); background: var(--card); }
.nav-item.active::before {
  content: '';
  position: absolute;
  left: -16px;
  width: 3px;
  height: 20px;
  border-radius: 0 3px 3px 0;
  background: var(--primary);
}

.nav-bottom {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  margin-top: auto;
}

.user-avatar span {
  font-size: 16px;
  font-weight: 700;
  color: var(--primary);
}
.mini-avatar { width: 100%; height: 100%; border-radius: 12px; object-fit: cover; }

.nav-icon { display: flex; align-items: center; justify-content: center; }

.nav-badge {
  position: absolute; top: 4px; right: 4px; min-width: 16px; height: 16px;
  border-radius: 8px; background: #ff4757; color: #fff; font-size: 10px;
  font-weight: 700; display: flex; align-items: center; justify-content: center;
  padding: 0 4px; line-height: 1;
}
</style>
