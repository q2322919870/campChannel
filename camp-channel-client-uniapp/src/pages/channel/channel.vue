<template>
  <view class="channel-container" @touchstart.capture="onTouchStart" @touchend.capture="onTouchEnd">
    <view v-if="channelId" class="channel-detail">
      <view class="channel-header-card">
        <view class="channel-header-top">
          <view class="channel-avatar-large" :style="{ background: channelColor }">
            <text>{{ channelName?.charAt(0) || '#' }}</text>
          </view>
          <view class="channel-header-info">
            <text class="channel-title">{{ channelName }}</text>
            <text class="channel-desc-text">{{ channelDescription }}</text>
            <text class="channel-meta-text">{{ memberCount }} 位成员</text>
          </view>
        </view>
        <view class="channel-actions">
          <button v-if="!isMember" class="btn-join" @tap="joinChannel">加入频道</button>
          <button v-if="isMember" class="btn-chat" @tap="goGroupChat">群聊</button>
          <button v-if="isMember && !isOwner" class="btn-leave" @tap="leaveChannel">退出频道</button>
          <button v-if="isOwner || isAdmin" class="btn-manage" @tap="showManagePanel">管理</button>
        </view>
      </view>

      <view v-if="showManage && (isOwner || isAdmin)" class="manage-panel">
        <view class="section-header">
          <text class="section-title">待处理申请</text>
        </view>
        <view v-for="app in pendingApplications" :key="app.id" class="application-item">
          <text class="app-user">{{ app.username }}</text>
          <view class="app-actions">
            <button class="btn-approve" @tap="handleApplication(app.id, 'APPROVED')">同意</button>
            <button class="btn-reject" @tap="handleApplication(app.id, 'REJECTED')">拒绝</button>
          </view>
        </view>
        <view v-if="pendingApplications.length === 0" class="no-data">
          <text>暂无待处理申请</text>
        </view>
      </view>

      <view class="section tabs">
        <view class="tab" :class="{ active: activeTab === 'posts' }" @tap="activeTab = 'posts'">
          <text>帖子</text>
        </view>
        <view class="tab" :class="{ active: activeTab === 'members' }" @tap="activeTab = 'members'; loadMembers()">
          <text>成员 ({{ memberCount }})</text>
        </view>
      </view>

      <view v-if="activeTab === 'posts'" class="post-list">
        <view v-for="post in posts" :key="post.id" class="post-card" @tap="goDetail(post)">
          <view class="post-header">
            <image v-if="post.avatar" :src="post.avatar" mode="aspectFill" class="author-avatar-img" />
            <view v-else class="author-avatar" :style="{ background: 'var(--primary-soft)' }">
              <text>{{ post.author?.charAt(0) || '?' }}</text>
            </view>
            <view class="author-info">
              <text class="author-name">{{ post.author }}</text>
              <text class="post-time">{{ post.createdAt }}</text>
            </view>
          </view>
          <text class="post-title">{{ post.title }}</text>
          <text class="post-preview">{{ post.content }}</text>
          <view class="post-actions">
            <text class="action-text">❤️ {{ post.likeCount }}</text>
            <text class="action-text">💬 {{ post.commentCount }}</text>
          </view>
        </view>
        <view v-if="posts.length === 0" class="no-data">
          <text>暂无帖子</text>
        </view>
      </view>

      <view v-if="activeTab === 'members'" class="member-list">
        <view v-for="m in members" :key="m.id" class="member-item">
          <image v-if="m.avatar" :src="m.avatar" mode="aspectFill" class="member-avatar" />
          <view v-else class="member-avatar-placeholder">
            <text>{{ m.username?.charAt(0) || '?' }}</text>
          </view>
          <view class="member-info">
            <text class="member-name">{{ m.username }}</text>
            <text class="member-role">{{ m.role === 'owner' ? '频道主' : m.role === 'admin' ? '管理员' : '成员' }}</text>
          </view>
        </view>
      </view>
    </view>

    <view v-else class="discover-view">
      <view class="search-bar">
        <view class="search-input-wrapper">
          <text class="search-icon">🔍</text>
          <input
            v-model="searchText"
            type="text"
            placeholder="搜索频道..."
            class="search-input"
            placeholder-class="ph"
            @confirm="handleSearch"
          />
        </view>
      </view>

      <view class="section">
        <view class="section-header">
          <text class="section-title">推荐频道</text>
        </view>
        <view
          v-for="ch in recommendChannels"
          :key="ch.id"
          class="channel-card"
          @tap="goChannelDetail(ch.id)"
        >
          <view class="channel-avatar" :style="{ background: ch.color || 'var(--primary)' }">
            <text>{{ ch.name?.charAt(0) || '#' }}</text>
          </view>
          <view class="channel-info">
            <text class="channel-name">{{ ch.name }}</text>
            <text class="channel-desc">{{ ch.description || ch.type || '' }}</text>
          </view>
          <view class="channel-meta">
            <text class="channel-count">{{ ch.memberCount || 0 }}人</text>
          </view>
        </view>
        <view v-if="recommendChannels.length === 0" class="no-data">
          <text>暂无推荐频道</text>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import request, { processImageUrl } from '../../utils/request'
