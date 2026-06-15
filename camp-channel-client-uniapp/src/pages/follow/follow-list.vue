<template>
  <view class="follow-list-page">
    <view class="tabs">
      <view class="tab" :class="{ active: activeTab === 'following' }" @tap="switchTab('following')">
        <text>关注 ({{ followingCount }})</text>
      </view>
      <view class="tab" :class="{ active: activeTab === 'followers' }" @tap="switchTab('followers')">
        <text>粉丝 ({{ followerCount }})</text>
      </view>
    </view>

    <view v-if="loading" class="loading-state">
      <text class="loading-text">加载中...</text>
    </view>

    <view v-else-if="users.length === 0" class="empty-state">
      <text class="empty-icon">{{ activeTab === 'following' ? '👤' : '👥' }}</text>
      <text class="empty-text">{{ activeTab === 'following' ? '暂未关注任何人' : '暂无粉丝' }}</text>
    </view>

    <scroll-view v-else scroll-y class="user-list" @scrolltolower="loadMore">
      <view v-for="u in users" :key="u.userId" class="user-item">
        <view class="user-avatar" @tap="goProfile(u.userId)">
          <image v-if="u.avatar" :src="u.avatar" mode="aspectFill" class="avatar-img" />
          <text v-else>{{ (u.username || '?').charAt(0) }}</text>
        </view>
        <view class="user-info" @tap="goProfile(u.userId)">
          <text class="user-name">{{ u.username }}</text>
          <text v-if="u.bio" class="user-bio">{{ u.bio }}</text>
        </view>
        <button
          v-if="u.userId !== currentUserId"
          class="btn-follow"
          :class="{ active: u.isFollowing }"
          @tap="toggleFollow(u)"
        >
          {{ u.isFollowing ? '已关注' : '关注' }}
        </button>
      </view>

      <view v-if="loadingMore" class="loading-more">
        <text>加载中...</text>
      </view>
      <view v-if="!hasMore && users.length > 0" class="no-more">
        <text>没有更多了</text>
      </view>
    </scroll-view>
  </view>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '../../stores/auth'
import request, { processImageUrl } from '../../utils/request'

const authStore = useAuthStore()
const currentUserId = computed(() => authStore.userInfo?.userId || 0)

interface UserItem {
  userId: number
  username: string
  avatar: string
  bio?: string
  isFollowing: boolean
}

const activeTab = ref<'following' | 'followers'>('following')
const users = ref<UserItem[]>([])
const loading = ref(true)
const loadingMore = ref(false)
const page = ref(1)
const hasMore = ref(true)
const targetUserId = ref(0)
const followingCount = ref(0)
const followerCount = ref(0)

onMounted(() => {
  const pages = getCurrentPages()
  const page_ = pages[pages.length - 1] as any
  targetUserId.value = parseInt(page_?.options?.userId || '0') || currentUserId.value
  const tabParam = page_?.options?.tab
  if (tabParam === 'followers' || tabParam === 'following') {
    activeTab.value = tabParam
  }
  loadCounts()
  loadList()
})

async function loadCounts() {
  try {
    const res = await request<any>(`/follow/${targetUserId.value}/counts`)
    if (res?.code === 200 && res.data) {
      followingCount.value = res.data.followingCount || 0
      followerCount.value = res.data.followerCount || 0
    }
  } catch (_) {}
}

async function loadList() {
  loading.value = true
  page.value = 1
  try {
    const endpoint = activeTab.value === 'following'
      ? `/follow/${targetUserId.value}/following?page=1&size=20`
      : `/follow/${targetUserId.value}/followers?page=1&size=20`
    const res = await request<any>(endpoint)
    if (res?.code === 200) {
      const list = res.data?.records || res.data || []
      users.value = mapUsers(list)
      hasMore.value = list.length >= 20
    }
  } catch (_) {
    uni.showToast({ title: '加载失败', icon: 'none' })
  } finally {
    loading.value = false
  }
}

