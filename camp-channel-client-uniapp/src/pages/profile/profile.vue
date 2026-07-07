<template>
  <view class="profile-page" @touchstart.capture="onTouchStart" @touchend.capture="onTouchEnd">
    <view class="profile-header">
      <view class="avatar-wrapper" @tap="previewAvatar">
        <view class="profile-avatar">
          <image v-if="avatarUrl" :src="avatarUrl" mode="aspectFill" class="avatar-img" />
          <view v-else class="no-avatar">{{ username.charAt(0) }}</view>
        </view>
      </view>
      <view class="profile-info">
        <text class="profile-name">{{ username }}</text>
        <text class="profile-email">{{ email }}</text>
        <view class="profile-stats">
          <view class="stat-item">
            <text class="stat-value">{{ posts }}</text>
            <text class="stat-label">帖子</text>
          </view>
          <view class="stat-item">
            <text class="stat-value">{{ followingCount }}</text>
            <text class="stat-label">关注</text>
          </view>
          <view class="stat-item">
            <text class="stat-value">{{ followerCount }}</text>
            <text class="stat-label">粉丝</text>
          </view>
          <view class="stat-item">
            <text class="stat-value">{{ friends }}</text>
            <text class="stat-label">好友</text>
          </view>
        </view>
      </view>
    </view>

    <view class="profile-nav">
      <view class="nav-item" @tap="goEditProfile">
        <text class="nav-icon">✏️</text>
        <text class="nav-label">编辑资料</text>
      </view>
      <view class="nav-item" @tap="goMyPosts">
        <text class="nav-icon">📝</text>
        <text class="nav-label">我的帖子</text>
      </view>
      <view class="nav-item" @tap="goDrafts">
        <text class="nav-icon">📋</text>
        <text class="nav-label">我的草稿</text>
      </view>
      <view class="nav-item" @tap="goFollowingFeed">
        <text class="nav-icon">🔔</text>
        <text class="nav-label">关注动态</text>
      </view>
      <view class="nav-item" @tap="goFollowList">
        <text class="nav-icon">👤</text>
        <text class="nav-label">关注 / 粉丝</text>
      </view>
      <view class="nav-item" @tap="goFriends">
        <text class="nav-icon">👥</text>
        <text class="nav-label">好友管理</text>
      </view>
      <view class="nav-item" @tap="goFavourites">
        <text class="nav-icon">★</text>
        <text class="nav-label">我的收藏</text>
      </view>
      <view class="nav-item" @tap="goLikedPosts">
        <text class="nav-icon">❤</text>
        <text class="nav-label">赞过的贴</text>
      </view>
      <view class="nav-item" @tap="goHotPosts">
        <text class="nav-icon">🔥</text>
        <text class="nav-label">热门帖子</text>
      </view>
      <view class="nav-item" @tap="goTreeHole">
        <text class="nav-icon">🌫️</text>
        <text class="nav-label">树洞</text>
      </view>
      <view class="nav-item" @tap="goSettings">
        <text class="nav-icon">⚙</text>
        <text class="nav-label">设置</text>
      </view>
      <view v-if="isAdmin" class="nav-item" @tap="goAdmin">
        <text class="nav-icon">🛡</text>
        <text class="nav-label">管理后台</text>
      </view>
    </view>

    <button class="logout-btn" @tap="handleLogout">退出登录</button>
  </view>

  <!-- Avatar Preview Modal -->
  <view v-if="showAvatarPreview" class="avatar-overlay" @tap="closeAvatarPreview">
    <view class="avatar-preview-content" @tap.stop>
      <image :src="avatarUrl" mode="widthFix" class="avatar-preview-img" />
      <view class="avatar-actions">
        <view class="avatar-btn" @tap="changeAvatar">
          <text class="btn-icon">📷</text>
          <text class="btn-label">更改头像</text>
        </view>
        <view class="avatar-btn" @tap="downloadAvatar">
          <text class="btn-icon">💾</text>
          <text class="btn-label">下载头像</text>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useAuthStore } from '../../stores/auth'
import request, { processImageUrl, BASE_URL } from '../../utils/request'
import { useSwipeTab } from '../../utils/useSwipeTab'

const { onTouchStart, onTouchEnd } = useSwipeTab()

