<template>
  <view class="home-container">
    <scroll-view scroll-x class="channel-scroll">
      <view
        class="channel-tab"
        :class="{ active: activeChannel === 0 }"
        @tap="switchChannel(0)"
      >
        <text>全部</text>
      </view>
      <view
        v-for="ch in channels"
        :key="ch.id"
        class="channel-tab"
        :class="{ active: activeChannel === ch.id }"
        @tap="switchChannel(ch.id)"
      >
        <text>{{ ch.name }}</text>
      </view>
    </scroll-view>

    <view class="feed-list">
      <view
        v-for="post in posts"
        :key="post.id"
        class="post-card"
        @tap="goDetail(post)"
      >
        <view class="post-header" @tap.stop="showUserCard(post.authorId)">
          <image v-if="post.avatar" :src="post.avatar" mode="aspectFill" class="author-avatar-img" />
          <view v-else class="author-avatar" :style="{ background: post.color }">
            <text class="avatar-text">{{ post.author?.charAt(0) || '?' }}</text>
          </view>
          <view class="author-info">
            <text class="author-name">{{ post.author }}</text>
            <text class="post-time">{{ post.createdAt }}</text>
          </view>
          <view class="channel-tag" :style="{ background: 'var(--primary-soft)', color: 'var(--primary)' }">
            {{ post.channelName }}
          </view>
        </view>

        <text class="post-title">{{ post.title }}</text>
        <text class="post-preview">{{ post.content }}</text>

        <view v-if="post.images?.length" class="post-images">
          <image
            v-for="(img, idx) in post.images.slice(0, 3)"
            :key="idx"
            :src="img"
            mode="aspectFill"
            class="post-image"
            :class="{ wide: post.images.length === 1 }"
          />
        </view>

        <view class="post-actions">
          <view class="action-item" @tap.stop="toggleLike(post)">
            <text class="action-icon">{{ post.isLiked ? '❤' : '♡' }}</text>
            <text class="action-text">{{ post.likeCount }}</text>
          </view>
          <view class="action-item">
            <text class="action-icon">💬</text>
            <text class="action-text">{{ post.commentCount }}</text>
          </view>
        </view>
      </view>

      <view v-if="loading" class="loading-state">
        <text class="loading-text">加载中...</text>
      </view>
      <view v-if="!loading && posts.length === 0" class="empty-state">
        <text class="empty-icon">📭</text>
        <text class="empty-text">暂无帖子</text>
      </view>
    </view>

    <view v-if="showRefreshHint" class="refresh-hint" @tap="loadPosts">
      <text>有新的帖子，点击刷新</text>
    </view>

    <view class="fab" @tap="goCreate">
      <text class="fab-icon">+</text>
    </view>

    <view class="fab-refresh" @tap="loadPosts">
      <text class="fab-icon">↻</text>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { onPullDownRefresh } from '@dcloudio/uni-app'
import { useAuthStore } from '../../stores/auth'
import request, { processImageUrl } from '../../utils/request'

const authStore = useAuthStore()

interface Channel {
  id: number
  name: string
}

interface Post {
  id: number
  authorId: number
  author: string
  avatar: string
  color: string
  createdAt: string
  channelName: string
  channelId: number
  title: string
  content: string
  images: string[]
  likeCount: number
  commentCount: number
  isLiked: boolean
}

const channels = ref<Channel[]>([])
const activeChannel = ref(0)
const posts = ref<Post[]>([])
const loading = ref(false)
const showRefreshHint = ref(false)

let ws: any = null
let pollTimer: any = null

onMounted(() => {
  if (!authStore.token) {
    uni.reLaunch({ url: '/pages/login/login' })
    return
  }
  loadChannels()
  loadPosts()
  connectWebSocket()
})

onUnmounted(() => {
  if (ws) ws.close()
  if (pollTimer) clearInterval(pollTimer)
})

onPullDownRefresh(() => {
  loadPosts().finally(() => uni.stopPullDownRefresh())
})

async function loadChannels() {
  try {
    const res = await request<any>('/channels/my')
    if (res?.code === 200) {
      channels.value = (res.data || []).filter((ch: any) => ch.type !== 'PUBLIC')
    }
  } catch (_) {}
}

async function loadPosts() {
  loading.value = true
  showRefreshHint.value = false
  try {
    const url = activeChannel.value === 0
      ? '/posts'
      : `/posts/channel/${activeChannel.value}`
    const res = await request<any>(url)
    if (res?.code === 200) {
      posts.value = (res.data || res.data?.records || []).map((p: any) => ({
        id: p.id,
        authorId: p.userId || p.authorId,
        author: p.author || p.username || '未知',
        avatar: processImageUrl(p.avatar || ''),
        color: p.color || '#7C9FCB',
        createdAt: formatTime(p.createdAt),
        channelName: p.channelName || '',
        channelId: p.channelId,
        title: p.title || '',
        content: p.content || '',
        images: (p.images || []).map((img: string) => processImageUrl(img)),
        likeCount: p.likeCount || 0,
        commentCount: p.commentCount || 0,
        isLiked: p.isLiked || false,
      }))
    }
  } catch (_) {
    uni.showToast({ title: '加载失败', icon: 'none' })
  } finally {
    loading.value = false
  }
}

