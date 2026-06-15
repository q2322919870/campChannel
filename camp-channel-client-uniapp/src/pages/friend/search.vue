<template>
  <view class="search-container">
    <view class="search-input-bar">
      <view class="search-input-wrapper">
        <text class="search-icon">🔍</text>
        <input
          v-model="keyword"
          type="text"
          placeholder="输入用户名或邮箱"
          class="search-input"
          placeholder-class="ph"
          @confirm="handleSearch"
        />
      </view>
      <button class="btn-search" @tap="handleSearch" :disabled="!keyword.trim()">搜索</button>
    </view>

    <view v-if="!keyword && pendingRequests.length > 0" class="section">
      <view class="section-header">
        <text class="section-title">我发出的申请</text>
      </view>
      <view v-for="r in pendingRequests" :key="r.id" class="request-item">
        <image v-if="r.avatar" :src="r.avatar" mode="aspectFill" class="result-avatar" />
        <view v-else class="result-avatar-placeholder">
          <text>{{ r.username?.charAt(0) || '?' }}</text>
        </view>
        <view class="result-info">
          <text class="result-name">{{ r.username }}</text>
          <text class="result-email">{{ r.email || '' }}</text>
        </view>
        <text class="status-text">待审核</text>
      </view>
    </view>

    <view v-if="keyword && !results.length && searched" class="empty-state">
      <text class="empty-icon">👀</text>
      <text class="empty-text">未找到相关用户</text>
    </view>

    <view v-for="(r, idx) in results" :key="r.id || idx" class="result-item">
      <image v-if="r.avatar" :src="r.avatar" mode="aspectFill" class="result-avatar" />
      <view v-else class="result-avatar-placeholder" :style="{ background: r.color || 'var(--primary)' }">
        <text>{{ r.username?.charAt(0) || '?' }}</text>
      </view>
      <view class="result-info">
        <text class="result-name">{{ r.username }}</text>
        <text class="result-email">{{ r.email }}</text>
      </view>
      <button
        :class="r.requestSent ? 'btn-sent' : 'btn-add'"
        :disabled="r.requestSent"
        @tap="sendRequest(r)"
      >
        {{ r.requestSent ? '已申请' : '加好友' }}
      </button>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import request, { processImageUrl } from '../../utils/request'
import { useAuthStore } from '../../stores/auth'

const authStore = useAuthStore()

const keyword = ref('')
const results = ref<any[]>([])
const searched = ref(false)
const pendingRequests = ref<any[]>([])

onMounted(() => {
  if (!authStore.token) {
    uni.reLaunch({ url: '/pages/login/login' })
    return
  }
})



async function handleSearch() {
  if (!keyword.value.trim()) return
  searched.value = true
  try {
    const res = await request<any>(`/friends/search?keyword=${encodeURIComponent(keyword.value.trim())}`)
    if (res?.code === 200) {
      results.value = (res.data || []).map((u: any) => ({
        id: u.id || u.userId,
        username: u.username || '未知',
        avatar: processImageUrl(u.avatar || ''),
        email: u.email || '',
        color: u.color || 'var(--primary)',
        requestSent: u.requestSent || false,
      }))
    }
  } catch (_) {
    uni.showToast({ title: '搜索失败', icon: 'none' })
  }
}

async function sendRequest(user: any) {
  try {
    const res = await request<any>({
      url: '/friends/request',
      method: 'POST',
      data: { friendId: user.id },
    })
    if (res?.code === 200) {
      uni.showToast({ title: `已发送好友申请给 ${user.username}`, icon: 'success' })
      user.requestSent = true
    } else {
      uni.showToast({ title: res?.message || '发送失败', icon: 'none' })
    }
  } catch (_) {
    uni.showToast({ title: '发送失败', icon: 'none' })
  }
}
</script>

<style>
.search-container {
  min-height: 100vh;
  background-color: var(--bg);
  padding: 30rpx;
  box-sizing: border-box;
}

.search-input-bar {
  display: flex;
  align-items: center;
  gap: 20rpx;
  margin-bottom: 30rpx;
}

.search-input-wrapper {
  display: flex;
  align-items: center;
  background-color: var(--card);
  border-radius: 100rpx;
  padding: 0 30rpx;
  flex: 1;
  height: 80rpx;
  border: 1px solid var(--card-border);
}

.search-icon {
  font-size: 28rpx;
  margin-right: 16rpx;
}

.search-input {
  flex: 1;
  height: 100%;
  font-size: 28rpx;
  color: var(--text);
}

.ph {
  color: var(--text-muted);
}

.btn-search {
  height: 80rpx;
  padding: 0 32rpx;
  background: var(--primary);
  border-radius: 40rpx;
  color: #ffffff;
  font-size: 26rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
  flex-shrink: 0;
}

.btn-search::after {
  border: none;
}

.section {
  margin-bottom: 30rpx;
}

.section-header {
  margin-bottom: 16rpx;
}

.section-title {
  font-size: 28rpx;
  font-weight: bold;
  color: var(--text);
  padding-left: 12rpx;
  border-left: 6rpx solid var(--primary);
}

.request-item {
  display: flex;
  align-items: center;
  padding: 20rpx;
  background-color: var(--card);
  border-radius: 20rpx;
  margin-bottom: 12rpx;
  border: 1px solid var(--card-border);
}

.status-text {
  font-size: 22rpx;
  color: var(--text-muted);
  flex-shrink: 0;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding-top: 120rpx;
}

.empty-icon {
  font-size: 80rpx;
  margin-bottom: 20rpx;
}

.empty-text {
  font-size: 28rpx;
  color: var(--text-muted);
}

.result-item {
  display: flex;
  align-items: center;
  padding: 24rpx 20rpx;
  background-color: var(--card);
  border-radius: 20rpx;
  margin-bottom: 12rpx;
  border: 1px solid var(--card-border);
}

.result-avatar {
  width: 72rpx;
  height: 72rpx;
  border-radius: 50%;
  margin-right: 20rpx;
  flex-shrink: 0;
}

.result-avatar-placeholder {
  width: 72rpx;
  height: 72rpx;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28rpx;
  color: #ffffff;
  font-weight: bold;
  margin-right: 20rpx;
  flex-shrink: 0;
}

.result-info {
  flex: 1;
  min-width: 0;
}

.result-name {
  font-size: 28rpx;
  font-weight: 600;
  color: var(--text);
  display: block;
  margin-bottom: 4rpx;
}

.result-email {
  font-size: 22rpx;
  color: var(--text-soft);
}

.btn-add {
  height: 60rpx;
  padding: 0 24rpx;
  background: var(--primary);
  border-radius: 30rpx;
  color: #ffffff;
  font-size: 22rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
  flex-shrink: 0;
}

.btn-sent {
  height: 60rpx;
  padding: 0 24rpx;
  background: var(--bg);
  border-radius: 30rpx;
  color: var(--text-muted);
  font-size: 22rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px solid var(--card-border);
  flex-shrink: 0;
}

.btn-add::after,
.btn-sent::after {
  border: none;
}
</style>