const authStore = useAuthStore()

const username = ref(authStore.userInfo?.username || '未登录')
const email = ref(authStore.userInfo?.email || '')
const avatarUrl = ref('')
const posts = ref(0)
const friends = ref(0)
const followingCount = ref(0)
const followerCount = ref(0)
const isAdmin = ref(false)
const showAvatarPreview = ref(false)

onMounted(() => {
  if (!authStore.token) {
    uni.reLaunch({ url: '/pages/login/login' })
    return
  }
  fetchProfile()
})

async function fetchProfile() {
  try {
    const res = await request<any>('/users/me')
    if (res?.code === 200) {
      username.value = res.data.username || '未登录'
      email.value = res.data.email || ''
      avatarUrl.value = processImageUrl(res.data.avatar || '')
      isAdmin.value = res.data.role === 'ADMIN' || res.data.role === 'OWNER'
      // Sync avatar back to authStore so other pages (chat) can use it
      if (res.data.avatar) {
        const info = { ...(authStore.userInfo || {}), avatar: res.data.avatar }
        authStore.setAuth(authStore.token, info)
      }
    }
    
    // Get post count
    const pRes = await request<any>('/posts/my?page=1&size=100')
    if (pRes?.code === 200 && Array.isArray(pRes.data)) {
      posts.value = pRes.data.length
    }
    
    // Get friend count
    const fRes = await request<any>('/friends')
    if (fRes?.code === 200 && Array.isArray(fRes.data)) {
      friends.value = fRes.data.length
    }
    
    // Get follow/follower counts
    const userId = authStore.userInfo?.userId
    if (userId) {
      const followRes = await request<any>(`/follow/${userId}/counts`)
      if (followRes?.code === 200 && followRes.data) {
        followingCount.value = followRes.data.followingCount || 0
        followerCount.value = followRes.data.followerCount || 0
      }
    }
  } catch (_) {}
}

function previewAvatar() {
  if (avatarUrl.value) {
    showAvatarPreview.value = true
  }
}

function closeAvatarPreview() {
  showAvatarPreview.value = false
}

async function changeAvatar() {
  closeAvatarPreview()
  try {
    const res = await uni.chooseImage({
      count: 1,
      sizeType: ['compressed'],
      sourceType: ['album', 'camera']
    })
    if (res.tempFilePaths && res.tempFilePaths.length > 0) {
      uni.showLoading({ title: '上传中...' })
      const filePath = res.tempFilePaths[0]
      const uploadRes = await uni.uploadFile({
        url: `${BASE_URL}/users/avatar`,
        filePath: filePath,
        name: 'file',
        header: {
          'Authorization': authStore.token
        }
      })
      uni.hideLoading()
      const data = JSON.parse(uploadRes.data || '{}')
      if (data.code === 200) {
        avatarUrl.value = processImageUrl(data.data?.url || '')
        // Update auth store
        const info = { ...(authStore.userInfo || {}), avatar: data.data?.url || '' }
        authStore.setAuth(authStore.token, info)
        uni.showToast({ title: '头像更新成功', icon: 'success' })
      } else {
        uni.showToast({ title: data.message || '上传失败', icon: 'none' })
      }
    }
  } catch (err) {
    uni.hideLoading()
    console.error('changeAvatar error:', err)
  }
}

async function downloadAvatar() {
  if (!avatarUrl.value) return
  try {
    uni.showLoading({ title: '下载中...' })
    const downloadRes = await uni.downloadFile({ url: avatarUrl.value })
    if (downloadRes.statusCode === 200) {
      await uni.saveImageToPhotosAlbum({ filePath: downloadRes.tempFilePath })
      uni.hideLoading()
      uni.showToast({ title: '已保存到相册', icon: 'success' })
    } else {
      uni.hideLoading()
      uni.showToast({ title: '下载失败', icon: 'none' })
    }
  } catch (_) {
    uni.hideLoading()
    uni.showToast({ title: '下载失败', icon: 'none' })
  }
}

function goEditProfile() {
  uni.navigateTo({ url: '/pages/settings/edit-profile' })
}

function goMyPosts() {
  uni.navigateTo({ url: '/pages/post/my-posts' })
}

function goDrafts() {
  uni.navigateTo({ url: '/pages/post/drafts' })
}