function switchChannel(id: number) {
  activeChannel.value = id
  loadPosts()
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

function toggleLike(post: Post) {
  request<any>({
    url: `/posts/${post.id}/like`,
    method: 'POST',
  }).then((res: any) => {
    if (res?.code === 200) {
      post.isLiked = !post.isLiked
      post.likeCount += post.isLiked ? 1 : -1
    }
  }).catch(() => {})
}

function goDetail(post: Post) {
  uni.navigateTo({ url: `/pages/post/detail?id=${post.id}` })
}

function goCreate() {
  uni.navigateTo({ url: '/pages/post/create' })
}

function showUserCard(userId: number) {
  uni.navigateTo({ url: `/pages/friend/search?userId=${userId}` })
}

function connectWebSocket() {
  try {
    const storedUrl = uni.getStorageSync('api_base_url')
    const baseUrl = storedUrl || 'http://localhost:8080'
    const wsUrl = baseUrl.replace('http', 'ws').replace('/api', '') + '/ws'
    
    ws = uni.connectSocket({
      url: wsUrl,
      success: () => {},
    })
    ws.onMessage((msg: any) => {
      try {
        const data = JSON.parse(msg.data)
        if (data.type === 'new_post' || data.type === 'new_comment' || data.type === 'new_like') {
          showRefreshHint.value = true
        }
      } catch (_) {}
    })
    ws.onClose(() => {
      setTimeout(connectWebSocket, 5000)
    })
    ws.onError(() => {
      setTimeout(connectWebSocket, 5000)
    })
  } catch (_) {}
}
</script>

<style>
.home-container {
  min-height: 100vh;
  background-color: var(--bg);
  box-sizing: border-box;
}

.channel-scroll {
  display: flex;
  white-space: nowrap;
  padding: 20rpx 30rpx;
  background-color: var(--card);
  border-bottom: 1px solid var(--card-border);
}

.channel-tab {
  display: inline-flex;
  align-items: center;
  padding: 12rpx 32rpx;
  border-radius: 100rpx;
  font-size: 26rpx;
  color: var(--text-soft);
  background-color: var(--bg);
  margin-right: 16rpx;
  border: 1px solid var(--card-border);
}

.channel-tab.active {
  background: linear-gradient(135deg, var(--primary), var(--primary));
  color: #ffffff;
  border-color: transparent;
}

.feed-list {
  padding: 0;
}

.post-card {
  background-color: var(--card);
  padding: 28rpx 32rpx;
  margin-bottom: 16rpx;
  border-bottom: 1px solid var(--card-border);
}

.post-header {
  display: flex;
  align-items: center;
  margin-bottom: 16rpx;
}

.author-avatar {
  width: 64rpx;
  height: 64rpx;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 32rpx;
  margin-right: 16rpx;
  flex-shrink: 0;
}

.author-avatar-img {
  width: 64rpx;
  height: 64rpx;
  border-radius: 50%;
  margin-right: 16rpx;
  flex-shrink: 0;
}

.avatar-text {
  color: #ffffff;
  font-weight: bold;
}

.author-info {
  flex: 1;
}

.author-name {
  font-size: 28rpx;
  font-weight: 600;
  color: var(--text);
  display: block;
  margin-bottom: 2rpx;
}

.post-time {
  font-size: 22rpx;
  color: var(--text-muted);
}

.channel-tag {
  padding: 6rpx 20rpx;
  border-radius: 100rpx;
  font-size: 20rpx;
  font-weight: 500;
  flex-shrink: 0;
}

.post-title {
  font-size: 32rpx;
  font-weight: bold;
  color: var(--text);
  display: block;
  margin-bottom: 12rpx;
  line-height: 1.3;
}

.post-preview {
  font-size: 26rpx;
  color: var(--text-soft);
  line-height: 1.5;
  display: block;
  margin-bottom: 16rpx;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
}

.post-images {
  display: flex;
  gap: 8rpx;
  margin-bottom: 16rpx;
}

.post-image {
  width: 200rpx;
  height: 200rpx;
  border-radius: 16rpx;
  background-color: var(--bg);
}

.post-image.wide {
  width: 100%;
  height: 300rpx;
}

.post-actions {
  display: flex;
  align-items: center;
  gap: 40rpx;
  padding-top: 16rpx;
  border-top: 1px solid var(--card-border);
}

.action-item {
  display: flex;
  align-items: center;
  gap: 8rpx;
}

.action-icon {
  font-size: 28rpx;
}

.action-text {
  font-size: 22rpx;
  color: var(--text-muted);
}

.loading-state,
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 80rpx 0;
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

.refresh-hint {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  background: var(--primary);
  color: #ffffff;
  text-align: center;
  padding: 16rpx;
  font-size: 26rpx;
  z-index: 999;
}

.fab {
  position: fixed;
  bottom: 140rpx;
  right: 32rpx;
  width: 100rpx;
  height: 100rpx;
  border-radius: 50%;
  background: linear-gradient(135deg, var(--primary), var(--accent));
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 8rpx 32rpx rgba(124, 157, 212, 0.4);
  z-index: 100;
}

.fab-refresh {
  position: fixed;
  bottom: 260rpx;
  right: 32rpx;
  width: 80rpx;
  height: 80rpx;
  border-radius: 50%;
  background: var(--card);
  border: 1px solid var(--card-border);
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.1);
  z-index: 100;
}

.fab-icon {
  font-size: 40rpx;
}
</style>