import { useAuthStore } from '../../stores/auth'
import { useSwipeTab } from '../../utils/useSwipeTab'

const { onTouchStart, onTouchEnd } = useSwipeTab()

const authStore = useAuthStore()

const channelId = ref(0)
const channelName = ref('')
const channelDescription = ref('')
const channelColor = ref('var(--primary)')
const memberCount = ref(0)
const isMember = ref(false)
const isOwner = ref(false)
const isAdmin = ref(false)
const activeTab = ref('posts')
const showManage = ref(false)
const posts = ref<any[]>([])
const members = ref<any[]>([])
const pendingApplications = ref<any[]>([])

const searchText = ref('')
const recommendChannels = ref<any[]>([])

onMounted(async () => {
  const pages = getCurrentPages()
  const page = pages[pages.length - 1] as any
  const id = parseInt(page?.options?.id || page?.options?.channelId || '0')
  if (id) {
    channelId.value = id
    loadChannelDetail()
  } else {
    loadRecommendChannels()
  }
})

async function loadChannelDetail() {
  try {
    // Backend doesn't have GET /channels/{id}, so we need to get it from search or my channels
    let channelData = null
    
    // First try to get from user's channels
    const myRes = await request<any>('/channels/my')
    if (myRes?.code === 200) {
      channelData = (myRes.data || []).find((ch: any) => ch.id === channelId.value)
    }
    
    // If not found, try search
    if (!channelData) {
      const searchRes = await request<any>('/channels/search?keyword=')
      if (searchRes?.code === 200) {
        channelData = (searchRes.data || []).find((ch: any) => ch.id === channelId.value)
      }
    }
    
    if (channelData) {
      const d = channelData
      channelName.value = d.name || ''
      channelDescription.value = d.description || ''
      channelColor.value = d.color || 'var(--primary)'
      memberCount.value = d.memberCount || 0
      isMember.value = d.isMember || false
      isOwner.value = d.isOwner || false
      isAdmin.value = d.isAdmin || false
    }
  } catch (_) {}
  loadPosts()
}

async function loadPosts() {
  try {
    const res = await request<any>(`/posts/channel/${channelId.value}`)
    if (res?.code === 200) {
      posts.value = (res.data || res.data?.records || []).map((p: any) => ({
        id: p.id,
        author: p.author || p.username || '',
        avatar: processImageUrl(p.avatar || ''),
        createdAt: formatTime(p.createdAt),
        title: p.title || '',
        content: p.content || '',
        likeCount: p.likeCount || 0,
        commentCount: p.commentCount || 0,
      }))
    }
  } catch (_) {}
}

async function loadMembers() {
  try {
    const res = await request<any>(`/channels/${channelId.value}/members`)
    if (res?.code === 200) {
      members.value = (res.data || []).map((m: any) => ({
        id: m.id || m.userId,
        username: m.username || '',
        avatar: processImageUrl(m.avatar || ''),
        role: m.role || 'MEMBER',
      }))
    }
  } catch (_) {}
}

async function loadPendingApplications() {
  try {
    const res = await request<any>(`/channels/${channelId.value}/applications`)
    if (res?.code === 200) {
      pendingApplications.value = res.data || []
    }
  } catch (_) {}
}

function showManagePanel() {
  showManage.value = !showManage.value
  if (showManage.value) loadPendingApplications()
}

function goGroupChat() {
  uni.navigateTo({
    url: `/pages/chat/group-chat?channelId=${channelId.value}&channelName=${encodeURIComponent(channelName.value)}`
  })
}

async function joinChannel() {
  try {
    const res = await request<any>({ url: `/channels/${channelId.value}/join`, method: 'POST' })
    if (res?.code === 200) {
      isMember.value = true
      uni.showToast({ title: '加入成功', icon: 'success' })
    } else {
      uni.showToast({ title: res?.message || '加入失败', icon: 'none' })
    }
  } catch (_) {
    uni.showToast({ title: '操作失败', icon: 'none' })
  }
}

