<template>
  <view class="user-profile-page">
    <view v-if="loading" class="loading-state">
      <text class="loading-text">加载中...</text>
    </view>

    <template v-else>
      <!-- Profile Header -->
      <view class="profile-header">
        <view class="avatar-section">
          <view class="profile-avatar">
            <image v-if="profile.avatar" :src="profile.avatar" mode="aspectFill" class="avatar-img" />
            <text v-else class="avatar-letter">{{ (profile.username || '?').charAt(0) }}</text>
          </view>
        </view>
        <view class="profile-info">
          <text class="profile-name">{{ profile.username || '未知用户' }}</text>
          <text v-if="profile.realName" class="profile-real">{{ profile.realName }}</text>
          <view class="profile-stats">
            <view class="stat-item" @tap="goFollowList('following')">
              <text class="stat-value">{{ followingCount }}</text>
              <text class="stat-label">关注</text>
            </view>
            <view class="stat-item" @tap="goFollowList('followers')">
              <text class="stat-value">{{ followerCount }}</text>
              <text class="stat-label">粉丝</text>
            </view>
            <view class="stat-item">
              <text class="stat-value">{{ postCount }}</text>
              <text class="stat-label">帖子</text>
            </view>
          </view>
        </view>
      </view>

      <!-- Action Buttons -->
      <view v-if="!isSelf" class="action-row">
        <button
          class="btn-follow"
          :class="{ active: isFollowing }"
          @tap="toggleFollow"
        >
          {{ isFollowing ? '已关注' : '+ 关注' }}
        </button>
        <button class="btn-chat" @tap="startChat">💬 发消息</button>
        <button v-if="!isFriend" class="btn-friend" @tap="addFriend">加好友</button>
      </view>

      <!-- User's Posts -->
      <view class="section-header">
        <text class="section-title">TA的帖子</text>
      </view>

      <view v-if="userPosts.length === 0" class="empty-state">
        <text class="empty-text">暂无帖子</text>
      </view>

      <view v-for="post in userPosts" :key="post.id" class="post-item" @tap="goDetail(post.id)">
        <text class="post-title">{{ post.title }}</text>
        <text class="post-preview">{{ post.content }}</text>
        <view class="post-meta">
          <text class="meta-item">{{ post.channelName }}</text>
          <text class="meta-item">❤ {{ post.likeCount }}</text>
          <text class="meta-item">💬 {{ post.commentCount }}</text>
          <text class="meta-item">{{ post.time }}</text>
        </view>
      </view>
    </template>
  </view>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '../../stores/auth'
import request, { processImageUrl } from '../../utils/request'

const authStore = useAuthStore()
const currentUserId = computed(() => authStore.userInfo?.userId || 0)

interface UserProfile {
  userId: number
  username: string
  realName?: string
  avatar: string
  email?: string
}

interface UserPost {
  id: number
  title: string
  content: string
  channelName: string
  likeCount: number
  commentCount: number
  time: string
}

const profile = ref<UserProfile>({ userId: 0, username: '', avatar: '' })
const userPosts = ref<UserPost[]>([])
const postCount = ref(0)
const followingCount = ref(0)
const followerCount = ref(0)
const isFollowing = ref(false)
const isFriend = ref(false)
const loading = ref(true)
const targetUserId = ref(0)

const isSelf = computed(() => targetUserId.value === currentUserId.value)

onMounted(() => {
  const pages = getCurrentPages()
  const page = pages[pages.length - 1] as any
  targetUserId.value = parseInt(page?.options?.userId || '0')
  if (targetUserId.value) {
    loadProfile()
  }
})

async function loadProfile() {
  loading.value = true
  try {
    // Load profile data
    const res = await request<any>(`/users/${targetUserId.value}/profile`)
    if (res?.code === 200 && res.data) {
      const d = res.data
      profile.value = {
        userId: d.userId || d.id || targetUserId.value,
        username: d.username || '未知',
        realName: d.realName || '',
        avatar: processImageUrl(d.avatar || ''),
        email: d.email || '',
      }
      isFriend.value = d.isFriend || false
      // Parse posts
      if (d.posts && Array.isArray(d.posts)) {
        userPosts.value = d.posts.map((p: any) => ({
          id: p.id,
          title: p.title || '',
          content: p.content || '',
          channelName: p.channelName || '',
          likeCount: p.likeCount || 0,
          commentCount: p.commentCount || 0,
          time: formatTime(p.createdAt),
        }))
      }
      postCount.value = d.postCount || userPosts.value.length
    }

    // Load follow counts
    try {
      const countRes = await request<any>(`/follow/${targetUserId.value}/counts`)
      if (countRes?.code === 200 && countRes.data) {
        followingCount.value = countRes.data.followingCount || 0
        followerCount.value = countRes.data.followerCount || 0
      }
    } catch (_) {}

    // Check follow status
    try {
      const followRes = await request<any>(`/follow/${targetUserId.value}/is-following`)
      if (followRes?.code === 200) {
        isFollowing.value = followRes.data === true || followRes.data?.isFollowing === true
      }
    } catch (_) {}
  } catch (_) {
    uni.showToast({ title: '加载失败', icon: 'none' })
  } finally {
    loading.value = false
  }
}

