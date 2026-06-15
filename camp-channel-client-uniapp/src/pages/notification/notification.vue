<template>
  <view class="notify-container" @touchstart.capture="onTouchStart" @touchend.capture="onTouchEnd">
    <view class="tabs">
      <view class="tab" :class="{ active: activeTab === 'all' }" @tap="activeTab = 'all'">
        <text>全部</text>
      </view>
      <view class="tab" :class="{ active: activeTab === 'interaction' }" @tap="activeTab = 'interaction'">
        <text>互动</text>
      </view>
      <view class="tab" :class="{ active: activeTab === 'chat' }" @tap="activeTab = 'chat'">
        <text>聊天</text>
      </view>
      <view class="tab" :class="{ active: activeTab === 'system' }" @tap="activeTab = 'system'">
        <text>系统</text>
      </view>
    </view>

    <view class="mark-all" @tap="markAllRead" v-if="hasUnread">
      <text>全部已读</text>
    </view>

    <view v-if="filteredNotifications.length === 0" class="empty-state">
      <text class="empty-icon">🔔</text>
      <text class="empty-text">暂无通知</text>
    </view>

    <view
      v-for="n in filteredNotifications"
      :key="n.id"
      class="notify-item"
      :class="{ unread: !n.read }"
      @tap="handleTap(n)"
    >
      <view class="notify-icon-wrapper">
        <view class="notify-icon" :style="{ background: n.color || 'var(--primary-soft)' }">
          <text>{{ n.icon || '📢' }}</text>
        </view>
      </view>
      <view class="notify-body">
        <view class="notify-top">
          <text class="notify-title">{{ n.title }}</text>
          <text class="notify-time">{{ n.createdAt }}</text>
        </view>
        <text class="notify-content">{{ n.content }}</text>
      </view>
      <view v-if="!n.read" class="notify-dot"></view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '../../stores/auth'
import request from '../../utils/request'
import { useSwipeTab } from '../../utils/useSwipeTab'

const { onTouchStart, onTouchEnd } = useSwipeTab()

const authStore = useAuthStore()

const activeTab = ref('all')
const notifications = ref<any[]>([])
const page = ref(1)
const hasMore = ref(true)

const hasUnread = computed(() => notifications.value.some((n) => !n.read))

const filteredNotifications = computed(() => {
  if (activeTab.value === 'all') return notifications.value
  return notifications.value.filter((n) => n.category === activeTab.value)
})

onMounted(() => {
  if (!authStore.token) {
    uni.reLaunch({ url: '/pages/login/login' })
    return
  }
  loadNotifications()
})

async function loadNotifications() {
  try {
    const res = await request<any>(`/notifications/history?page=${page.value}&size=30`)
    if (res?.code === 200) {
      const list = (res.data || []).map((n: any) => ({
        id: n.id,
        type: n.type || 'system',
        category: n.category || 'system',
        icon: n.type === 'like' ? '❤️' : n.type === 'comment' ? '💬' : n.type === 'follow' ? '👤' : n.type === 'mention' ? '@' : '📢',
        title: n.title || '',
        content: n.content || '',
        createdAt: formatTime(n.createTime || n.createdAt),
        read: n.isRead === 1 || n.isRead === true,
        relatedId: n.relatedId,
        color: n.type === 'like' ? '#f38ba8' : n.type === 'comment' ? '#89b4fa' : n.category === 'interaction' ? '#a6e3a1' : '#cba6f7',
      }))
      if (page.value === 1) {
        notifications.value = list
      } else {
        notifications.value = [...notifications.value, ...list]
      }
      if (list.length < 30) hasMore.value = false
    }
  } catch (_) {}
}

async function markAllRead() {
  try {
    const res = await request<any>({ url: '/notifications/read-all', method: 'POST' })
    if (res?.code === 200) {
      notifications.value.forEach((n) => (n.read = true))
      uni.showToast({ title: '已全部标记为已读', icon: 'success' })
    }
  } catch (_) {}
}

function handleTap(n: any) {
  if (!n.read) {
    n.read = true
    request<any>({ url: `/notifications/${n.id}/read`, method: 'POST' }).catch(() => {})
  }
  // Navigate based on notification type
  if (n.type === 'like' || n.type === 'comment' || n.type === 'mention') {
    if (n.relatedId) {
      uni.navigateTo({ url: `/pages/post/detail?id=${n.relatedId}` })
    }
  } else if (n.type === 'follow') {
    // Could navigate to follower profile
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
</script>

<style>
.notify-container {
  min-height: 100vh;
  background: var(--bg);
  padding: 30rpx;
  box-sizing: border-box;
}

.tabs {
  display: flex;
  gap: 12rpx;
  margin-bottom: 20rpx;
}

.tab {
  padding: 14rpx 32rpx;
  border-radius: 100rpx;
  font-size: 26rpx;
  color: var(--text-secondary);
  background: var(--bg);
}

.tab.active {
  background: var(--primary);
  color: #ffffff;
  font-weight: 600;
  box-shadow: 0 4rpx 12rpx rgba(99, 102, 241, 0.25);
}

.mark-all {
  text-align: right;
  padding: 0 0 16rpx 0;
  font-size: 24rpx;
  color: var(--primary);
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding-top: 160rpx;
}

.empty-icon {
  font-size: 100rpx;
  margin-bottom: 20rpx;
}

.empty-text {
  font-size: 28rpx;
  color: var(--text-muted);
}

.notify-item {
  display: flex;
  align-items: flex-start;
  padding: 28rpx;
  background: var(--card);
  border: 1rpx solid var(--card-border);
  border-radius: var(--radius);
  margin-bottom: 16rpx;
  box-shadow: var(--shadow-sm);
}

.notify-item.unread {
  border-left: 6rpx solid var(--primary);
}

.notify-icon-wrapper {
  margin-right: 20rpx;
  flex-shrink: 0;
}

.notify-icon {
  width: 64rpx;
  height: 64rpx;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28rpx;
}

.notify-body {
  flex: 1;
  min-width: 0;
}

.notify-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 8rpx;
}

.notify-title {
  font-size: 28rpx;
  font-weight: 600;
  color: var(--text);
}

.notify-time {
  font-size: 20rpx;
  color: var(--text-muted);
  flex-shrink: 0;
}

.notify-content {
  font-size: 26rpx;
  color: var(--text-secondary);
  line-height: 1.4;
  display: block;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.notify-dot {
  width: 12rpx;
  height: 12rpx;
  border-radius: 50%;
  background: var(--accent);
  position: absolute;
  top: 20rpx;
  right: 20rpx;
}
</style>
