<template>
  <view class="admin-container">
    <view class="admin-header">
      <text class="admin-title">管理后台</text>
      <text class="admin-subtitle">仅管理员可见</text>
    </view>

    <view class="stats-grid">
      <view class="stat-card">
        <text class="stat-icon">👥</text>
        <text class="stat-value">{{ stats.userCount }}</text>
        <text class="stat-desc">注册用户</text>
      </view>
      <view class="stat-card">
        <text class="stat-icon">📄</text>
        <text class="stat-value">{{ stats.postCount }}</text>
        <text class="stat-desc">帖子总数</text>
      </view>
      <view class="stat-card">
        <text class="stat-icon">💬</text>
        <text class="stat-value">{{ stats.commentCount }}</text>
        <text class="stat-desc">评论数量</text>
      </view>
      <view class="stat-card">
        <text class="stat-icon">📊</text>
        <text class="stat-value">{{ stats.channelCount }}</text>
        <text class="stat-desc">频道数量</text>
      </view>
    </view>

    <view class="section">
      <view class="section-header">
        <text class="section-title">发布公告</text>
      </view>
      <textarea
        v-model="announcementContent"
        placeholder="输入公告内容..."
        class="announcement-input"
        placeholder-class="ph"
      />
      <button class="btn-announce" @tap="publishAnnouncement" :disabled="!announcementContent.trim()">
        发布公告
      </button>
    </view>

    <view class="section">
      <view class="section-header">
        <text class="section-title">举报处理</text>
      </view>
      <view v-if="reports.length === 0" class="no-data">
        <text>暂无待处理举报</text>
      </view>
      <view v-for="r in reports" :key="r.id" class="report-item">
        <view class="report-info">
          <text class="report-reason">举报原因：{{ r.reason }}</text>
          <text class="report-target">目标：{{ r.targetType }} #{{ r.targetId }}</text>
          <text class="report-user">举报人：{{ r.reporterName || r.reporterId }}</text>
        </view>
        <view class="report-actions">
          <button class="btn-approve" @tap="handleReport(r.id, 'DISMISS')">驳回</button>
          <button class="btn-reject" @tap="handleReport(r.id, 'DELETE')">删除</button>
        </view>
      </view>
    </view>

    <view class="section">
      <view class="section-header">
        <text class="section-title">用户管理</text>
      </view>
      <view class="search-bar-small">
        <input
          v-model="userSearch"
          type="text"
          placeholder="搜索用户..."
          class="search-input-small"
          placeholder-class="ph"
          @confirm="searchUsers"
        />
        <button class="btn-search-small" @tap="searchUsers">搜索</button>
      </view>
      <view v-for="u in userResults" :key="u.id" class="user-item">
        <image v-if="u.avatar" :src="u.avatar" mode="aspectFill" class="user-avatar-small" />
        <view v-else class="user-avatar-placeholder-small">
          <text>{{ u.username?.charAt(0) || '?' }}</text>
        </view>
        <view class="user-item-info">
          <text class="user-item-name">{{ u.username }}</text>
          <text class="user-item-email">{{ u.email }}</text>
        </view>
        <view class="user-item-role">
          <text>{{ u.role === 'ADMIN' ? '管理员' : u.role === 'OWNER' ? '超级管理员' : '用户' }}</text>
        </view>
        <button v-if="u.role !== 'OWNER'" class="btn-ban" @tap="toggleBan(u)">
          {{ u.status === 0 ? '解封' : '封禁' }}
        </button>
      </view>
      <view v-if="userResults.length === 0 && userSearched" class="no-data">
        <text>未找到用户</text>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useAuthStore } from '../../stores/auth'
import request from '../../utils/request'

const authStore = useAuthStore()

const stats = ref({ userCount: 0, postCount: 0, commentCount: 0, channelCount: 0 })
const announcementContent = ref('')
const reports = ref<any[]>([])
const userSearch = ref('')
const userResults = ref<any[]>([])
const userSearched = ref(false)

