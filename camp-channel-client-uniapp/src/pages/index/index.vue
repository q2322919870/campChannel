<template>
  <view class="home-page" @touchstart.capture="onTouchStart" @touchend.capture="onTouchEnd">
    <view class="home-header">
      <view class="header-top">
        <text class="page-title">首页</text>
        <view class="hot-entry" @tap="goHotPosts">
          <text class="hot-icon">🔥</text>
          <text class="hot-text">热门</text>
        </view>
        <view class="search-bar" @tap="focusSearch">
          <input
            v-model="searchKeyword"
            placeholder="搜索帖子..."
            class="search-input"
            confirm-type="search"
            @confirm="doSearch"
          />
          <text v-if="searchKeyword" class="search-clear" @tap.stop="clearSearch">×</text>
          <text v-else class="search-icon">🔍</text>
        </view>
      </view>
      <scroll-view v-if="channelTabs.length > 0 && !isSearching" scroll-x class="channel-tabs">
        <view
          v-for="tab in channelTabs"
          :key="tab.id"
          class="channel-tab"
          :class="{ active: currentTab === tab.id }"
          @tap="switchChannel(tab.id)"
        >
          <text>{{ tab.name }}</text>
          <text v-if="tab.unread" class="tab-badge">{{ tab.unread }}</text>
        </view>
      </scroll-view>
    </view>

    <swiper :current="tabIndex" @change="onSwiperChange" class="content-swiper">
      <swiper-item v-for="(tab, idx) in channelTabs" :key="tab.id">
        <scroll-view 
          class="posts-list" 
          scroll-y 
          refresher-enabled
          :refresher-triggered="refreshing"
          @refresherrefresh="onRefresh"
        >
          <PostCard
            v-for="post in posts"
            :key="post.id"
            :post="post"
            @click="viewPost"
            @avatar-click="showUserCard"
            @like="toggleLike"
            @comment="viewPost"
            @share="sharePost"
          />

          <view v-if="loading" class="loading-state">
            <text class="loading-text">加载中...</text>
          </view>
          
          <view v-if="!loading && posts.length === 0" class="empty-state">
            <text class="empty-icon">📭</text>
            <text class="empty-text">暂无帖子</text>
          </view>
        </scroll-view>
      </swiper-item>
    </swiper>
  </view>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import PostCard from '../../components/PostCard.vue'
import { useAuthStore } from '../../stores/auth'
import request, { processImageUrl } from '../../utils/request'
import wsManager from '../../utils/websocket'
import { useSwipeTab } from '../../utils/useSwipeTab'

const { onTouchStart, onTouchEnd } = useSwipeTab({ avoidTop: 250 })

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

const authStore = useAuthStore()

interface Channel {
  id: number
  name: string
  unread?: number
}

interface Post {
  id: number
  authorId: number
  author: string
  avatar: string
  userId?: number
  time: string
  channelName: string
  channelId: number
  userChannelRole?: string
  title: string
  content: string
  images: string[]
  likeCount: number
  commentCount: number
  isLiked: boolean
  isPinned?: boolean
}

const channelTabs = ref<Channel[]>([])
const currentTab = ref(0)
const tabIndex = ref(0)
const posts = ref<Post[]>([])
const loading = ref(false)
const refreshing = ref(false)
const searchKeyword = ref('')
const isSearching = ref(false)

let unsubscribeNewPost: (() => void) | null = null
let unsubscribeNewComment: (() => void) | null = null
let unsubscribeNewLike: (() => void) | null = null

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
  // Unsubscribe from WebSocket events
  if (unsubscribeNewPost) unsubscribeNewPost()
  if (unsubscribeNewComment) unsubscribeNewComment()
  if (unsubscribeNewLike) unsubscribeNewLike()
})

