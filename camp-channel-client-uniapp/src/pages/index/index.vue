<template>
  <view class="home-page" @touchstart.capture="onTouchStart" @touchend.capture="onTouchEnd">
    <view class="home-header">
      <text class="page-title">首页</text>
      <scroll-view v-if="channelTabs.length > 0" scroll-x class="channel-tabs">
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
}

const channelTabs = ref<Channel[]>([])
const currentTab = ref(0)
const tabIndex = ref(0)
const posts = ref<Post[]>([])
const loading = ref(false)
const refreshing = ref(false)

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
  uni.navigateTo({ url: `/pages/friend/search?userId=${userId}` })
}

function sharePost(post: Post) {
  uni.showShareMenu({
    withShareTicket: true,
  })
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
  position: relative;
  z-index: 1;
}

.home-header {
  background: rgba(124, 159, 203, 0.08);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  padding: 24rpx 32rpx;
  border-bottom: 1rpx solid rgba(124, 159, 203, 0.15);
  position: relative;
  z-index: 10;
}

.home-header::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(
    135deg,
    rgba(255, 255, 255, 0.05) 0%,
    rgba(255, 255, 255, 0.02) 50%,
    transparent 100%
  );
  pointer-events: none;
  border-radius: 0;
}

.page-title {
  font-size: 40rpx;
  font-weight: bold;
  color: #E8EFF7;
  margin-bottom: 16rpx;
  display: block;
  position: relative;
  z-index: 1;
}

.channel-tabs {
  white-space: nowrap;
  position: relative;
  z-index: 1;
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
  padding: 12rpx 32rpx;
  border-radius: 100rpx;
  font-size: 26rpx;
  color: rgba(232, 239, 247, 0.6);
  background: rgba(124, 159, 203, 0.08);
  margin-right: 16rpx;
  border: 1rpx solid rgba(124, 159, 203, 0.15);
  position: relative;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.channel-tab.active {
  background: rgba(124, 159, 203, 0.15);
  border-color: #7C9FCB;
  color: #7C9FCB;
  font-weight: 600;
}

.tab-badge {
  position: absolute;
  top: -8rpx;
  right: -8rpx;
  background: #7C9FCB;
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
  padding: 16rpx;
  position: relative;
  z-index: 1;
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
  padding: 80rpx 0;
}

.loading-text,
.empty-text {
  font-size: 28rpx;
  color: rgba(232, 239, 247, 0.6);
}

.empty-icon {
  font-size: 80rpx;
  margin-bottom: 20rpx;
}
</style>