onMounted(async () => {
  if (!authStore.token) {
    uni.reLaunch({ url: '/pages/login/login' })
    return
  }
  if (authStore.userInfo?.role !== 'ADMIN' && authStore.userInfo?.role !== 'OWNER') {
    uni.showToast({ title: '无管理员权限', icon: 'none' })
    uni.navigateBack()
    return
  }
  await Promise.all([loadStats(), loadReports()])
})

async function loadStats() {
  try {
    const res = await request<any>('/admin/stats')
    if (res?.code === 200) {
      stats.value = res.data || stats.value
    }
  } catch (_) {}
}

async function loadReports() {
  try {
    const res = await request<any>('/reports?status=PENDING')
    if (res?.code === 200) {
      reports.value = res.data || []
    }
  } catch (_) {}
}

async function publishAnnouncement() {
  if (!announcementContent.value.trim()) return
  try {
    const res = await request<any>({
      url: '/admin/announcement',
      method: 'POST',
      data: { content: announcementContent.value.trim() },
    })
    if (res?.code === 200) {
      uni.showToast({ title: '公告发布成功', icon: 'success' })
      announcementContent.value = ''
    } else {
      uni.showToast({ title: res?.message || '发布失败', icon: 'none' })
    }
  } catch (_) {
    uni.showToast({ title: '发布失败', icon: 'none' })
  }
}

async function handleReport(reportId: number, action: string) {
  try {
    const res = await request<any>({
      url: `/reports/${reportId}/handle`,
      method: 'POST',
      data: { 
        approved: action === 'DELETE',
        note: action === 'DELETE' ? '删除内容' : '驳回举报'
      },
    })
    if (res?.code === 200) {
      uni.showToast({ title: action === 'DELETE' ? '已处理' : '已驳回', icon: 'success' })
      reports.value = reports.value.filter((r) => r.id !== reportId)
    }
  } catch (_) {}
}

async function searchUsers() {
  if (!userSearch.value.trim()) return
  userSearched.value = true
  try {
    const res = await request<any>(`/admin/users?q=${encodeURIComponent(userSearch.value.trim())}`)
    if (res?.code === 200) {
      userResults.value = res.data || []
    }
  } catch (_) {
    uni.showToast({ title: '搜索失败', icon: 'none' })
  }
}

async function toggleBan(user: any) {
  const newStatus = user.status === 1 ? 0 : 1
  const action = newStatus === 0 ? '禁用' : '启用'
  uni.showModal({
    title: `确认${action}`,
    content: `确定要${action}用户 ${user.username} 吗？`,
    success: async (res) => {
      if (res.confirm) {
        try {
          const r = await request<any>({
            url: `/admin/users/${user.id}/status`,
            method: 'PUT',
            data: { status: newStatus },
          })
          if (r?.code === 200) {
            user.status = newStatus
            uni.showToast({ title: `${action}成功`, icon: 'success' })
          }
        } catch (_) {}
      }
    },
  })
}
</script>

<style>
.admin-container {
  min-height: 100vh;
  background-color: var(--bg);
  padding: 30rpx;
  box-sizing: border-box;
}

.admin-header {
  text-align: center;
  padding: 40rpx 0;
}

.admin-title {
  font-size: 40rpx;
  font-weight: bold;
  color: var(--text);
  display: block;
  margin-bottom: 8rpx;
}

.admin-subtitle {
  font-size: 24rpx;
  color: var(--text-muted);
}

.stats-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16rpx;
  margin-bottom: 30rpx;
}

.stat-card {
  background-color: var(--card);
  border-radius: 24rpx;
  padding: 30rpx;
  text-align: center;
  border: 1px solid var(--card-border);
}

.stat-icon {
  font-size: 44rpx;
  display: block;
  margin-bottom: 12rpx;
}

.stat-value {
  font-size: 36rpx;
  font-weight: bold;
  color: var(--text);
  display: block;
  margin-bottom: 4rpx;
}

.stat-desc {
  font-size: 22rpx;
  color: var(--text-muted);
}

.section {
  margin-bottom: 30rpx;
}

.section-header {
  margin-bottom: 16rpx;
}

