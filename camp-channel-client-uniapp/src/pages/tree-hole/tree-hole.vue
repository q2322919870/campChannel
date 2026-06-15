<template>
  <view class="tree-hole-page">
    <view class="page-header">
      <text class="page-title">树洞</text>
      <text class="page-subtitle">匿名分享你的心事，24小时后自动消失</text>
    </view>

    <view class="create-btn-wrapper">
      <button class="create-btn" @tap="showCreateModal">
        <text class="btn-icon">✍️</text>
        <text class="btn-text">发布匿名帖子</text>
      </button>
    </view>

    <view v-if="loading && posts.length === 0" class="loading-state">
      <text class="loading-text">加载中...</text>
    </view>

    <view v-else-if="posts.length === 0" class="empty-state">
      <text class="empty-icon">🌫️</text>
      <text class="empty-text">暂无树洞帖子</text>
      <text class="empty-hint">成为第一个分享心事的人吧</text>
    </view>

    <scroll-view v-else scroll-y class="posts-list" @scrolltolower="loadMore">
      <view
        v-for="post in posts"
        :key="post.id"
        class="post-item"
        :class="{ revealed: post.revealed }"
        @tap="toggleReveal(post)"
      >
        <view class="post-mist" v-if="!post.revealed">
          <text class="mist-icon">🌫️</text>
          <text class="mist-text">点击揭开迷雾</text>
        </view>

        <view v-else class="post-content">
          <text class="post-text">{{ post.content }}</text>
          <view class="post-meta">
            <text class="post-time">{{ formatTime(post.createTime) }}</text>
            <text class="post-hint">24小时后消失</text>
          </view>
        </view>
      </view>

      <view v-if="loadingMore" class="loading-more">
        <text>加载中...</text>
      </view>
      <view v-if="!hasMore && posts.length > 0" class="no-more">
        <text>没有更多了</text>
      </view>
    </scroll-view>

    <!-- 发布弹窗 -->
    <view v-if="showModal" class="modal-overlay" @tap="closeModal">
      <view class="modal-content" @tap.stop>
        <text class="modal-title">发布匿名帖子</text>
        <textarea
          v-model="newPostContent"
          placeholder="在这里写下你的心事..."
          class="post-textarea"
          maxlength="500"
        />
        <text class="char-count">{{ newPostContent.length }}/500</text>
        <view class="modal-actions">
          <button class="btn-cancel" @tap="closeModal">取消</button>
          <button
            class="btn-submit"
            :disabled="!newPostContent.trim() || submitting"
            @tap="submitPost"
          >
            {{ submitting ? '发布中...' : '发布' }}
          </button>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import request from '../../utils/request'

interface TreeHolePost {
  id: number
  content: string
  createTime: string
  revealed: boolean
}

const posts = ref<TreeHolePost[]>([])
const loading = ref(true)
const loadingMore = ref(false)
const hasMore = ref(true)
const page = ref(1)

const showModal = ref(false)
const newPostContent = ref('')
const submitting = ref(false)

onMounted(() => {
  loadPosts()
})

