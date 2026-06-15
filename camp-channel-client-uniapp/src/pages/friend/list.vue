<template>
  <view class="friend-list-container">
    <view class="search-bar" @tap="goSearch">
      <view class="search-input-wrapper">
        <text class="search-icon">🔍</text>
        <text class="search-placeholder">搜索好友</text>
      </view>
    </view>

    <view v-if="pendingRequests.length > 0" class="section">
      <view class="section-header" @tap="showPending = !showPending">
        <text class="section-title">待处理申请 ({{ pendingRequests.length }})</text>
        <text class="arrow">{{ showPending ? '▼' : '▶' }}</text>
      </view>
      <view v-if="showPending">
        <view v-for="r in pendingRequests" :key="r.id" class="request-item">
          <image v-if="r.avatar" :src="r.avatar" mode="aspectFill" class="request-avatar" />
          <view v-else class="request-avatar-placeholder">
            <text>{{ r.username?.charAt(0) || '?' }}</text>
          </view>
          <text class="request-name">{{ r.username }}</text>
          <view class="request-actions">
            <button class="btn-approve" @tap="handleRequest(r.id, 'APPROVED')">同意</button>
            <button class="btn-reject" @tap="handleRequest(r.id, 'REJECTED')">拒绝</button>
          </view>
        </view>
      </view>
    </view>

    <view class="section">
      <view class="section-header">
        <text class="section-title">好友列表 ({{ friends.length }})</text>
      </view>

      <view v-for="f in friends" :key="f.id" class="friend-item" @tap="goChat(f)">
        <image v-if="f.avatar" :src="f.avatar" mode="aspectFill" class="friend-avatar-img" />
        <view v-else class="friend-avatar" :style="{ background: f.color || 'var(--primary)' }">
          <text>{{ f.username?.charAt(0) || '?' }}</text>
        </view>
        <view class="friend-info">
          <text class="friend-name">{{ f.username }}</text>
          <text class="friend-desc">{{ f.email || f.description || '' }}</text>
        </view>
        <view class="friend-status" :class="{ online: f.online }">
          <text class="status-dot"></text>
        </view>
      </view>

      <view v-if="friends.length === 0 && !loading" class="empty-state">
        <text>暂无好友，去搜索添加吧</text>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import request, { processImageUrl } from '../../utils/request'
import { useAuthStore } from '../../stores/auth'
import wsManager from '../../utils/websocket'

const authStore = useAuthStore()

interface Friend {
  id: number
  username: string
  avatar: string
  color: string
  email: string
  description: string
  online: boolean
}

const friends = ref<Friend[]>([])
const pendingRequests = ref<any[]>([])
const showPending = ref(true)
const loading = ref(false)
let pollTimer: any = null

let unsubscribeOnline: (() => void) | null = null

onMounted(async () => {
  if (!authStore.token) {
    uni.reLaunch({ url: '/pages/login/login' })
    return
  }
  await Promise.all([loadFriends(), loadPendingRequests()])
  startPolling()
  connectWebSocket()
})

onUnmounted(() => {
  if (unsubscribeOnline) unsubscribeOnline()
  if (pollTimer) clearInterval(pollTimer)
})

async function loadFriends() {
  loading.value = true
  try {
    const friendsRes = await request<any>('/friends/list')
    if (friendsRes?.code === 200) {
      const friendList = friendsRes.data || []
      // Try to get online status, but don't fail if unavailable
      let onlineMap: Record<number, boolean> = {}
      try {
        if (friendList.length > 0) {
          const ids = friendList.map((f: any) => f.id).join(',')
          const onlineRes = await request<any>(`/chat/online/batch?userIds=${ids}`)
          if (onlineRes?.code === 200 && onlineRes.data) {
            onlineMap = onlineRes.data
          }
        }
      } catch (_) {}
      friends.value = friendList.map((f: any) => ({
        id: f.id,
        username: f.username || '未知',
        avatar: processImageUrl(f.avatar || ''),
        color: f.color || '#7C9FCB',
        email: f.email || '',
        description: f.description || '',
        online: onlineMap[f.id] || false,
      }))
    }
  } catch (_) {
    uni.showToast({ title: '加载好友列表失败', icon: 'none' })
  } finally {
    loading.value = false
  }
}

async function startPolling() {
  pollTimer = setInterval(async () => {
    try {
      if (friends.value.length === 0) return
      const ids = friends.value.map((f) => f.id).join(',')
      const onlineRes = await request<any>(`/chat/online/batch?userIds=${ids}`)
      if (onlineRes?.code === 200 && onlineRes.data) {
        const onlineMap: Record<number, boolean> = onlineRes.data
        friends.value.forEach((f) => {
          f.online = onlineMap[f.id] || false
        })
      }
    } catch (_) {}
  }, 30000)
}

function connectWebSocket() {
  wsManager.connect().then(() => {
    console.log('[Friend] WebSocket connected')
    
    // Subscribe to online status events
    unsubscribeOnline = wsManager.on('online_status', (data) => {
      const idx = friends.value.findIndex((f) => f.id === data.userId)
      if (idx !== -1) {
        friends.value[idx].online = data.online
      }
    })
  }).catch((err) => {
    console.error('[Friend] WebSocket connection failed:', err)
  })
}

