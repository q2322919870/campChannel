<template>
  <view class="drafts-page">
    <view class="header-card">
      <text class="page-title">我的草稿</text>
      <text class="page-subtitle">未发布的帖子草稿</text>
    </view>

    <view v-if="loading" class="loading-state">
      <text class="loading-text">加载中...</text>
    </view>

    <view v-else-if="drafts.length === 0" class="empty-state">
      <text class="empty-icon">📋</text>
      <text class="empty-text">暂无草稿</text>
      <text class="empty-hint">发布帖子时点击"存草稿"可保存到这里</text>
    </view>

    <view v-else class="drafts-list">
      <view
        v-for="d in drafts"
        :key="d.id"
        class="draft-item"
        @tap="editDraft(d)"
      >
        <view class="draft-header">
          <text class="draft-channel">{{ d.channelName || '未选频道' }}</text>
          <text class="draft-time">{{ formatTime(d.updatedAt) }}</text>
        </view>
        <text class="draft-content">{{ d.content }}</text>
        <view v-if="d.images && d.images.length" class="draft-images-hint">
          <text>📷 {{ d.images.length }}张图片</text>
        </view>
        <view class="draft-actions">
          <button class="btn-edit" @tap.stop="editDraft(d)">编辑</button>
          <button class="btn-publish" @tap.stop="publishDraft(d)">发布</button>
          <button class="btn-delete" @tap.stop="deleteDraft(d)">删除</button>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import request, { processImageUrl } from '../../utils/request'

interface Draft {
  id: number
  channelId: number
  channelName: string
  content: string
  images: string[]
  topic: string
  isAnonymous: boolean
  updatedAt: string
}

const drafts = ref<Draft[]>([])
const loading = ref(true)

onMounted(() => {
  loadDrafts()
})

async function loadDrafts() {
  loading.value = true
  try {
    const res = await request<any>('/drafts?page=1&size=50')
    if (res?.code === 200) {
      const list = res.data?.records || res.data || []
      drafts.value = list.map((d: any) => ({
        id: d.id,
        channelId: d.channelId || 0,
        channelName: d.channelName || '',
        content: d.content || '',
        images: d.images ? (Array.isArray(d.images) ? d.images : (() => { try { return JSON.parse(d.images) } catch (_) { return [] } })()) : [],
        topic: d.topic || '',
        isAnonymous: d.isAnonymous || false,
        updatedAt: d.updatedAt || d.createdAt || '',
      }))
    }
  } catch (_) {
    uni.showToast({ title: '加载失败', icon: 'none' })
  } finally {
    loading.value = false
  }
}

function editDraft(draft: Draft) {
  uni.navigateTo({ url: `/pages/post/create?draftId=${draft.id}` })
}

async function publishDraft(draft: Draft) {
  uni.showModal({
    title: '发布草稿',
    content: '确定要发布这篇草稿吗？',
    success: async (res) => {
      if (res.confirm) {
        try {
          const r = await request<any>({
            url: `/drafts/${draft.id}/publish`,
            method: 'POST',
          })
          if (r?.code === 200) {
            uni.showToast({ title: '发布成功', icon: 'success' })
            drafts.value = drafts.value.filter((d) => d.id !== draft.id)
          } else {
            uni.showToast({ title: r?.message || '发布失败', icon: 'none' })
          }
        } catch (_) {
          uni.showToast({ title: '发布失败', icon: 'none' })
        }
      }
    },
  })
}

async function deleteDraft(draft: Draft) {
  uni.showModal({
    title: '删除草稿',
    content: '确定要删除这篇草稿吗？此操作不可恢复。',
    success: async (res) => {
      if (res.confirm) {
        try {
          const r = await request<any>({
            url: `/drafts/${draft.id}`,
            method: 'DELETE',
          })
          if (r?.code === 200) {
            uni.showToast({ title: '已删除', icon: 'success' })
            drafts.value = drafts.value.filter((d) => d.id !== draft.id)
          }
        } catch (_) {
          uni.showToast({ title: '删除失败', icon: 'none' })
        }
      }
    },
  })
}

function formatTime(t: string): string {
  if (!t) return ''
  const d = new Date(t)
  const now = new Date()
  const diff = now.getTime() - d.getTime()
  if (diff < 60000) return '刚刚'
  if (diff < 3600000) return `${Math.floor(diff / 60000)}分钟前`
  if (diff < 86400000) return `${Math.floor(diff / 3600000)}小时前`
  return `${d.getMonth() + 1}/${d.getDate()} ${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`
}
</script>

<style scoped>
.drafts-page {
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

.drafts-list {
  display: flex;
  flex-direction: column;
  gap: 16rpx;
}

.draft-item {
  background: var(--card);
  border: 1rpx solid var(--card-border);
  border-radius: var(--radius);
  padding: 24rpx;
  box-shadow: var(--shadow-sm);
}

.draft-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12rpx;
}

.draft-channel {
  font-size: 24rpx;
  color: var(--primary);
  background: var(--primary-soft);
  padding: 4rpx 16rpx;
  border-radius: 100rpx;
}

.draft-time {
  font-size: 22rpx;
  color: var(--text-muted);
}

.draft-content {
  font-size: 28rpx;
  color: var(--text);
  line-height: 1.6;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
  margin-bottom: 12rpx;
}

.draft-images-hint {
  font-size: 24rpx;
  color: var(--text-muted);
  margin-bottom: 12rpx;
}

.draft-actions {
  display: flex;
  gap: 12rpx;
  padding-top: 12rpx;
  border-top: 1rpx solid var(--card-border);
}

.btn-edit {
  flex: 1;
  height: 60rpx;
  background: var(--primary-soft);
  border-radius: 30rpx;
  color: var(--primary);
  font-size: 24rpx;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
}

.btn-publish {
  flex: 1;
  height: 60rpx;
  background: var(--primary-gradient);
  border-radius: 30rpx;
  color: #ffffff;
  font-size: 24rpx;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
}

.btn-delete {
  height: 60rpx;
  padding: 0 32rpx;
  background: var(--accent-soft);
  border-radius: 30rpx;
  color: var(--accent);
  font-size: 24rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
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
</style>
