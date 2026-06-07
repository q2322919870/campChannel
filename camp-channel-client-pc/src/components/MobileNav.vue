<template>
  <nav
    class="mobile-bubble-nav"
    @mousemove="onMouseMove"
    @mouseleave="onMouseLeave"
    @touchmove.passive="onTouchMove"
    @touchend="onTouchEnd"
  >
    <button
      v-for="item in navItems"
      :key="item.id"
      :ref="(el) => setBubbleEl(item.id, el as HTMLElement | null)"
      type="button"
      class="mobile-bubble"
      :class="{ entered, active: isActive(item.path), hovered: hoveredId === item.id }"
      :style="bubbleStyle(layouts[item.id])"
      @mouseenter="hoveredId = item.id"
      @mouseleave="hoveredId = null"
      @click="router.push(item.path)"
    >
      <span class="bubble-icon" v-html="item.icon" />
      <span class="bubble-text">{{ item.label }}</span>
      <span v-if="item.badge" class="nav-badge">{{ item.badge }}</span>
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

const { entered } = useBubbleEntrance(150)
const hoveredId = ref<string | null>(null)
const unreadCount = ref(0)

let unreadInterval: ReturnType<typeof setInterval> | null = null

const navItems = computed(() => {
  const items: Array<{ id: string; path: string; label: string; icon: string; badge?: string }> = [
    { id: 'home', path: '/home', label: '首页', icon: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>' },
    { id: 'discover', path: '/channels/search', label: '发现', icon: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polygon points="16.24 7.76 14.12 14.12 7.76 16.24 9.88 9.88 16.24 7.76"/></svg>' },
    { id: 'chat', path: '/chat', label: '消息', icon: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>', badge: unreadCount.value > 0 ? (unreadCount.value > 99 ? '99+' : String(unreadCount.value)) : undefined },
    { id: 'tree-hole', path: '/tree-hole', label: '树洞', icon: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2a10 10 0 0 1 10 10c0 5.52-4.48 10-10 10S2 17.52 2 12"/><path d="M12 2c3 3 4 7 4 10s-1 7-4 10"/><circle cx="12" cy="12" r="3"/></svg>' },
    { id: 'profile', path: '/profile', label: '我的', icon: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>' },
  ]
  if (authStore.isAdmin) {
    items.splice(4, 0, { id: 'admin', path: '/admin', label: '管理', icon: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>' })
  }
  return items
})

const bubbleIds = computed(() => navItems.value.map((i) => i.id))
const { offsets, setBubbleEl, onMouseMove, onMouseLeave } = useBubbleMagnet(() => bubbleIds.value)

const layouts = computed(() => {
  const map: Record<string, BubbleLayout> = {}
  buildBubbleLayouts(bubbleIds.value, 0, 0).forEach((l, i) => {
    map[l.id] = {
      ...l,
      scatterX: (i - 2) * 40,
      scatterY: 80 + Math.abs(i - 2) * 25,
      scatterRotate: (i - 2) * 8,
      delay: i * 50,
    }
  })
  return map
})

function bubbleStyle(layout?: BubbleLayout) {
  if (!layout) return {}
  const mag = offsets.value[layout.id] ?? { x: 0, y: 0 }
  const scatterX = entered.value ? 0 : layout.scatterX
  const scatterY = entered.value ? 0 : layout.scatterY
  const scatterRot = entered.value ? 0 : layout.scatterRotate
  const scale = entered.value ? 1 : 0.5

  return {
    transform: `translate(${scatterX + mag.x}px, ${scatterY + mag.y}px) rotate(${scatterRot}deg) scale(${scale})`,
    opacity: entered.value ? 1 : 0,
    transitionDelay: `${layout.delay}ms`,
  }
}

function onTouchMove(e: TouchEvent) {
  const t = e.touches[0]
  if (!t) return
  onMouseMove({ clientX: t.clientX, clientY: t.clientY } as MouseEvent)
}

function onTouchEnd() {
  onMouseLeave()
}

function isActive(path: string): boolean {
  if (path === '/home') return route.path === '/home' || route.path === '/' || route.path.startsWith('/post')
  if (path === '/chat') return route.path.startsWith('/chat')
  if (path === '/tree-hole') return route.path === '/tree-hole'
  if (path === '/profile') return route.path === '/profile' || route.path === '/settings'
  if (path === '/channels/search') return route.path === '/channels/search'
  if (path === '/admin') return route.path === '/admin'
  return route.path === path
}

async function fetchUnreadCount() {
  try {
    const res = await api.get('/chat/conversations')
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      unreadCount.value = res.data.data.reduce((sum: number, m: { unread?: number }) => sum + (m.unread || 0), 0)
    }
  } catch { /* ignore */ }
}

onMounted(() => {
  fetchUnreadCount()
  unreadInterval = setInterval(fetchUnreadCount, 30000)
})

onUnmounted(() => {
  if (unreadInterval) clearInterval(unreadInterval)
})
</script>

<style scoped>
.mobile-bubble-nav {
  position: fixed;
  bottom: 14px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 200;
  display: flex;
  align-items: flex-end;
  justify-content: center;
  gap: 8px;
  padding: 10px 12px;
  padding-bottom: max(10px, env(safe-area-inset-bottom));
  width: calc(100% - 20px);
  max-width: 440px;
  border-radius: 28px;
  background: var(--card-bg, rgba(255, 255, 255, 0.1));
  border: 1.5px solid var(--border-color, rgba(255, 255, 255, 0.25));
  backdrop-filter: blur(28px) saturate(1.35);
  -webkit-backdrop-filter: blur(28px) saturate(1.35);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.14);
}

.mobile-bubble {
  position: relative;
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 3px;
  padding: 8px 4px;
  border: 1.5px solid transparent;
  border-radius: 16px;
  background: transparent;
  color: var(--on-surface-variant);
  cursor: pointer;
  -webkit-tap-highlight-color: transparent;
  transition:
    transform 0.6s cubic-bezier(0.34, 1.45, 0.64, 1),
    opacity 0.45s ease,
    background 0.25s,
    border-color 0.25s,
    color 0.2s;
  will-change: transform, opacity;
}

.mobile-bubble.hovered,
.mobile-bubble.active {
  background: color-mix(in srgb, var(--brand, #35bfab) 12%, transparent);
  border-color: color-mix(in srgb, var(--brand, #35bfab) 35%, transparent);
  color: var(--brand, var(--primary));
}

.bubble-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  transition: transform 0.3s cubic-bezier(0.34, 1.5, 0.64, 1);
}

.mobile-bubble.hovered .bubble-icon,
.mobile-bubble.active .bubble-icon {
  transform: scale(1.15) translateY(-2px);
}

.bubble-text {
  font-size: 10px;
  font-weight: 600;
}

.nav-badge {
  position: absolute;
  top: 2px;
  right: 2px;
  min-width: 15px;
  height: 15px;
  border-radius: 8px;
  background: #ff4757;
  color: #fff;
  font-size: 8px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0 3px;
}
</style>