async function loadPendingRequests() {
  try {
    const res = await request<any>('/friends/requests/pending')
    if (res?.code === 200) {
      const list = res.data || []
      // Friendship only has userId (sender), fetch sender info
      const requests = await Promise.all(list.map(async (r: any) => {
        try {
          const userRes = await request<any>(`/users/${r.userId}`)
          if (userRes?.code === 200) {
            return {
              id: r.id,
              username: userRes.data.username || '未知',
              avatar: processImageUrl(userRes.data.avatar || ''),
            }
          }
        } catch (_) {}
        return {
          id: r.id,
          username: '未知',
          avatar: '',
        }
      }))
      pendingRequests.value = requests
    }
  } catch (_) {}
}

async function handleRequest(requestId: number, status: string) {
  try {
    const url = status === 'APPROVED' 
      ? `/friends/requests/${requestId}/approve`
      : `/friends/requests/${requestId}/reject`
    const res = await request<any>({
      url,
      method: 'POST',
    })
    if (res?.code === 200) {
      uni.showToast({ title: status === 'APPROVED' ? '已添加好友' : '已拒绝', icon: 'success' })
      pendingRequests.value = pendingRequests.value.filter((r) => r.id !== requestId)
      if (status === 'APPROVED') loadFriends()
    }
  } catch (_) {}
}

function goChat(f: Friend) {
  uni.navigateTo({ url: `/pages/chat/detail?friendId=${f.id}&name=${f.username}` })
}

function goSearch() {
  uni.navigateTo({ url: '/pages/friend/search' })
}
</script>

<style>
.friend-list-container {
  min-height: 100vh;
  background: var(--bg);
  padding: 30rpx;
  box-sizing: border-box;
}

.search-bar {
  margin-bottom: 30rpx;
}

.search-input-wrapper {
  display: flex;
  align-items: center;
  background: var(--card);
  border: 1rpx solid var(--card-border);
  border-radius: 100rpx;
  padding: 0 30rpx;
  height: 80rpx;
  box-shadow: var(--shadow-sm);
}

.search-icon {
  font-size: 28rpx;
  margin-right: 16rpx;
}

.search-placeholder {
  font-size: 28rpx;
  color: var(--text-muted);
}

.section {
  margin-bottom: 40rpx;
}

.section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 20rpx;
}

.section-title {
  font-size: 30rpx;
  font-weight: bold;
  color: var(--text);
  padding-left: 12rpx;
  border-left: 6rpx solid var(--primary);
}

.arrow {
  font-size: 24rpx;
  color: var(--text-muted);
}

.request-item {
  display: flex;
  align-items: center;
  padding: 20rpx;
  background: var(--card);
  border: 1rpx solid var(--card-border);
  border-radius: var(--radius);
  margin-bottom: 12rpx;
  box-shadow: var(--shadow-sm);
}

.request-avatar {
  width: 64rpx;
  height: 64rpx;
  border-radius: 50%;
  margin-right: 16rpx;
}

.request-avatar-placeholder {
  width: 64rpx;
  height: 64rpx;
  border-radius: 50%;
  background: var(--primary-soft);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 26rpx;
  color: var(--primary);
  font-weight: bold;
  margin-right: 16rpx;
  flex-shrink: 0;
}

.request-name {
  flex: 1;
  font-size: 28rpx;
  color: var(--text);
}

.request-actions {
  display: flex;
  gap: 12rpx;
}

.btn-approve {
  height: 56rpx;
  padding: 0 24rpx;
  background: var(--primary-gradient);
  border-radius: 28rpx;
  color: #ffffff;
  font-size: 22rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
  box-shadow: 0 4rpx 12rpx rgba(99, 102, 241, 0.2);
}

.btn-reject {
  height: 56rpx;
  padding: 0 24rpx;
  background: var(--accent-soft);
  border-radius: 28rpx;
  color: var(--accent);
  font-size: 22rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
}

.btn-approve::after,
.btn-reject::after {
  border: none;
}

.friend-item {
  display: flex;
  align-items: center;
  padding: 24rpx 20rpx;
  background: var(--card);
  border: 1rpx solid var(--card-border);
  border-radius: var(--radius);
  margin-bottom: 12rpx;
  box-shadow: var(--shadow-sm);
}

.friend-avatar {
  width: 80rpx;
  height: 80rpx;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 32rpx;
  color: #ffffff;
  font-weight: bold;
  margin-right: 20rpx;
  flex-shrink: 0;
}

.friend-avatar-img {
  width: 80rpx;
  height: 80rpx;
  border-radius: 50%;
  margin-right: 20rpx;
  flex-shrink: 0;
}

.friend-info {
  flex: 1;
  min-width: 0;
}

.friend-name {
  font-size: 30rpx;
  font-weight: 600;
  color: var(--text);
  display: block;
  margin-bottom: 6rpx;
}

.friend-desc {
  font-size: 24rpx;
  color: var(--text-secondary);
}

.friend-status {
  width: 16rpx;
  height: 16rpx;
  border-radius: 50%;
  background-color: var(--card-border);
  flex-shrink: 0;
  margin-left: 16rpx;
}

.friend-status.online {
  background-color: var(--success);
}

.empty-state {
  text-align: center;
  padding: 40rpx;
  color: var(--text-muted);
  font-size: 26rpx;
}
</style>