async function leaveChannel() {
  uni.showModal({
    title: '确认退出',
    content: '确定要退出此频道吗？',
    success: async (res) => {
      if (res.confirm) {
        try {
          const r = await request<any>({ url: `/channels/${channelId.value}/leave`, method: 'POST' })
          if (r?.code === 200) {
            isMember.value = false
            uni.showToast({ title: '已退出', icon: 'success' })
          }
        } catch (_) {}
      }
    },
  })
}

async function handleApplication(appId: number, status: string) {
  try {
    const res = await request<any>({
      url: `/channels/applications/${appId}/approve`,
      method: 'POST',
      data: { approved: status === 'APPROVED' },
    })
    if (res?.code === 200) {
      uni.showToast({ title: status === 'APPROVED' ? '已同意' : '已拒绝', icon: 'success' })
      loadPendingApplications()
    }
  } catch (_) {}
}

async function loadRecommendChannels() {
  try {
    // Use search endpoint with empty keyword to get all channels
    const res = await request<any>('/channels/search?keyword=')
    if (res?.code === 200) {
      recommendChannels.value = (res.data || []).slice(0, 10) // Limit to 10
    }
  } catch (_) {
    // Fallback: try to get user's channels
    try {
      const myRes = await request<any>('/channels/my')
      if (myRes?.code === 200) {
        recommendChannels.value = myRes.data || []
      }
    } catch (_) {}
  }
}

function goChannelDetail(id: number) {
  uni.navigateTo({ url: `/pages/channel/channel?id=${id}` })
}

function goDetail(post: any) {
  uni.navigateTo({ url: `/pages/post/detail?id=${post.id}` })
}

