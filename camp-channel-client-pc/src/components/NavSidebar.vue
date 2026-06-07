<template>
  <nav
    class="nav-bubble-field"
    :style="{ height: `${fieldHeight}px`, marginTop: `-${fieldHeight / 2}px` }"
    @mousemove="onMouseMove"
    @mouseleave="onMouseLeave"
  >
    <button
      :ref="(el) => setBubbleEl('brand', el as HTMLElement | null)"
      type="button"
      class="nav-bubble brand-bubble font-display"
      :class="{ entered, hovered: hoveredId === 'brand' }"
      :style="bubbleStyle(layouts.brand)"
      title="Camp Channel"
      @mouseenter="hoveredId = 'brand'"
      @mouseleave="hoveredId = null"
      @click="router.push('/home')"
    >
      <span class="bubble-icon-only">C</span>
      <span class="bubble-label">Camp</span>
    </button>

    <button
      v-for="item in mainNavItems"
      :key="item.id"
      :ref="(el) => setBubbleEl(item.id, el as HTMLElement | null)"
      type="button"
      class="nav-bubble"
      :class="{ entered, active: isActive(item.path), hovered: hoveredId === item.id }"
      :style="bubbleStyle(layouts[item.id])"
      :title="item.label"
      @mouseenter="hoveredId = item.id"
      @mouseleave="hoveredId = null"
      @click="router.push(item.path)"
    >
      <span class="bubble-icon-only" v-html="item.icon" />
      <span class="bubble-label">{{ item.label }}</span>
      <span v-if="item.badge" class="nav-badge">{{ item.badge }}</span>
    </button>

    <button
      v-for="item in footerNavItems"
      :key="item.id"
      :ref="(el) => setBubbleEl(item.id, el as HTMLElement | null)"
      type="button"
      class="nav-bubble"
      :class="{
        entered,
        active: item.path ? isActive(item.path) : false,
        hovered: hoveredId === item.id,
        'avatar-bubble': item.id === 'avatar',
      }"
      :style="bubbleStyle(layouts[item.id])"
      :title="item.label"
      @mouseenter="hoveredId = item.id"
      @mouseleave="hoveredId = null"
      @click="item.action?.()"
    >
      <template v-if="item.id === 'avatar'">
        <img v-if="authStore.user?.avatar" :src="authStore.user.avatar" class="avatar-img" alt="" />
        <span v-else class="avatar-letter">{{ displayName }}</span>
      </template>
      <template v-else>
        <span class="bubble-icon-only" v-html="item.icon" />
        <span class="bubble-label">{{ item.label }}</span>
      </template>
    </button>
  </nav>
</template>