function goFollowingFeed() {
  uni.navigateTo({ url: '/pages/follow/following-feed' })
}

function goFollowList() {
  const userId = authStore.userInfo?.userId || 0
  uni.navigateTo({ url: `/pages/follow/follow-list?userId=${userId}` })
}

function goFriends() {
  uni.navigateTo({ url: '/pages/friend/list' })
}

function goFavourites() {
  uni.navigateTo({ url: '/pages/post/favourites' })
}

function goLikedPosts() {
  uni.navigateTo({ url: '/pages/post/liked-posts' })
}

function goHotPosts() {
  uni.navigateTo({ url: '/pages/post/hot-posts' })
}

function goTreeHole() {
  uni.navigateTo({ url: '/pages/tree-hole/tree-hole' })
}

function goSettings() {
  uni.navigateTo({ url: '/pages/settings/settings' })
}

function goAdmin() {
  uni.navigateTo({ url: '/pages/admin/admin' })
}

function handleLogout() {
  uni.showModal({
    title: '提示',
    content: '确定要退出登录吗？',
    success: (res) => {
      if (res.confirm) {
        authStore.logout()
        uni.reLaunch({ url: '/pages/login/login' })
      }
    }
  })
}
</script>

<style scoped>
.profile-page {
  min-height: 100vh;
  background: transparent;
  padding: 32rpx;
  padding-bottom: 32rpx;
}

.profile-header {
  display: flex;
  gap: 24rpx;
  align-items: center;
  padding: 32rpx;
  background: var(--card);
  border: 1rpx solid var(--card-border);
  border-radius: var(--radius-lg);
  margin-bottom: 16rpx;
  box-shadow: var(--shadow);
}

.avatar-wrapper {
  position: relative;
  flex-shrink: 0;
}

.profile-avatar {
  width: 160rpx;
  height: 160rpx;
  border-radius: 50%;
  background: var(--primary-gradient);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 64rpx;
  font-weight: 700;
  color: #fff;
  overflow: hidden;
}

.avatar-img {
  width: 100%;
  height: 100%;
}

.no-avatar {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 64rpx;
  font-weight: 700;
  color: #fff;
}

.profile-info {
  flex: 1;
}

.profile-name {
  font-size: 40rpx;
  font-weight: 700;
  color: var(--text);
  margin-bottom: 8rpx;
  display: block;
}

.profile-email {
  font-size: 24rpx;
  color: var(--text-secondary);
  margin-bottom: 24rpx;
  display: block;
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
  font-size: 36rpx;
  font-weight: 700;
  color: var(--primary);
}

.stat-label {
  font-size: 22rpx;
  color: var(--text-muted);
}

.profile-nav {
  display: flex;
  flex-direction: column;
  gap: 8rpx;
  margin-bottom: 16rpx;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 16rpx;
  padding: 24rpx;
  background: var(--card);
  border: 1rpx solid var(--card-border);
  border-radius: var(--radius);
  box-shadow: var(--shadow-sm);
}

.nav-item:active {
  background: var(--bg);
}

.nav-icon {
  font-size: 40rpx;
}

.nav-label {
  font-size: 28rpx;
  color: var(--text);
  font-weight: 500;
}

.logout-btn {
  width: 100%;
  padding: 24rpx;
  border: none;
  border-radius: var(--radius);
  background: var(--accent-soft);
  color: var(--accent);
  font-size: 28rpx;
  font-weight: 600;
}

.avatar-overlay {
  position: fixed;
  top: 0; left: 0; right: 0; bottom: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
}

.avatar-preview-content {
  width: 85%;
  max-width: 600rpx;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.avatar-preview-img {
  width: 100%;
  border-radius: var(--radius);
  background: var(--card);
}

.avatar-actions {
  display: flex;
  gap: 40rpx;
  margin-top: 48rpx;
}

.avatar-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12rpx;
  padding: 24rpx 36rpx;
  background: var(--card);
  border: 1rpx solid var(--card-border);
  border-radius: var(--radius);
}

.avatar-btn:active {
  opacity: 0.7;
}

.btn-icon {
  font-size: 48rpx;
}

.btn-label {
  font-size: 24rpx;
  color: var(--text);
}
</style>