function handleSearch() {
  if (searchText.value.trim()) {
    uni.navigateTo({ url: `/pages/channel/channel?search=${searchText.value}` })
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
.channel-container {
  min-height: 100vh;
  background: var(--bg);
  padding: 30rpx;
  box-sizing: border-box;
}

.channel-header-card {
  background: var(--card);
  border: 1rpx solid var(--card-border);
  border-radius: var(--radius-lg);
  padding: 32rpx;
  margin-bottom: 24rpx;
  box-shadow: var(--shadow);
}

.channel-header-top {
  display: flex;
  align-items: center;
  margin-bottom: 24rpx;
}

.channel-avatar-large {
  width: 96rpx;
  height: 96rpx;
  border-radius: var(--radius);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 44rpx;
  color: #ffffff;
  font-weight: bold;
  margin-right: 24rpx;
  flex-shrink: 0;
}

.channel-header-info {
  flex: 1;
}

.channel-title {
  font-size: 36rpx;
  font-weight: bold;
  color: var(--text);
  display: block;
  margin-bottom: 6rpx;
}

.channel-desc-text {
  font-size: 26rpx;
  color: var(--text-secondary);
  display: block;
  margin-bottom: 4rpx;
}

.channel-meta-text {
  font-size: 22rpx;
  color: var(--text-muted);
}

.channel-actions {
  display: flex;
  gap: 20rpx;
}

.btn-join {
  flex: 1;
  height: 72rpx;
  background: var(--primary-gradient);
  border-radius: 36rpx;
  color: #ffffff;
  font-size: 26rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
  box-shadow: 0 8rpx 24rpx rgba(99, 102, 241, 0.25);
}

.btn-join::after,
.btn-leave::after,
.btn-manage::after,
.btn-approve::after,
.btn-reject::after {
  border: none;
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

.btn-leave {
  flex: 1;
  height: 72rpx;
  background: var(--accent-soft);
  border-radius: 36rpx;
  color: var(--accent);
  font-size: 26rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
}

.btn-manage {
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

.manage-panel {
  background: var(--card);
  border: 1rpx solid var(--card-border);
  border-radius: var(--radius);
  padding: 24rpx;
  margin-bottom: 24rpx;
  box-shadow: var(--shadow-sm);
}

.application-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16rpx 0;
  border-bottom: 1rpx solid var(--card-border);
}

.application-item:last-child {
  border-bottom: none;
}

.app-user {
  font-size: 26rpx;
  color: var(--text);
}

.app-actions {
  display: flex;
  gap: 16rpx;
}

.btn-approve {
  height: 56rpx;
  padding: 0 24rpx;
  background: var(--primary-soft);
  border-radius: 28rpx;
  color: var(--primary);
  font-size: 22rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
}

.btn-reject {
  height: 56rpx;
  padding: 0 24rpx;
  background: var(--accent-soft);
  border-radius: 28rpx;
  color: var(--accent);
  font-size: 22rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
}

.tabs {
  display: flex;
  gap: 12rpx;
  margin-bottom: 24rpx;
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

.post-list {
  margin-bottom: 24rpx;
}

.post-card {
  background: var(--card);
  border: 1rpx solid var(--card-border);
  border-radius: var(--radius);
  padding: 24rpx;
  margin-bottom: 16rpx;
  box-shadow: var(--shadow-sm);
}

.post-header {
  display: flex;
  align-items: center;
  margin-bottom: 12rpx;
}

.author-avatar {
  width: 56rpx;
  height: 56rpx;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24rpx;
  margin-right: 16rpx;
  flex-shrink: 0;
  color: #ffffff;
  font-weight: bold;
  background: var(--primary-gradient);
}

.author-avatar-img {
  width: 56rpx;
  height: 56rpx;
  border-radius: 50%;
  margin-right: 16rpx;
  flex-shrink: 0;
}

.author-info {
  flex: 1;
}

.author-name {
  font-size: 26rpx;
  font-weight: 600;
  color: var(--text);
  display: block;
}

.post-time {
  font-size: 20rpx;
  color: var(--text-muted);
}

.post-title {
  font-size: 30rpx;
  font-weight: bold;
  color: var(--text);
  display: block;
  margin-bottom: 8rpx;
}

.post-preview {
  font-size: 24rpx;
  color: var(--text-secondary);
  line-height: 1.5;
  display: block;
  margin-bottom: 12rpx;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
}

.post-actions {
  display: flex;
  gap: 24rpx;
}

.action-text {
  font-size: 22rpx;
  color: var(--text-muted);
}

.member-list {
  margin-bottom: 24rpx;
}

.member-item {
  display: flex;
  align-items: center;
  padding: 20rpx;
  background: var(--card);
  border: 1rpx solid var(--card-border);
  border-radius: var(--radius);
  margin-bottom: 12rpx;
  box-shadow: var(--shadow-sm);
}

.member-avatar {
  width: 72rpx;
  height: 72rpx;
  border-radius: 50%;
  margin-right: 20rpx;
}

.member-avatar-placeholder {
  width: 72rpx;
  height: 72rpx;
  border-radius: 50%;
  background: var(--primary-gradient);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28rpx;
  color: #ffffff;
  font-weight: bold;
  margin-right: 20rpx;
  flex-shrink: 0;
}

.member-info {
  flex: 1;
}

.member-name {
  font-size: 28rpx;
  font-weight: 600;
  color: var(--text);
  display: block;
  margin-bottom: 4rpx;
}

.member-role {
  font-size: 22rpx;
  color: var(--text-muted);
}

.no-data {
  text-align: center;
  padding: 60rpx 0;
  color: var(--text-muted);
  font-size: 26rpx;
}

.discover-view .search-bar {
  margin-bottom: 30rpx;
}

.discover-view .search-input-wrapper {
  display: flex;
  align-items: center;
  background: var(--card);
  border: 1rpx solid var(--card-border);
  border-radius: 100rpx;
  padding: 0 30rpx;
  height: 80rpx;
  box-shadow: var(--shadow-sm);
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

.section {
  margin-bottom: 40rpx;
}

.section-header {
  display: flex;
  align-items: center;
  margin-bottom: 20rpx;
}

.section-title {
  font-size: 32rpx;
  font-weight: bold;
  color: var(--text);
  padding-left: 12rpx;
  border-left: 6rpx solid var(--primary);
}

.channel-card {
  display: flex;
  align-items: center;
  background: var(--card);
  border: 1rpx solid var(--card-border);
  border-radius: var(--radius);
  padding: 28rpx;
  margin-bottom: 16rpx;
  box-shadow: var(--shadow-sm);
}

.channel-avatar {
  width: 80rpx;
  height: 80rpx;
  border-radius: 20rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 36rpx;
  color: #ffffff;
  font-weight: bold;
  margin-right: 24rpx;
  flex-shrink: 0;
}

.channel-info {
  flex: 1;
  min-width: 0;
}

.channel-name {
  font-size: 30rpx;
  font-weight: 600;
  color: var(--text);
  display: block;
  margin-bottom: 6rpx;
}

.channel-desc {
  font-size: 24rpx;
  color: var(--text-secondary);
  display: block;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.channel-meta {
  flex-shrink: 0;
  margin-left: 16rpx;
}

.channel-count {
  font-size: 22rpx;
  color: var(--text-muted);
}
</style>