async function toggleFollow() {
  try {
    const res = await request<any>({
      url: `/follow/${targetUserId.value}/toggle`,
      method: 'POST',
    })
    if (res?.code === 200) {
      isFollowing.value = !isFollowing.value
      followerCount.value += isFollowing.value ? 1 : -1
      followerCount.value = Math.max(followerCount.value, 0)
      uni.showToast({
        title: isFollowing.value ? '已关注' : '已取消关注',
        icon: 'success'
      })
    }
  } catch (_) {
    uni.showToast({ title: '操作失败', icon: 'none' })
  }
}

function startChat() {
  uni.navigateTo({
    url: `/pages/chat/detail?userId=${targetUserId.value}&username=${encodeURIComponent(profile.value.username)}`
  })
}

async function addFriend() {
  try {
    const res = await request<any>({
      url: `/friends/request`,
      method: 'POST',
      data: { friendId: targetUserId.value },
    })
    if (res?.code === 200) {
      uni.showToast({ title: '好友请求已发送', icon: 'success' })
    } else {
      uni.showToast({ title: res?.message || '操作失败', icon: 'none' })
    }
  } catch (_) {
    uni.showToast({ title: '操作失败', icon: 'none' })
  }
}

function goFollowList(tab: string) {
  uni.navigateTo({
    url: `/pages/follow/follow-list?userId=${targetUserId.value}&tab=${tab}`
  })
}

function goDetail(id: number) {
  uni.navigateTo({ url: `/pages/post/detail?id=${id}` })
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

<style scoped>
.user-profile-page {
  min-height: 100vh;
  background: var(--bg);
  padding: 32rpx;
}

.profile-header {
  display: flex;
  gap: 24rpx;
  align-items: flex-start;
  padding: 32rpx;
  background: var(--card);
  border: 1rpx solid var(--card-border);
  border-radius: var(--radius-lg);
  margin-bottom: 20rpx;
  box-shadow: var(--shadow);
}

.avatar-section {
  flex-shrink: 0;
}

.profile-avatar {
  width: 140rpx;
  height: 140rpx;
  border-radius: 50%;
  background: var(--primary-gradient);
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.avatar-img {
  width: 100%;
  height: 100%;
}

.avatar-letter {
  font-size: 56rpx;
  font-weight: 700;
  color: #ffffff;
}

.profile-info {
  flex: 1;
}

.profile-name {
  font-size: 36rpx;
  font-weight: 700;
  color: var(--text);
  display: block;
  margin-bottom: 4rpx;
}

.profile-real {
  font-size: 24rpx;
  color: var(--text-secondary);
  display: block;
  margin-bottom: 16rpx;
}

.profile-stats {
  display: flex;
  gap: 32rpx;
}

.stat-item {
  text-align: center;
}

.stat-value {
  display: block;
  font-size: 32rpx;
  font-weight: 700;
  color: var(--primary);
}

.stat-label {
  font-size: 22rpx;
  color: var(--text-muted);
}

.action-row {
  display: flex;
  gap: 16rpx;
  margin-bottom: 24rpx;
}

.btn-follow {
  flex: 1;
  height: 72rpx;
  background: var(--primary-gradient);
  border-radius: 36rpx;
  color: #ffffff;
  font-size: 26rpx;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
  box-shadow: 0 8rpx 24rpx rgba(99, 102, 241, 0.25);
}

.btn-follow.active {
  background: var(--bg);
  color: var(--text-secondary);
  border: 1rpx solid var(--card-border);
  box-shadow: none;
}

.btn-chat {
  flex: 1;
  height: 72rpx;
  background: linear-gradient(135deg, #10B981, #059669);
  border-radius: 36rpx;
  color: #ffffff;
  font-size: 26rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
}

.btn-friend {
  flex: 1;
  height: 72rpx;
  background: var(--primary-soft);
  border-radius: 36rpx;
  color: var(--primary);
  font-size: 26rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
}

.section-header {
  margin-bottom: 16rpx;
}

.section-title {
  font-size: 32rpx;
  font-weight: bold;
  color: var(--text);
  padding-left: 16rpx;
  border-left: 6rpx solid var(--primary);
}

.post-item {
  background: var(--card);
  border: 1rpx solid var(--card-border);
  border-radius: var(--radius);
  padding: 24rpx;
  margin-bottom: 12rpx;
  box-shadow: var(--shadow-sm);
}

.post-title {
  font-size: 28rpx;
  font-weight: 700;
  color: var(--text);
  display: block;
  margin-bottom: 8rpx;
}

.post-preview {
  font-size: 24rpx;
  color: var(--text-secondary);
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  margin-bottom: 12rpx;
  line-height: 1.5;
}

.post-meta {
  display: flex;
  gap: 16rpx;
  flex-wrap: wrap;
}

.meta-item {
  font-size: 22rpx;
  color: var(--text-muted);
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
</style>