async function loadChannels() {
  try {
    const res = await request<any>('/channels/my')
    if (res?.code === 200) {
      // Put PUBLIC channel first, then others
      const channels = res.data || []
      const publicChannel = channels.find((ch: any) => ch.type === 'PUBLIC')
      const otherChannels = channels.filter((ch: any) => ch.type !== 'PUBLIC')
      
      channelTabs.value = [
        { id: 0, name: '全部', unread: 0 },
        ...(publicChannel ? [{ id: publicChannel.id, name: publicChannel.name, unread: 0 }] : []),
        ...otherChannels.map((ch: any) => ({ id: ch.id, name: ch.name, unread: 0 }))
      ]
    }
  } catch (_) {}
}

async function loadPosts() {
  loading.value = true
  try {
    const url = currentTab.value === 0
      ? '/posts'
      : `/posts/channel/${currentTab.value}`
    const res = await request<any>(url)
    if (res?.code === 200) {
      posts.value = (res.data || res.data?.records || []).map((p: any) => ({
        id: p.id,
        authorId: p.userId || p.authorId,
        author: p.author || p.username || '未知',
        avatar: processImageUrl(p.avatar || ''),
        userId: p.userId,
        time: formatTime(p.createdAt),
        channelName: p.channelName || '',
        channelId: p.channelId,
        userChannelRole: p.userChannelRole,
        title: p.title || '',
        content: p.content || '',
        images: safeParseImages(p.images),
        likeCount: p.likeCount || 0,
        commentCount: p.commentCount || 0,
        isLiked: p.isLiked || false,
        isPinned: p.isPinned || false,
      }))
    }
  } catch (_) {
    uni.showToast({ title: '加载失败', icon: 'none' })
  } finally {
    loading.value = false
    refreshing.value = false
  }
}

function onRefresh() {
  refreshing.value = true
  loadPosts()
}

function switchChannel(id: number) {
  currentTab.value = id
  tabIndex.value = channelTabs.value.findIndex((t) => t.id === id)
  if (tabIndex.value < 0) tabIndex.value = 0
  loadPosts()
}

