<template>
  <nav class="mobile-nav">
    <div class="mobile-nav-inner">
      <div
        v-for="item in navItems"
        :key="item.path"
        class="mobile-nav-item"
        :class="{ active: isActive(item.path) }"
        @click="router.push(item.path)"
      >
        <span class="nav-icon-wrapper">
          <span class="nav-icon" v-html="item.icon"></span>
          <span v-if="item.path === '/chat' && unreadCount > 0" class="nav-badge">{{ unreadCount > 99 ? '99+' : unreadCount }}</span>
        </span>
        <span class="nav-label">{{ item.label }}</span>
      </div>
    </div>
    <div class="download-app-btn" @click="handleDownload">
      <span>下载APP</span>
    </div>
  </nav>
</template>

<script setup lang="ts">
import { computed, ref, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { api } from '../api/client'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()

const unreadCount = ref(0)
let unreadInterval: any = null

async function fetchUnreadCount() {
  try {
    const res = await api.get('/chat/conversations')
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      unreadCount.value = res.data.data.reduce((sum: number, m: any) => sum + (m.unread || 0), 0)
    }
  } catch (e) {}
}

onMounted(() => {
  fetchUnreadCount()
  unreadInterval = setInterval(fetchUnreadCount, 30000)
})

onUnmounted(() => {
  if (unreadInterval) clearInterval(unreadInterval)
})

function handleDownload() {
  // Placeholder: open app download page or show QR code
  window.alert('请访问官方网站下载APP')
}

const navItems = computed(() => {
  const items = [
    { path: '/home', label: '首页', icon: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>' },
    { path: '/channels/search', label: '发现', icon: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polygon points="16.24 7.76 14.12 14.12 7.76 16.24 9.88 9.88 16.24 7.76"/></svg>' },
    { path: '/chat', label: '消息', icon: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>' },
    { path: '/tree-hole', label: '树洞', icon: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2a10 10 0 0 1 10 10c0 5.52-4.48 10-10 10S2 17.52 2 12"/><path d="M12 2c3 3 4 7 4 10s-1 7-4 10"/><circle cx="12" cy="12" r="3"/></svg>' },
    { path: '/announcements', label: '公告', icon: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 12h-4l-3 9L9 3l-3 9H2"/></svg>' },
    { path: '/profile', label: '我的', icon: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>' },
  ]
  if (authStore.isAdmin) {
    items.push({ path: '/admin', label: '管理', icon: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>' })
  }
  return items
})

function isActive(path: string): boolean {
  if (path === '/home') return route.path === '/home' || route.path === '/' || route.path.startsWith('/post')
  if (path === '/chat') return route.path.startsWith('/chat')
  if (path === '/tree-hole') return route.path === '/tree-hole'
  if (path === '/announcements') return route.path === '/announcements'
  if (path === '/profile') return route.path === '/profile' || route.path === '/settings' || route.path === '/liked-posts' || route.path === '/device-management' || route.path === '/channels/applications'
  if (path === '/channels/search') return route.path === '/channels/search'
  if (path === '/admin') return route.path === '/admin'
  return route.path === path
}
</script>

<style scoped>
.mobile-nav {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  z-index: 100;
  background: rgba(15, 18, 25, 0.92);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border-top: 1px solid var(--border);
  padding: 6px 0 6px;
  padding-bottom: max(6px, env(safe-area-inset-bottom));
  display: flex;
  flex-direction: column;
  align-items: center;
}

.mobile-nav-inner {
  display: flex;
  justify-content: space-around;
  width: 100%;
  max-width: 500px;
  padding: 0 8px;
}

.mobile-nav-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
  padding: 4px 8px;
  cursor: pointer;
  color: var(--text-secondary);
  transition: all 0.2s;
  border-radius: 8px;
  -webkit-tap-highlight-color: transparent;
  min-width: 48px;
}

.mobile-nav-item:hover,
.mobile-nav-item.active {
  color: var(--primary);
}

.nav-icon-wrapper {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
}

.nav-icon {
  display: flex;
  align-items: center;
  justify-content: center;
}

.nav-label {
  font-size: 10px;
  font-weight: 500;
  white-space: nowrap;
}

.nav-badge {
  position: absolute;
  top: -4px;
  right: -6px;
  min-width: 16px;
  height: 16px;
  border-radius: 8px;
  background: #ff4757;
  color: #fff;
  font-size: 9px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0 3px;
  line-height: 1;
}

.download-app-btn {
  margin-top: 6px;
  padding: 4px 20px;
  background: #ffffff;
  border-radius: 20px;
  cursor: pointer;
  transition: all 0.2s;
  -webkit-tap-highlight-color: transparent;
}

.download-app-btn span {
  font-size: 11px;
  font-weight: 700;
  color: #0F1923;
  letter-spacing: 0.5px;
}

.download-app-btn:active {
  transform: scale(0.95);
  opacity: 0.9;
}
</style>