<script setup lang="ts">
import { computed, ref, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { api } from '../api/client'
import {
  buildBubbleLayouts,
  useBubbleMagnet,
  useBubbleEntrance,
  type BubbleLayout,
} from '../composables/useBubbleNav'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()

const { entered } = useBubbleEntrance(100)
const hoveredId = ref<string | null>(null)
const unreadCount = ref(0)
const pendingAppCount = ref(0)

let unreadInterval: ReturnType<typeof setInterval> | null = null
let pendingAppInterval: ReturnType<typeof setInterval> | null = null

const ICON = {
  settings: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>',
  logout: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>',
}

const mainNavItems = computed(() => {
  const items: Array<{ id: string; path: string; label: string; icon: string; badge?: string }> = [
    { id: 'home', path: '/home', label: '首页', icon: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>' },
    { id: 'discover', path: '/channels/search', label: '发现', icon: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polygon points="16.24 7.76 14.12 14.12 7.76 16.24 9.88 9.88 16.24 7.76"/></svg>' },
    { id: 'chat', path: '/chat', label: '消息', icon: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>', badge: unreadCount.value > 0 ? (unreadCount.value > 99 ? '99+' : String(unreadCount.value)) : undefined },
    { id: 'friends', path: '/friends', label: '好友', icon: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8.5" cy="7" r="4"/><polyline points="17 11 19 13 23 9"/></svg>' },
    { id: 'notifications', path: '/notifications', label: '通知', icon: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>' },
    { id: 'tree-hole', path: '/tree-hole', label: '树洞', icon: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2a10 10 0 0 1 10 10c0 5.52-4.48 10-10 10S2 17.52 2 12"/><path d="M12 2c3 3 4 7 4 10s-1 7-4 10"/><circle cx="12" cy="12" r="3"/></svg>' },
    { id: 'announcements', path: '/announcements', label: '公告', icon: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 12h-4l-3 9L9 3l-3 9H2"/></svg>' },
    { id: 'applications', path: '/channels/applications', label: '申请', icon: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>', badge: pendingAppCount.value > 0 ? String(pendingAppCount.value) : undefined },
    { id: 'profile', path: '/profile', label: '我的', icon: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>' },
  ]
  if (authStore.isAdmin) {
    items.push({ id: 'admin', path: '/admin', label: '管理', icon: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>' })
  }
  return items
})

const footerNavItems = computed(() => [
  { id: 'settings', path: '/settings', label: '设置', icon: ICON.settings, action: () => router.push('/settings') },
  { id: 'logout', path: '', label: '退出', icon: ICON.logout, action: handleLogout },
  { id: 'avatar', path: '/profile', label: '头像', icon: '', action: () => router.push('/profile') },
])

const allBubbleIds = computed(() => [
  'brand',
  ...mainNavItems.value.map((i) => i.id),
  ...footerNavItems.value.map((i) => i.id),
])

const { offsets, setBubbleEl, onMouseMove, onMouseLeave } = useBubbleMagnet(() => allBubbleIds.value)

const layouts = computed(() => {
  const map: Record<string, BubbleLayout> = {}
  const brandLayout = buildBubbleLayouts(['brand'], 0, 0)[0]
  map.brand = brandLayout

  const mainIds = mainNavItems.value.map((i) => i.id)
  const mainLayouts = buildBubbleLayouts(mainIds, 64, 56)
  mainLayouts.forEach((l) => { map[l.id] = l })

  const footerStart = 64 + mainIds.length * 56 + 28
  const footerIds = footerNavItems.value.map((i) => i.id)
  const footerLayouts = buildBubbleLayouts(footerIds, footerStart, 56)
  footerLayouts.forEach((l) => { map[l.id] = l })

  return map
})

const fieldHeight = computed(() => {
  const ids = allBubbleIds.value
  if (!ids.length) return 400
  const last = layouts.value[ids[ids.length - 1]]
  return (last?.y ?? 0) + 72
})

function bubbleStyle(layout?: BubbleLayout) {
  if (!layout) return {}
  const mag = offsets.value[layout.id] ?? { x: 0, y: 0 }
  const scatterX = entered.value ? 0 : layout.scatterX
  const scatterY = entered.value ? 0 : layout.scatterY
  const scatterRot = entered.value ? layout.rotate : layout.scatterRotate
  const scale = entered.value ? 1 : 0.45
  const opacity = entered.value ? 1 : 0

  return {
    left: `${12 + layout.x}px`,
    top: `${layout.y}px`,
    transform: `translate(${scatterX + mag.x}px, ${scatterY + mag.y}px) rotate(${scatterRot}deg) scale(${scale})`,
    opacity,
    transitionDelay: `${layout.delay}ms`,
  }
}

function isActive(path: string): boolean {
  if (path === '/home') return route.path === '/home' || route.path === '/' || route.path.startsWith('/post')
  if (path === '/channels/search') return route.path === '/channels/search'
  if (path === '/channels/applications') return route.path === '/channels/applications'
  if (path === '/chat') return route.path.startsWith('/chat')
  if (path === '/friends') return route.path.startsWith('/friends')
  if (path === '/tree-hole') return route.path === '/tree-hole'
  if (path === '/announcements') return route.path === '/announcements'
  if (path === '/admin') return route.path === '/admin'
  return route.path === path
}

function handleLogout() {
  authStore.logout()
  router.push('/login')
}

const displayName = computed(() => {
  const name = authStore.user?.username
  return name ? name.charAt(0).toUpperCase() : '?'
})

async function fetchUnreadCount() {
  if (!authStore.isLoggedIn) return
  try {
    const res = await api.get('/chat/conversations')
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      unreadCount.value = res.data.data.reduce((sum: number, m: { unread?: number }) => sum + (m.unread || 0), 0)
    }
  } catch { /* ignore */ }
}

async function fetchPendingAppCount() {
  if (!authStore.isLoggedIn) return
  try {
    const res = await api.get('/channels/applications/pending/count')
    if (res.data.code === 200) pendingAppCount.value = res.data.data || 0
  } catch { /* ignore */ }
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
</script>

<style scoped>
.nav-bubble-field {
  position: fixed;
  left: 16px;
  top: 50%;
  width: 200px;
  z-index: 200;
  pointer-events: none;
}

.nav-bubble {
  position: absolute;
  pointer-events: auto;
  display: inline-flex;
  align-items: center;
  gap: 0;
  height: 50px;
  min-width: 50px;
  max-width: 50px;
  padding: 0 13px;
  border: 1.5px solid var(--border-color, rgba(255, 255, 255, 0.28));
  border-radius: 18px;
  background: var(--card-bg, rgba(255, 255, 255, 0.12));
  backdrop-filter: blur(24px) saturate(1.35);
  -webkit-backdrop-filter: blur(24px) saturate(1.35);
  box-shadow:
    0 6px 24px rgba(0, 0, 0, 0.1),
    inset 0 1px 0 rgba(255, 255, 255, 0.38);
  color: var(--on-surface-variant);
  cursor: pointer;
  overflow: hidden;
  white-space: nowrap;
  transition:
    transform 0.65s cubic-bezier(0.34, 1.45, 0.64, 1),
    opacity 0.5s ease,
    max-width 0.35s cubic-bezier(0.34, 1.4, 0.64, 1),
    padding 0.35s cubic-bezier(0.34, 1.4, 0.64, 1),
    gap 0.3s ease,
    border-color 0.25s,
    box-shadow 0.3s,
    color 0.2s;
  will-change: transform, opacity;
}

.nav-bubble.entered {
  animation: bubble-breathe 5s ease-in-out infinite;
}

.nav-bubble.hovered,
.nav-bubble.active {
  animation: none;
  z-index: 10;
}

.nav-bubble.hovered {
  max-width: 148px;
  gap: 10px;
  padding: 0 16px 0 13px;
  color: var(--text, var(--on-surface));
  border-color: color-mix(in srgb, var(--brand, #35bfab) 45%, var(--border-color));
  box-shadow:
    0 10px 32px color-mix(in srgb, var(--brand, #35bfab) 18%, transparent),
    inset 0 1px 0 rgba(255, 255, 255, 0.45);
}

.nav-bubble.active {
  color: var(--brand, var(--primary));
  border-color: color-mix(in srgb, var(--brand, #35bfab) 55%, white);
  background: color-mix(in srgb, var(--brand, #35bfab) 14%, var(--card-bg));
}

.brand-bubble {
  min-width: 50px;
  max-width: 50px;
  background: linear-gradient(135deg, var(--brand, #35bfab), var(--brand-secondary, #1fc9e7));
  color: #fff;
  border-color: rgba(255, 255, 255, 0.45);
  font-size: 20px;
}

.brand-bubble.hovered {
  max-width: 130px;
  color: #fff;
}

.bubble-icon-only {
  flex-shrink: 0;
  width: 22px;
  height: 22px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: transform 0.35s cubic-bezier(0.34, 1.5, 0.64, 1);
}

.nav-bubble.hovered .bubble-icon-only {
  transform: scale(1.12) rotate(-5deg);
}

.bubble-label {
  font-size: 13px;
  font-weight: 600;
  opacity: 0;
  max-width: 0;
  overflow: hidden;
  transition: opacity 0.25s, max-width 0.35s cubic-bezier(0.34, 1.4, 0.64, 1);
}

.nav-bubble.hovered .bubble-label {
  opacity: 1;
  max-width: 90px;
}

.avatar-bubble {
  border-radius: 50%;
  min-width: 50px;
  max-width: 50px;
  width: 50px;
  height: 50px;
  padding: 0;
  overflow: hidden;
  justify-content: center;
}

.avatar-bubble.hovered {
  max-width: 50px;
  border-radius: 50%;
}

.avatar-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.avatar-letter {
  font-size: 17px;
  font-weight: 700;
  color: var(--brand, var(--primary));
}

.nav-badge {
  position: absolute;
  top: -4px;
  right: -4px;
  min-width: 17px;
  height: 17px;
  border-radius: 9px;
  background: #ff4757;
  color: #fff;
  font-size: 9px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0 4px;
  border: 2px solid var(--background, #1a2224);
  box-shadow: 0 2px 8px rgba(255, 71, 87, 0.5);
  animation: badge-pulse 2s ease-in-out infinite;
}

@keyframes bubble-breathe {
  0%, 100% { filter: brightness(1); }
  50% { filter: brightness(1.06); }
}

@keyframes badge-pulse {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.1); }
}
</style>