async function loadPosts() {
  loading.value = true
  try {
    const res = await request<any>(`/tree-hole?page=1&size=20`)
    if (res?.code === 200) {
      const list = res.data?.records || res.data || []
      posts.value = list.map((p: any) => ({
        id: p.id,
        content: p.content || '',
        createTime: p.createTime || p.createdAt || '',
        revealed: false,
      }))
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
    const res = await request<any>(`/tree-hole?page=${page.value}&size=20`)
    if (res?.code === 200) {
      const list = res.data?.records || res.data || []
      posts.value = [
        ...posts.value,
        ...list.map((p: any) => ({
          id: p.id,
          content: p.content || '',
          createTime: p.createTime || p.createdAt || '',
          revealed: false,
        })),
      ]
      hasMore.value = list.length >= 20
    }
  } catch (_) {
    uni.showToast({ title: '加载失败', icon: 'none' })
  } finally {
    loadingMore.value = false
  }
}

function toggleReveal(post: TreeHolePost) {
  post.revealed = !post.revealed
}

function showCreateModal() {
  showModal.value = true
}

function closeModal() {
  showModal.value = false
  newPostContent.value = ''
}

async function submitPost() {
  if (!newPostContent.value.trim()) return
  submitting.value = true
  try {
    const res = await request<any>({
      url: '/tree-hole',
      method: 'POST',
      data: { content: newPostContent.value },
    })
    if (res?.code === 200) {
      uni.showToast({ title: '发布成功', icon: 'success' })
      closeModal()
      loadPosts()
    } else {
      uni.showToast({ title: res?.message || '发布失败', icon: 'none' })
    }
  } catch (_) {
    uni.showToast({ title: '发布失败', icon: 'none' })
  } finally {
    submitting.value = false
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
  return `${d.getMonth() + 1}/${d.getDate()} ${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`
}
</script>

<style scoped>
.tree-hole-page {
  min-height: 100vh;
  background: var(--bg);
  padding: 32rpx;
}

.page-header {
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

.create-btn-wrapper {
  margin-bottom: 24rpx;
}

.create-btn {
  width: 100%;
  height: 88rpx;
  background: var(--primary-gradient);
  border-radius: 44rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12rpx;
  border: none;
  box-shadow: 0 8rpx 24rpx rgba(99, 102, 241, 0.25);
}

.btn-icon {
  font-size: 32rpx;
}

.btn-text {
  font-size: 30rpx;
  font-weight: 600;
  color: #ffffff;
}

.posts-list {
  height: calc(100vh - 400rpx);
}

.post-item {
  background: var(--card);
  border: 1rpx solid var(--card-border);
  border-radius: var(--radius);
  padding: 32rpx;
  margin-bottom: 16rpx;
  box-shadow: var(--shadow-sm);
  min-height: 200rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s ease;
}

.post-mist {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16rpx;
}

.mist-icon {
  font-size: 64rpx;
  opacity: 0.6;
}

.mist-text {
  font-size: 26rpx;
  color: var(--text-muted);
}

.post-content {
  width: 100%;
}

.post-text {
  font-size: 30rpx;
  color: var(--text);
  line-height: 1.8;
  display: block;
  margin-bottom: 20rpx;
}

.post-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.post-time {
  font-size: 24rpx;
  color: var(--text-muted);
}

.post-hint {
  font-size: 22rpx;
  color: var(--accent);
  background: var(--accent-soft);
  padding: 4rpx 16rpx;
  border-radius: 100rpx;
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

/* 弹窗样式 */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
}

.modal-content {
  width: 85%;
  max-width: 600rpx;
  background: var(--card);
  border-radius: var(--radius-lg);
  padding: 40rpx 32rpx;
  box-shadow: var(--shadow-lg);
}

.modal-title {
  font-size: 36rpx;
  font-weight: 700;
  color: var(--text);
  display: block;
  margin-bottom: 24rpx;
  text-align: center;
}

.post-textarea {
  width: 100%;
  min-height: 300rpx;
  padding: 20rpx;
  background: var(--bg);
  border: 1rpx solid var(--card-border);
  border-radius: var(--radius);
  font-size: 28rpx;
  color: var(--text);
  resize: none;
  margin-bottom: 12rpx;
}

.char-count {
  font-size: 22rpx;
  color: var(--text-muted);
  text-align: right;
  display: block;
  margin-bottom: 24rpx;
}

.modal-actions {
  display: flex;
  gap: 16rpx;
}

.btn-cancel {
  flex: 1;
  height: 80rpx;
  background: var(--bg);
  border-radius: 40rpx;
  color: var(--text-secondary);
  font-size: 28rpx;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
}

.btn-submit {
  flex: 1;
  height: 80rpx;
  background: var(--primary-gradient);
  border-radius: 40rpx;
  color: #ffffff;
  font-size: 28rpx;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
  box-shadow: 0 8rpx 24rpx rgba(99, 102, 241, 0.25);
}

.btn-submit[disabled] {
  opacity: 0.5;
}
</style>
