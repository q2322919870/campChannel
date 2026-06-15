<template>
  <view class="feed-page">
    <view class="feed-header">
      <text class="page-title">关注动态</text>
      <text class="page-subtitle">你关注的人的最新帖子</text>
    </view>

    <view v-if="loading && posts.length === 0" class="loading-state">
      <text class="loading-text">加载中...</text>
    </view>

    <view v-else-if="posts.length === 0" class="empty-state">
      <text class="empty-icon">👤</text>
      <text class="empty-text">暂无关注动态</text>
      <text class="empty-hint">关注更多人后，这里会显示他们的帖子</text>
    </view>

    <scroll-view v-else scroll-y class="feed-list" @scrolltolower="loadMore">
      <view
        v-for="post in posts"
        :key="post.id"
        class="feed-item"
        @tap="goDetail(post.id)"
      >
        <view class="feed-author-row">
          <view class="feed-avatar" @tap.stop="goProfile(post.userId)">
            <image v-if="post.avatar" :src="post.avatar" mode="aspectFill" class="avatar-img" />
            <text v-else>{{ (post.author || '?').charAt(0) }}</text>
          </view>
          <view class="feed-author-info">
            <text class="feed-author-name">{{ post.author }}</text>
            <text class="feed-time">{{ post.time }}</text>
          </view>
          <text class="feed-channel">{{ post.channelName }}</text>
        </view>

        <text class="feed-title">{{ post.title }}</text>
        <text class="feed-content">{{ post.content }}</text>

        <view v-if="post.images && post.images.length" class="feed-images">
          <image
            v-for="(img, i) in post.images.slice(0, 3)"
            :key="i"
            :src="img"
            mode="aspectFill"
            class="feed-image"
          />
        </view>

        <view class="feed-actions">
          <text class="action">❤ {{ post.likeCount }}</text>
          <text class="action">💬 {{ post.commentCount }}</text>
        </view>
      </view>

      <view v-if="loadingMore" class="loading-more">
        <text>加载中...</text>
      </view>
      <view v-if="!hasMore && posts.length > 0" class="no-more">
        <text>没有更多了</text>
      </view>
    </scroll-view>
  </view>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import request, { processImageUrl } from '../../utils/request'

interface FeedPost {
  id: number
  author: string
  avatar: string
  userId: number
  title: string
  content: string
  channelName: string
  images: string[]
  likeCount: number
  commentCount: number
  time: string
}

function safeParseImages(images: any): string[] {
  if (!images) return []
  if (Array.isArray(images)) return images.map((img: string) => processImageUrl(img))
  if (typeof images === 'string') {
    try {
      const parsed = JSON.parse(images)
      if (Array.isArray(parsed)) return parsed.map((img: string) => processImageUrl(img))
    } catch (_) {}
    return [processImageUrl(images)]
  }
  return []
}

const posts = ref<FeedPost[]>([])
const loading = ref(true)
const loadingMore = ref(false)
const page = ref(1)
const hasMore = ref(true)

onMounted(() => {
  loadFeed()
})

async function loadFeed() {
  loading.value = true
  try {
    const res = await request<any>(`/follow/feed?page=1&size=20`)
    if (res?.code === 200) {
      const list = res.data?.records || res.data || []
      posts.value = mapPosts(list)
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
    const res = await request<any>(`/follow/feed?page=${page.value}&size=20`)
    if (res?.code === 200) {
      const list = res.data?.records || res.data || []
      posts.value = [...posts.value, ...mapPosts(list)]
      hasMore.value = list.length >= 20
    }
  } catch (_) {} finally {
    loadingMore.value = false
  }
}

function mapPosts(list: any[]): FeedPost[] {
  return list.map((p: any) => ({
    id: p.id,
    author: p.author || p.username || '未知',
    avatar: processImageUrl(p.avatar || ''),
    userId: p.userId || 0,
    title: p.title || '',
    content: p.content || '',
    channelName: p.channelName || '',
    images: safeParseImages(p.images),
    likeCount: p.likeCount || 0,
    commentCount: p.commentCount || 0,
    time: formatTime(p.createdAt),
  }))
}

function goDetail(id: number) {
  uni.navigateTo({ url: `/pages/post/detail?id=${id}` })
}

function goProfile(userId: number) {
  uni.navigateTo({ url: `/pages/user/profile?userId=${userId}` })
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
.feed-page {
  min-height: 100vh;
  background: var(--bg);
  padding: 32rpx;
}

.feed-header {
  background: var(--card);
  border: 1rpx solid var(--card-border);
  border-radius: var(--radius-lg);
  padding: 32rpx;
  margin-bottom: 24rpx;
  box-shadow: var(--shadow);
}

.page-title {
  font-size: 40rpx;
  font-weight: 700;
  color: var(--text);
  display: block;
  margin-bottom: 8rpx;
}

.page-subtitle {
  font-size: 24rpx;
  color: var(--text-muted);
}

.feed-list {
  height: calc(100vh - 280rpx);
}

.feed-item {
  background: var(--card);
  border: 1rpx solid var(--card-border);
  border-radius: var(--radius);
  padding: 24rpx;
  margin-bottom: 16rpx;
  box-shadow: var(--shadow-sm);
}

.feed-author-row {
  display: flex;
  align-items: center;
  margin-bottom: 16rpx;
}

.feed-avatar {
  width: 64rpx;
  height: 64rpx;
  border-radius: 50%;
  overflow: hidden;
  background: var(--primary-gradient);
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 16rpx;
  flex-shrink: 0;
  font-size: 28rpx;
  color: #fff;
  font-weight: 700;
}

.avatar-img {
  width: 100%;
  height: 100%;
}

.feed-author-info {
  flex: 1;
}

.feed-author-name {
  font-size: 28rpx;
  font-weight: 600;
  color: var(--text);
  display: block;
}

.feed-time {
  font-size: 22rpx;
  color: var(--text-muted);
}

.feed-channel {
  font-size: 22rpx;
  color: var(--primary);
  background: var(--primary-soft);
  padding: 4rpx 16rpx;
  border-radius: 100rpx;
  flex-shrink: 0;
}

.feed-title {
  font-size: 30rpx;
  font-weight: 700;
  color: var(--text);
  display: block;
  margin-bottom: 8rpx;
}

.feed-content {
  font-size: 26rpx;
  color: var(--text-secondary);
  line-height: 1.6;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
  margin-bottom: 12rpx;
}

.feed-images {
  display: flex;
  gap: 8rpx;
  margin-bottom: 12rpx;
}

.feed-image {
  flex: 1;
  height: 180rpx;
  border-radius: 12rpx;
  background: var(--bg);
}

.feed-actions {
  display: flex;
  gap: 24rpx;
  padding-top: 12rpx;
  border-top: 1rpx solid var(--card-border);
}

.action {
  font-size: 24rpx;
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

.empty-icon {
  font-size: 80rpx;
  margin-bottom: 20rpx;
}

.empty-hint {
  font-size: 24rpx;
  color: var(--text-muted);
  margin-top: 8rpx;
}

.loading-more,
.no-more {
  text-align: center;
  padding: 32rpx 0;
  font-size: 24rpx;
  color: var(--text-muted);
}
</style>
