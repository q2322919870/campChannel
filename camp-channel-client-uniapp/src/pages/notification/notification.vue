<template>
  <view class="notify-container" @touchstart.capture="onTouchStart" @touchend.capture="onTouchEnd">
    <view class="tabs">
      <view class="tab" :class="{ active: activeTab === 'all' }" @tap="activeTab = 'all'">
        <text>全部</text>
      </view>
      <view class="tab" :class="{ active: activeTab === 'like' }" @tap="activeTab = 'like'">
        <text>赞</text>
      </view>
      <view class="tab" :class="{ active: activeTab === 'comment' }" @tap="activeTab = 'comment'">
        <text>评论</text>
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

const hasUnread = computed(() => notifications.value.some((n) => !n.read))

const filteredNotifications = computed(() => {
  if (activeTab.value === 'all') return notifications.value
  return notifications.value.filter((n) => n.type === activeTab.value)
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
    const res = await request<any>('/notifications/unread')
    if (res?.code === 200) {
      notifications.value = (res.data || []).map((n: any) => ({
        id: n.id,
        type: n.type || 'system',
        icon: n.type === 'like' ? '❤️' : n.type === 'comment' ? '💬' : '📢',
        title: n.title || '',
        content: n.content || '',
        createdAt: formatTime(n.createdAt),
        read: n.read || false,
        color: n.type === 'like' ? '#f38ba8' : n.type === 'comment' ? '#89b4fa' : '#a6e3a1',
      }))
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
  background: #0F1923;
  padding: 30rpx;
  box-sizing: border-box;
  padding-bottom: 30rpx;
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
  color: rgba(232, 239, 247, 0.6);
  background: rgba(124, 159, 203, 0.08);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1rpx solid rgba(124, 159, 203, 0.15);
}

.tab.active {
  background: rgba(124, 159, 203, 0.15);
  color: #7C9FCB;
  border-color: #7C9FCB;
  font-weight: 600;
}

.mark-all {
  text-align: right;
  padding: 0 0 16rpx 0;
  font-size: 24rpx;
  color: #7C9FCB;
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
  color: rgba(232, 239, 247, 0.4);
}

.notify-item {
  display: flex;
  align-items: flex-start;
  padding: 28rpx;
  background: rgba(124, 159, 203, 0.08);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1rpx solid rgba(124, 159, 203, 0.15);
  border-radius: 24rpx;
  margin-bottom: 16rpx;
  position: relative;
  overflow: hidden;
}

.notify-item::before {
  content: '';
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  background: linear-gradient(135deg, rgba(255,255,255,0.05) 0%, rgba(255,255,255,0.02) 50%, transparent 100%);
  pointer-events: none;
  border-radius: 24rpx;
}

.notify-item.unread {
  border-left: 6rpx solid #7C9FCB;
}

.notify-icon-wrapper {
  margin-right: 20rpx;
  flex-shrink: 0;
  position: relative;
  z-index: 1;
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
  position: relative;
  z-index: 1;
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
  color: #E8EFF7;
}

.notify-time {
  font-size: 20rpx;
  color: rgba(232, 239, 247, 0.5);
  flex-shrink: 0;
}

.notify-content {
  font-size: 26rpx;
  color: rgba(232, 239, 247, 0.6);
  line-height: 1.4;
  display: block;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  position: relative;
  z-index: 1;
}

.notify-dot {
  width: 12rpx;
  height: 12rpx;
  border-radius: 50%;
  background: #F2B5D4;
  position: absolute;
  top: 20rpx;
  right: 20rpx;
  z-index: 1;
}
</style>
