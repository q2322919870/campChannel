<template>
  <view class="hot-posts-page">
    <view class="header-card">
      <view class="header-row">
        <text class="fire-icon">🔥</text>
        <text class="page-title">热门帖子</text>
      </view>
      <text class="page-subtitle">近7天最热内容</text>
    </view>

    <view v-if="loading" class="loading-state">
      <text class="loading-text">加载中...</text>
    </view>

    <view v-else-if="posts.length === 0" class="empty-state">
      <text class="empty-icon">🔥</text>
      <text class="empty-text">暂无热门帖子</text>
    </view>

    <view v-else class="posts-list">
      <view
        v-for="(post, index) in posts"
        :key="post.id"
        class="hot-item"
        :class="{ 'top-3': index < 3 }"
        @tap="goDetail(post.id)"
      >
        <view class="rank-badge" :class="'rank-' + index">
          <text>{{ index + 1 }}</text>
        </view>
        <view class="item-body">
          <view class="item-header">
            <view class="author-row">
              <view class="mini-avatar">
                <image v-if="post.avatar" :src="post.avatar" mode="aspectFill" class="avatar-img" />
                <text v-else>{{ (post.author || '?').charAt(0) }}</text>
              </view>
              <text class="author-name">{{ post.author }}</text>
              <text class="channel-tag">{{ post.channelName }}</text>
            </view>
          </view>
          <text class="item-title">{{ post.title }}</text>
          <text class="item-preview">{{ post.content }}</text>
          <view class="item-stats">
            <text class="stat">❤ {{ post.likeCount }}</text>
            <text class="stat">💬 {{ post.commentCount }}</text>
            <text class="stat hot-score">🔥 {{ post.hotScore || 0 }}</text>
          </view>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import request, { processImageUrl } from '../../utils/request'

interface HotPost {
  id: number
  author: string
  avatar: string
  userId: number
  title: string
  content: string
  channelName: string
  likeCount: number
  commentCount: number
  hotScore: number
}

const posts = ref<HotPost[]>([])
const loading = ref(true)

onMounted(() => {
  loadHotPosts()
})

async function loadHotPosts() {
  loading.value = true
  try {
    const res = await request<any>('/posts/hot?limit=20')
    if (res?.code === 200) {
      posts.value = (res.data || []).map((p: any) => ({
        id: p.id,
        author: p.author || p.username || '未知',
        avatar: processImageUrl(p.avatar || ''),
        userId: p.userId || 0,
        title: p.title || '',
        content: p.content || '',
        channelName: p.channelName || '',
        likeCount: p.likeCount || 0,
        commentCount: p.commentCount || 0,
        hotScore: p.hotScore || p.score || Math.floor((p.likeCount || 0) * 3 + (p.commentCount || 0) * 2 + (p.viewCount || 0) * 0.5),
      }))
    }
  } catch (_) {
    uni.showToast({ title: '加载失败', icon: 'none' })
  } finally {
    loading.value = false
  }
}

function goDetail(id: number) {
  uni.navigateTo({ url: `/pages/post/detail?id=${id}` })
}
</script>

<style scoped>
.hot-posts-page {
  min-height: 100vh;
  background: var(--bg);
  padding: 32rpx;
}

.header-card {
  background: var(--card);
  border: 1rpx solid var(--card-border);
  border-radius: var(--radius-lg);
  padding: 32rpx;
  margin-bottom: 24rpx;
  box-shadow: var(--shadow);
}

.header-row {
  display: flex;
  align-items: center;
  gap: 12rpx;
  margin-bottom: 8rpx;
}

.fire-icon {
  font-size: 44rpx;
}

.page-title {
  font-size: 40rpx;
  font-weight: 700;
  color: var(--text);
}

.page-subtitle {
  font-size: 24rpx;
  color: var(--text-muted);
}

.posts-list {
  display: flex;
  flex-direction: column;
  gap: 16rpx;
}

.hot-item {
  display: flex;
  align-items: flex-start;
  background: var(--card);
  border: 1rpx solid var(--card-border);
  border-radius: var(--radius);
  padding: 24rpx;
  box-shadow: var(--shadow-sm);
}

.hot-item.top-3 {
  border-left: 6rpx solid var(--warning);
}

.rank-badge {
  width: 56rpx;
  height: 56rpx;
  border-radius: 16rpx;
  background: var(--bg);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28rpx;
  font-weight: 700;
  color: var(--text-muted);
  margin-right: 20rpx;
  flex-shrink: 0;
}

.rank-0 {
  background: linear-gradient(135deg, #FFD700, #FFA500);
  color: #ffffff;
}

.rank-1 {
  background: linear-gradient(135deg, #C0C0C0, #A0A0A0);
  color: #ffffff;
}

.rank-2 {
  background: linear-gradient(135deg, #CD7F32, #A0522D);
  color: #ffffff;
}

.item-body {
  flex: 1;
  min-width: 0;
}

.author-row {
  display: flex;
  align-items: center;
  gap: 8rpx;
  margin-bottom: 12rpx;
}

.mini-avatar {
  width: 40rpx;
  height: 40rpx;
  border-radius: 50%;
  overflow: hidden;
  background: var(--primary-gradient);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20rpx;
  color: #fff;
  font-weight: 700;
  flex-shrink: 0;
}

.avatar-img {
  width: 100%;
  height: 100%;
}

.author-name {
  font-size: 24rpx;
  font-weight: 600;
  color: var(--text);
}

.channel-tag {
  font-size: 20rpx;
  color: var(--primary);
  background: var(--primary-soft);
  padding: 2rpx 12rpx;
  border-radius: 100rpx;
}

.item-title {
  font-size: 28rpx;
  font-weight: 700;
  color: var(--text);
  display: block;
  margin-bottom: 8rpx;
  line-height: 1.5;
}

.item-preview {
  font-size: 24rpx;
  color: var(--text-secondary);
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  margin-bottom: 12rpx;
  line-height: 1.5;
}

.item-stats {
  display: flex;
  gap: 20rpx;
}

.stat {
  font-size: 22rpx;
  color: var(--text-muted);
}

.hot-score {
  color: var(--warning);
  font-weight: 600;
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
</style>