async function loadMore() {
  if (loadingMore.value || !hasMore.value) return
  loadingMore.value = true
  page.value++
  try {
    const endpoint = activeTab.value === 'following'
      ? `/follow/${targetUserId.value}/following?page=${page.value}&size=20`
      : `/follow/${targetUserId.value}/followers?page=${page.value}&size=20`
    const res = await request<any>(endpoint)
    if (res?.code === 200) {
      const list = res.data?.records || res.data || []
      users.value = [...users.value, ...mapUsers(list)]
      hasMore.value = list.length >= 20
    }
  } catch (_) {} finally {
    loadingMore.value = false
  }
}

function mapUsers(list: any[]): UserItem[] {
  return list.map((u: any) => ({
    userId: u.userId || u.id || u.followerId || u.followingId,
    username: u.username || '未知',
    avatar: processImageUrl(u.avatar || ''),
    bio: u.bio || u.signature || '',
    isFollowing: u.isFollowing || false,
  }))
}

function switchTab(tab: 'following' | 'followers') {
  if (activeTab.value === tab) return
  activeTab.value = tab
  loadList()
}

async function toggleFollow(user: UserItem) {
  try {
    const res = await request<any>({
      url: `/follow/${user.userId}/toggle`,
      method: 'POST',
    })
    if (res?.code === 200) {
      user.isFollowing = !user.isFollowing
      if (activeTab.value === 'following') {
        followingCount.value += user.isFollowing ? 1 : -1
        followingCount.value = Math.max(followingCount.value, 0)
      }
      uni.showToast({
        title: user.isFollowing ? '已关注' : '已取消关注',
        icon: 'success'
      })
    }
  } catch (_) {
    uni.showToast({ title: '操作失败', icon: 'none' })
  }
}

function goProfile(userId: number) {
  uni.navigateTo({ url: `/pages/user/profile?userId=${userId}` })
}
</script>

<style scoped>
.follow-list-page {
  min-height: 100vh;
  background: var(--bg);
  padding: 32rpx;
}

.tabs {
  display: flex;
  gap: 12rpx;
  margin-bottom: 24rpx;
}

.tab {
  flex: 1;
  text-align: center;
  padding: 20rpx;
  border-radius: 100rpx;
  font-size: 28rpx;
  color: var(--text-secondary);
  background: var(--card);
  border: 1rpx solid var(--card-border);
  font-weight: 500;
}

.tab.active {
  background: var(--primary);
  color: #ffffff;
  font-weight: 600;
  border-color: var(--primary);
  box-shadow: 0 4rpx 12rpx rgba(99, 102, 241, 0.25);
}

.user-list {
  height: calc(100vh - 200rpx);
}

.user-item {
  display: flex;
  align-items: center;
  background: var(--card);
  border: 1rpx solid var(--card-border);
  border-radius: var(--radius);
  padding: 24rpx;
  margin-bottom: 12rpx;
  box-shadow: var(--shadow-sm);
}

.user-avatar {
  width: 80rpx;
  height: 80rpx;
  border-radius: 50%;
  overflow: hidden;
  background: var(--primary-gradient);
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 20rpx;
  flex-shrink: 0;
  font-size: 32rpx;
  color: #fff;
  font-weight: 700;
}

.avatar-img {
  width: 100%;
  height: 100%;
}

.user-info {
  flex: 1;
  min-width: 0;
}

.user-name {
  font-size: 28rpx;
  font-weight: 600;
  color: var(--text);
  display: block;
  margin-bottom: 4rpx;
}

.user-bio {
  font-size: 24rpx;
  color: var(--text-muted);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  display: block;
}

.btn-follow {
  height: 56rpx;
  padding: 0 32rpx;
  background: var(--primary-gradient);
  border-radius: 28rpx;
  color: #ffffff;
  font-size: 24rpx;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
  flex-shrink: 0;
}

.btn-follow.active {
  background: var(--bg);
  color: var(--text-secondary);
  border: 1rpx solid var(--card-border);
}

.loading-state,
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 120rpx 0;
}

.loading-text,
.empty-text {
  font-size: 28rpx;
  color: var(--text-muted);
}

.empty-icon {
  font-size: 80rpx;
  margin-bottom: 20rpx;
}

.loading-more,
.no-more {
  text-align: center;
  padding: 32rpx 0;
  font-size: 24rpx;
  color: var(--text-muted);
}
</style>
