<template>
  <view class="chat-list-container" @touchstart.capture="onTouchStart" @touchend.capture="onTouchEnd">
    <view v-if="sessions.length === 0" class="empty-state">
      <text class="empty-icon">💬</text>
      <text class="empty-text">暂无会话</text>
    </view>

    <view
      v-for="s in sessions"
      :key="s.id"
      class="session-item"
      @tap="goChat(s)"
    >
      <view class="session-avatar-wrapper">
        <image v-if="s.avatar" :src="s.avatar" mode="aspectFill" class="session-avatar-img" />
        <view v-else class="session-avatar" :style="{ background: s.color || 'var(--primary)' }">
          <text>{{ s.name?.charAt(0) || '?' }}</text>
        </view>
        <view v-if="s.online" class="online-dot"></view>
      </view>
      <view class="session-info">
        <view class="session-top">
          <text class="session-name">{{ s.name }}</text>
          <text class="session-time">{{ s.lastTime }}</text>
        </view>
        <view class="session-bottom">
          <text class="session-preview">{{ s.lastMessage }}</text>
          <view v-if="s.unreadCount" class="unread-badge">
            <text class="unread-text">{{ s.unreadCount > 99 ? '99+' : s.unreadCount }}</text>
          </view>
        </view>
      </view>
    </view>

    <view v-if="loading" class="loading-state">
      <text>加载中...</text>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { useAuthStore } from '../../stores/auth'
import request, { processImageUrl } from '../../utils/request'
import wsManager from '../../utils/websocket'
import { useSwipeTab } from '../../utils/useSwipeTab'

const { onTouchStart, onTouchEnd } = useSwipeTab()

const authStore = useAuthStore()

interface Session {
  id: number
  name: string
  avatar: string
  color: string
  lastMessage: string
  lastTime: string
  unreadCount: number
  friendId?: number
  online?: boolean
}

const sessions = ref<Session[]>([])
const loading = ref(false)
let pollTimer: any = null

let unsubscribeMessage: (() => void) | null = null
let unsubscribeRead: (() => void) | null = null
let unsubscribeOnline: (() => void) | null = null

onMounted(() => {
  if (!authStore.token) {
    uni.reLaunch({ url: '/pages/login/login' })
    return
  }
  loadSessions()
  clearBadge()
  connectWebSocket()
  startPolling()
})

onUnmounted(() => {
  // Unsubscribe from WebSocket events
  if (unsubscribeMessage) unsubscribeMessage()
  if (unsubscribeRead) unsubscribeRead()
  if (unsubscribeOnline) unsubscribeOnline()
  if (pollTimer) clearInterval(pollTimer)
})

function clearBadge() {
  uni.removeTabBarBadge({ index: 2 })
}

async function loadSessions() {
  loading.value = true
  try {
    const res = await request<any>('/chat/conversations/with-unread')
    if (res?.code === 200) {
      sessions.value = (res.data || []).map((s: any) => ({
        id: s.conversationId || s.id,
        name: s.username || '未知',
        avatar: processImageUrl(s.avatar || ''),
        color: s.color || '#7C9FCB',
        lastMessage: s.lastMsg || '',
        lastTime: formatTime(s.createTime),
        unreadCount: s.unread || 0,
        friendId: s.id,
        online: s.online || false,
      }))
      // Update tab badge
      const total = sessions.value.reduce((sum, s) => sum + s.unreadCount, 0)
      if (total > 0) {
        uni.setTabBarBadge({ index: 2, text: total > 99 ? '99+' : String(total) })
      }
    }
  } catch (_) {
    uni.showToast({ title: '加载失败', icon: 'none' })
  } finally {
    loading.value = false
  }
}

function formatTime(t: string): string {
  if (!t) return ''
  const d = new Date(t)
  const now = new Date()
  const diff = now.getTime() - d.getTime()
  if (diff < 60000) return '刚刚'
  if (diff < 3600000) return `${Math.floor(diff / 60000)}分钟前`
  if (diff < 86400000) return `${Math.floor(diff / 3600000)}小时前`
  if (diff < 172800000) return '昨天'
  return `${d.getMonth() + 1}/${d.getDate()}`
}