function onSwiperChange(e: any) {
  const idx = e.detail?.current || 0
  tabIndex.value = idx
  const tab = channelTabs.value[idx]
  if (tab) {
    currentTab.value = tab.id
    loadPosts()
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

function toggleLike(post: Post, event: any) {
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

function viewPost(postId: number) {
  uni.navigateTo({ url: `/pages/post/detail?id=${postId}` })
}

function showUserCard(userId: number) {
  uni.navigateTo({ url: `/pages/user/profile?userId=${userId}` })
}

function goHotPosts() {
  uni.navigateTo({ url: '/pages/post/hot-posts' })
}

function sharePost(post: Post) {
  const shareText = `${post.author}: ${post.content.substring(0, 100)}...`
  uni.setClipboardData({
    data: shareText,
    success: () => {
      uni.showToast({ title: '内容已复制，可粘贴分享', icon: 'none', duration: 2000 })
    },
    fail: () => {
      uni.showToast({ title: '分享失败', icon: 'none' })
    }
  })
}

function focusSearch() {
  // input auto-focuses when tapped
}

async function doSearch() {
  const keyword = searchKeyword.value.trim()
  if (!keyword) {
    clearSearch()
    return
  }
  isSearching.value = true
  loading.value = true
  try {
    const res = await request<any>(`/posts/search?keyword=${encodeURIComponent(keyword)}&page=1&size=20`)
    if (res?.code === 200) {
      posts.value = (res.data || []).map((p: any) => ({
        id: p.id,
        authorId: p.userId || p.authorId,
        author: p.author || p.username || '未知',
        avatar: processImageUrl(p.avatar || ''),
        userId: p.userId,
        time: formatTime(p.createdAt),
        channelName: p.channelName || '',
        channelId: p.channelId,
        userChannelRole: p.userChannelRole,
        title: p.title || '',
        content: p.content || '',
        images: safeParseImages(p.images),
        likeCount: p.likeCount || 0,
        commentCount: p.commentCount || 0,
        isLiked: p.isLiked || false,
      }))
    }
  } catch (_) {
    uni.showToast({ title: '搜索失败', icon: 'none' })
  } finally {
    loading.value = false
  }
}

function clearSearch() {
  searchKeyword.value = ''
  isSearching.value = false
  loadPosts()
}

function connectWebSocket() {
  // Connect using centralized manager
  wsManager.connect().then(() => {
    console.log('[Home] WebSocket connected')
    
    // Subscribe to new post events
    unsubscribeNewPost = wsManager.on('new_post', () => {
      console.log('[Home] New post received, refreshing...')
      loadPosts()
    })
    
    // Subscribe to new comment events
    unsubscribeNewComment = wsManager.on('new_comment', () => {
      console.log('[Home] New comment received, refreshing...')
      loadPosts()
    })
    
    // Subscribe to new like events
    unsubscribeNewLike = wsManager.on('new_like', () => {
      console.log('[Home] New like received, refreshing...')
      loadPosts()
    })
  }).catch((err) => {
    console.error('[Home] WebSocket connection failed:', err)
  })
}
</script>

<style scoped>
.home-page {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  background: var(--bg);
}

.home-header {
  background: var(--card);
  padding: 20rpx 32rpx 16rpx;
  box-shadow: var(--shadow-sm);
  position: relative;
  z-index: 10;
}

.header-top {
  display: flex;
  align-items: center;
  gap: 16rpx;
  margin-bottom: 20rpx;
}

.page-title {
  font-size: 44rpx;
  font-weight: 800;
  color: var(--text);
  display: block;
  flex-shrink: 0;
}

.search-bar {
  flex: 1;
  display: flex;
  align-items: center;
  background: var(--bg);
  border: 1rpx solid var(--card-border);
  border-radius: 100rpx;
  padding: 8rpx 20rpx;
  gap: 8rpx;
}

.search-input {
  flex: 1;
  font-size: 26rpx;
  color: var(--text);
  height: 48rpx;
}

.hot-entry {
  display: flex;
  align-items: center;
  gap: 4rpx;
  padding: 8rpx 20rpx;
  background: rgba(245, 158, 11, 0.1);
  border-radius: 100rpx;
  flex-shrink: 0;
}

.hot-icon {
  font-size: 28rpx;
}

.hot-text {
  font-size: 24rpx;
  color: #F59E0B;
  font-weight: 600;
}

.search-icon {
  font-size: 28rpx;
  color: var(--text-muted);
}

.search-clear {
  font-size: 32rpx;
  color: var(--text-muted);
  padding: 0 8rpx;
}

.channel-tabs {
  white-space: nowrap;
  width: 100%;
  overflow-x: auto;
  overflow-y: hidden;
}

.channel-tabs::-webkit-scrollbar {
  display: none;
}

.channel-tab {
  display: inline-flex;
  align-items: center;
  padding: 12rpx 28rpx;
  border-radius: 100rpx;
  font-size: 26rpx;
  color: var(--text-secondary);
  background: var(--bg);
  margin-right: 12rpx;
  font-weight: 500;
  transition: all 0.2s ease;
}

.channel-tab.active {
  background: var(--primary);
  color: #ffffff;
  font-weight: 600;
  box-shadow: 0 4rpx 12rpx rgba(99, 102, 241, 0.25);
}

.tab-badge {
  position: absolute;
  top: -8rpx;
  right: -8rpx;
  background: var(--accent);
  color: #ffffff;
  font-size: 20rpx;
  padding: 2rpx 12rpx;
  border-radius: 100rpx;
  min-width: 32rpx;
  text-align: center;
}

.posts-list {
  flex: 1;
  height: 100%;
  padding: 20rpx 24rpx;
}

.content-swiper {
  flex: 1;
  overflow: hidden;
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