.section-title {
  font-size: 30rpx;
  font-weight: bold;
  color: var(--text);
  padding-left: 12rpx;
  border-left: 6rpx solid var(--primary);
}

.announcement-input {
  width: 100%;
  min-height: 160rpx;
  background-color: var(--card);
  border-radius: 20rpx;
  padding: 24rpx;
  box-sizing: border-box;
  border: 1px solid var(--card-border);
  font-size: 26rpx;
  color: var(--text);
  margin-bottom: 16rpx;
}

.ph {
  color: var(--text-muted);
}

.btn-announce {
  width: 100%;
  height: 80rpx;
  background: linear-gradient(135deg, var(--primary), var(--primary));
  border-radius: 20rpx;
  color: #ffffff;
  font-size: 28rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
}

.btn-announce::after {
  border: none;
}

.no-data {
  text-align: center;
  padding: 40rpx 0;
  color: var(--text-muted);
  font-size: 26rpx;
}

.report-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20rpx;
  background-color: var(--card);
  border-radius: 20rpx;
  margin-bottom: 12rpx;
  border: 1px solid var(--card-border);
}

.report-info {
  flex: 1;
}

.report-reason {
  font-size: 26rpx;
  color: var(--text);
  display: block;
  margin-bottom: 4rpx;
  font-weight: 500;
}

.report-target,
.report-user {
  font-size: 22rpx;
  color: var(--text-muted);
  display: block;
}

.report-actions {
  display: flex;
  gap: 12rpx;
  flex-shrink: 0;
  margin-left: 16rpx;
}

.btn-approve {
  height: 56rpx;
  padding: 0 20rpx;
  background: var(--bg);
  border-radius: 28rpx;
  color: var(--text);
  font-size: 22rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px solid var(--card-border);
}

.btn-reject {
  height: 56rpx;
  padding: 0 20rpx;
  background: var(--danger);
  border-radius: 28rpx;
  color: #ffffff;
  font-size: 22rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
}

.btn-approve::after,
.btn-reject::after {
  border: none;
}

.search-bar-small {
  display: flex;
  gap: 16rpx;
  margin-bottom: 16rpx;
}

.search-input-small {
  flex: 1;
  height: 72rpx;
  background-color: var(--card);
  border-radius: 36rpx;
  padding: 0 24rpx;
  font-size: 26rpx;
  color: var(--text);
  border: 1px solid var(--card-border);
}

.btn-search-small {
  height: 72rpx;
  padding: 0 28rpx;
  background: linear-gradient(135deg, var(--primary), var(--primary));
  border-radius: 36rpx;
  color: #ffffff;
  font-size: 24rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
  flex-shrink: 0;
}

.btn-search-small::after {
  border: none;
}

.user-item {
  display: flex;
  align-items: center;
  padding: 20rpx;
  background-color: var(--card);
  border-radius: 20rpx;
  margin-bottom: 12rpx;
  border: 1px solid var(--card-border);
}

.user-avatar-small {
  width: 64rpx;
  height: 64rpx;
  border-radius: 50%;
  margin-right: 16rpx;
}

.user-avatar-placeholder-small {
  width: 64rpx;
  height: 64rpx;
  border-radius: 50%;
  background: var(--primary-soft);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24rpx;
  color: var(--primary);
  font-weight: bold;
  margin-right: 16rpx;
  flex-shrink: 0;
}

.user-item-info {
  flex: 1;
  min-width: 0;
}

.user-item-name {
  font-size: 26rpx;
  font-weight: 600;
  color: var(--text);
  display: block;
  margin-bottom: 4rpx;
}

.user-item-email {
  font-size: 22rpx;
  color: var(--text-muted);
}

.user-item-role {
  font-size: 22rpx;
  color: var(--text-muted);
  margin: 0 16rpx;
}

.btn-ban {
  height: 52rpx;
  padding: 0 20rpx;
  background: var(--danger);
  border-radius: 26rpx;
  color: #ffffff;
  font-size: 22rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
  flex-shrink: 0;
}

.btn-ban::after {
  border: none;
}
</style>