function goChat(s: Session) {
  // Mark as read using correct endpoint
  request<any>({
    url: `/chat/read-all/${s.friendId || s.id}`,
    method: 'POST',
  }).catch(() => {})
  uni.navigateTo({
    url: `/pages/chat/detail?friendId=${s.friendId || s.id}&name=${encodeURIComponent(s.name)}&avatar=${encodeURIComponent(s.avatar)}&conversationId=${s.id}`,
  })
}

function connectWebSocket() {
  wsManager.connect().then(() => {
    console.log('[Chat] WebSocket connected')
    
    // Subscribe to new message events
    unsubscribeMessage = wsManager.on('new_message', () => {
      console.log('[Chat] New message received')
      loadSessions()
    })
    
    // Subscribe to message read events
    unsubscribeRead = wsManager.on('message_read', () => {
      console.log('[Chat] Message read event')
      loadSessions()
    })
    
    // Subscribe to online status events
    unsubscribeOnline = wsManager.on('online_status', (data) => {
      const idx = sessions.value.findIndex((s) => s.friendId === data.userId)
      if (idx !== -1) {
        sessions.value[idx].online = data.online
      }
    })
  }).catch((err) => {
    console.error('[Chat] WebSocket connection failed:', err)
  })
}

function startPolling() {
  pollTimer = setInterval(() => {
    loadSessions()
  }, 30000)
}
</script>

<style>
.chat-list-container {
  min-height: 100vh;
  background: transparent;
  padding: 20rpx 0;
  box-sizing: border-box;
  padding-bottom: 20rpx;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding-top: 200rpx;
}

.empty-icon {
  font-size: 100rpx;
  margin-bottom: 20rpx;
}

.empty-text {
  font-size: 28rpx;
  color: rgba(232, 239, 247, 0.5);
}

.loading-state {
  text-align: center;
  padding: 40rpx;
  color: rgba(232, 239, 247, 0.5);
  font-size: 26rpx;
}

.session-item {
  display: flex;
  align-items: center;
  padding: 24rpx 30rpx;
  background: rgba(124, 159, 203, 0.08);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  margin: 0 20rpx 12rpx 20rpx;
  border-radius: 20rpx;
  border: 1rpx solid rgba(124, 159, 203, 0.15);
  position: relative;
  overflow: hidden;
}

.session-item::before {
  content: '';
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  background: linear-gradient(135deg,
    rgba(255, 255, 255, 0.05) 0%,
    rgba(255, 255, 255, 0.02) 50%,
    transparent 100%);
  pointer-events: none;
  border-radius: 20rpx;
}

.session-avatar {
  width: 88rpx;
  height: 88rpx;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 36rpx;
  color: #ffffff;
  font-weight: bold;
  margin-right: 24rpx;
  flex-shrink: 0;
}

.session-avatar-img {
  width: 88rpx;
  height: 88rpx;
  border-radius: 50%;
  margin-right: 24rpx;
  flex-shrink: 0;
}

.session-avatar-wrapper {
  position: relative;
  margin-right: 24rpx;
  flex-shrink: 0;
  z-index: 1;
}

.session-avatar-wrapper .session-avatar,
.session-avatar-wrapper .session-avatar-img {
  margin-right: 0;
}

.online-dot {
  position: absolute;
  bottom: 2rpx;
  right: 4rpx;
  width: 18rpx;
  height: 18rpx;
  border-radius: 50%;
  background-color: #2ecc71;
  border: 3rpx solid #0F1923;
  z-index: 2;
}

.session-info {
  flex: 1;
  min-width: 0;
  z-index: 1;
  position: relative;
}

.session-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10rpx;
}

.session-name {
  font-size: 30rpx;
  font-weight: 600;
  color: #E8EFF7;
}

.session-time {
  font-size: 22rpx;
  color: rgba(232, 239, 247, 0.5);
  flex-shrink: 0;
}

.session-bottom {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.session-preview {
  font-size: 26rpx;
  color: rgba(232, 239, 247, 0.6);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  flex: 1;
}

.unread-badge {
  min-width: 36rpx;
  height: 36rpx;
  border-radius: 18rpx;
  background: #F2B5D4;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-left: 12rpx;
  flex-shrink: 0;
  padding: 0 8rpx;
}

.unread-text {
  color: #ffffff;
  font-size: 20rpx;
  font-weight: bold;
}
</style>
