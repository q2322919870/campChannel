<template>
  <view class="post-detail">
    <scroll-view scroll-y class="detail-content">
      <!-- Post Card -->
      <view class="post-card">
        <view class="post-author-row">
          <view class="post-avatar" @tap.stop="showUserCard">
            <image v-if="post.avatar" :src="post.avatar" mode="aspectFill" class="post-avatar-img" />
            <view v-else class="avatar-placeholder">
              <text>{{ (post.author || '?').charAt(0) }}</text>
            </view>
          </view>
          <view class="author-info">
            <view class="author-name">
              <text>{{ post.author || '未知用户' }}</text>
              <text v-if="post.userChannelRole" class="role-badge" :class="'role-' + post.userChannelRole">{{ roleLabel }}</text>
            </view>
            <text class="post-time">{{ post.time || '' }}</text>
          </view>
        </view>
        
        <text class="post-title">{{ post.title }}</text>
        <text v-if="post.editCount > 0" class="edited-tag">已编辑</text>
        <text class="post-content">{{ post.content }}</text>
        
        <view v-if="post.images && post.images.length" class="post-images">
          <image 
            v-for="(img, i) in post.images" 
            :key="i" 
            :src="img" 
            mode="aspectFill"
            class="post-image"
            @tap="previewImage(i)"
          />
        </view>
        
        <view class="post-actions">
          <view class="action-btn" :class="{ liked: isLiked }" @tap="toggleLike">
            <text class="action-icon">{{ isLiked ? '❤' : '♡' }}</text>
            <text class="action-text">{{ post.likeCount }}</text>
          </view>
          <view class="action-btn">
            <text class="action-icon">💬</text>
            <text class="action-text">{{ comments.length || post.commentCount }}</text>
          </view>
          <view class="action-btn" :class="{ favourited: isFavourited }" @tap="toggleFavourite">
            <text class="action-icon">{{ isFavourited ? '★' : '☆' }}</text>
            <text class="action-text">收藏</text>
          </view>
          <view v-if="currentUserId === post.userId" class="action-btn" @tap="editPost">
            <text class="action-icon">✏</text>
          </view>
          <view v-if="currentUserId === post.userId" class="action-btn danger" @tap="deletePost">
            <text class="action-icon">🗑</text>
          </view>
          <view class="action-btn" @tap="sharePost">
            <text class="action-icon">↗</text>
          </view>
        </view>
      </view>

      <!-- Comments Section -->
      <view class="comments-section">
        <text class="section-title">评论 ({{ comments.length }})</text>
        
        <view class="comment-input">
          <input 
            v-model="newComment" 
            placeholder="写下你的评论...（使用 @用户名 可以提及他人）" 
            class="comment-input-field"
            @confirm="addComment"
          />
          <button class="btn-send" @tap="addComment">发送</button>
        </view>
        
        <view v-for="c in comments" :key="c.id" class="comment-item">
          <view class="comment-avatar">
            <image v-if="c.avatar" :src="c.avatar" mode="aspectFill" class="comment-avatar-img" />
            <view v-else class="avatar-placeholder small">
              <text>{{ (c.username || '?').charAt(0) }}</text>
            </view>
          </view>
          <view class="comment-body">
            <view class="comment-author">
              <text>{{ c.username || '匿名' }}</text>
              <text v-if="c.userId === currentUserId" class="me-badge">(我)</text>
            </view>
            <text class="comment-text">{{ c.content }}</text>
            <view class="comment-footer">
              <text class="comment-time">{{ c.time || '' }}</text>
              <view class="comment-like-btn" :class="{ liked: c.isLiked }" @tap="toggleCommentLike(c)">
                <text>{{ c.isLiked ? '❤' : '♡' }} {{ c.likeCount || '' }}</text>
              </view>
              <text v-if="currentUserId === c.userId || currentUserId === post.userId" class="delete-comment" @tap="deleteComment(c.id)">删除</text>
            </view>
          </view>
        </view>
        
        <view v-if="comments.length === 0" class="no-comments">
          <text>暂无评论，快来抢沙发</text>
        </view>
      </view>
    </scroll-view>
  </view>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { onShareAppMessage, onShareTimeline } from '@dcloudio/uni-app'
import { useAuthStore } from '../../stores/auth'
import request, { processImageUrl } from '../../utils/request'

const authStore = useAuthStore()
const currentUserId = computed(() => authStore.userInfo?.userId || 0)

interface Post {
  id: number
  userId: number
  author: string
  avatar: string
  userChannelRole?: string
  title: string
  content: string
  images: string[]
  time: string
  editCount: number
  likeCount: number
  commentCount: number
}

interface Comment {
  id: number
  content: string
  username: string
  avatar: string
  userId: number
  time: string
  isLiked: boolean
  likeCount: number
}

const post = ref<Post>({
  id: 0,
  userId: 0,
  author: '',
  avatar: '',
  title: '',
  content: '',
  images: [],
  time: '',
  editCount: 0,
  likeCount: 0,
  commentCount: 0,
})

const isLiked = ref(false)
const isFavourited = ref(false)
const comments = ref<Comment[]>([])
const newComment = ref('')
const showReport = ref(false)
const postId = ref(0)

const roleLabel = computed(() => {
  const labels: Record<string, string> = { 
    OWNER: '频道主', 
    ADMIN: '管理员', 
    MEMBER: '成员' 
  }
  return labels[post.value.userChannelRole || ''] || ''
})

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

onMounted(() => {
  // Get post ID from route
  const pages = getCurrentPages()
  const page = pages[pages.length - 1] as any
  const opts = page?.options || {}
  postId.value = parseInt(opts.id || '0')
  
  if (postId.value) {
    fetchPost()
    fetchComments()
    // Increment view count
    request<any>(`/posts/${postId.value}/view`).catch(() => {})
  }
})

// 微信原生分享 - 分享给朋友
onShareAppMessage(() => {
  return {
    title: post.value.title || post.value.content.substring(0, 50) || 'Camp Channel',
    path: `/pages/post/detail?id=${postId.value}`,
    imageUrl: post.value.images?.[0] || '',
  }
})

// 微信原生分享 - 分享到朋友圈
onShareTimeline(() => {
  return {
    title: post.value.title || post.value.content.substring(0, 50) || 'Camp Channel',
    query: `id=${postId.value}`,
    imageUrl: post.value.images?.[0] || '',
  }
})

async function fetchPost() {
  try {
    const res = await request<any>(`/posts/${postId.value}`)
    if (res?.code === 200) {
      const data = res.data
      post.value = {
        id: data.id,
        userId: data.userId || 0,
        author: data.username || data.author || '用户',
        avatar: processImageUrl(data.avatar || ''),
        userChannelRole: data.userChannelRole,
        title: data.topic || data.title || (data.content ? data.content.substring(0, 50) : '帖子'),
        content: data.content || '',
        images: safeParseImages(data.images),
        time: formatTime(data.createTime || data.createdAt),
        editCount: data.editCount || 0,
        likeCount: data.likeCount || 0,
        commentCount: data.commentCount || 0,
      }
      // Use isLiked directly from post response
      isLiked.value = data.isLiked || false
    }
    
    // Get favourite status (non-critical, fail silently)
    try {
      const favRes = await request<any>(`/posts/${postId.value}/favourite/status`)
      if (favRes?.code === 200 && favRes.data) {
        isFavourited.value = favRes.data.isFavourited || false
      }
    } catch (_) {}
  } catch (_) {
    uni.showToast({ title: '加载失败', icon: 'none' })
  }
}

async function fetchComments() {
  try {
    const res = await request<any>(`/posts/${postId.value}/comments?page=1&size=50`)
    if (res?.code === 200 && Array.isArray(res.data)) {
      comments.value = res.data.map((c: any) => ({
        id: c.id,
        content: c.content,
        username: c.username || '匿名',
        avatar: processImageUrl(c.avatar || ''),
        userId: c.userId || 0,
        time: formatTime(c.createTime || c.createdAt),
        isLiked: c.isLiked || false,
        likeCount: c.likeCount || 0,
      }))
    }
  } catch (_) {}
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

async function toggleLike() {
  try {
    const res = await request<any>({
      url: `/posts/${postId.value}/like`,
      method: 'POST',
    })
    if (res?.code === 200 && res.data) {
      isLiked.value = res.data.liked
      post.value.likeCount = res.data.likeCount ?? (res.data.liked ? post.value.likeCount + 1 : Math.max(post.value.likeCount - 1, 0))
    } else {
      // Optimistic toggle if server doesn't return structured data
      isLiked.value = !isLiked.value
      post.value.likeCount += isLiked.value ? 1 : -1
      post.value.likeCount = Math.max(post.value.likeCount, 0)
    }
  } catch (_) {}
}

async function addComment() {
  if (!newComment.value.trim()) return
  
  try {
    const res = await request<any>({
      url: `/posts/${postId.value}/comments`,
      method: 'POST',
      data: {
        content: newComment.value,
        parentId: null,
      },
    })
    if (res?.code === 200) {
      const c = res.data
      comments.value.unshift({
        id: c.id || Date.now(),
        content: c.content || newComment.value,
        username: c.username || authStore.userInfo?.username || '我',
        avatar: processImageUrl(c.avatar || ''),
        userId: c.userId || currentUserId.value,
        time: '刚刚',
        isLiked: false,
        likeCount: 0,
      })
      newComment.value = ''
      uni.showToast({ title: '评论成功', icon: 'success' })
    }
  } catch (_) {
    uni.showToast({ title: '评论失败', icon: 'none' })
  }
}

function sharePost() {
  // Use clipboard as reliable share method (uni.showShareMenu requires page-level onShareAppMessage)
  const shareText = `${post.value.author}: ${post.value.content.substring(0, 100)}...`
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

function editPost() {
  uni.navigateTo({ url: `/pages/post/create?editId=${post.value.id}` })
}

async function toggleFavourite() {
  try {
    const res = await request<any>({
      url: `/posts/${postId.value}/favourite`,
      method: 'POST',
    })
    if (res?.code === 200) {
      isFavourited.value = !isFavourited.value
      uni.showToast({ title: isFavourited.value ? '已收藏' : '已取消收藏', icon: 'success' })
    }
  } catch (_) {}
}

async function toggleCommentLike(comment: Comment) {
  try {
    const res = await request<any>({
      url: `/posts/${postId.value}/comments/${comment.id}/like`,
      method: 'POST',
    })
    if (res?.code === 200) {
      const liked = res.data === true || res.data?.liked === true
      comment.isLiked = liked
      comment.likeCount = liked ? (comment.likeCount || 0) + 1 : Math.max((comment.likeCount || 0) - 1, 0)
    }
  } catch (_) {}
}

async function deletePost() {
  uni.showModal({
    title: '提示',
    content: '确定删除此帖子？',
    success: async (res) => {
      if (res.confirm) {
        try {
          await request<any>({
            url: `/posts/${postId.value}`,
            method: 'DELETE',
          })
          uni.showToast({ title: '帖子已删除', icon: 'success' })
          setTimeout(() => {
            uni.navigateBack()
          }, 1500)
        } catch (_) {
          uni.showToast({ title: '删除失败', icon: 'none' })
        }
      }
    },
  })
}

async function deleteComment(commentId: number) {
  uni.showModal({
    title: '提示',
    content: '确定删除此评论？',
    success: async (res) => {
      if (res.confirm) {
        try {
          await request<any>({
            url: `/posts/${postId.value}/comments/${commentId}`,
            method: 'DELETE',
          })
          comments.value = comments.value.filter(c => c.id !== commentId)
          uni.showToast({ title: '评论已删除', icon: 'success' })
        } catch (_) {
          uni.showToast({ title: '删除失败', icon: 'none' })
        }
      }
    },
  })
}

function showUserCard() {
  if (post.value.userId) {
    uni.navigateTo({ url: `/pages/user/profile?userId=${post.value.userId}` })
  }
}

function previewImage(index: number) {
  uni.previewImage({
    urls: post.value.images,
    current: index,
  })
}
</script>

<style scoped>
.post-detail {
  min-height: 100vh;
  background-color: var(--bg);
}

.detail-content {
  height: 100vh;
}

.post-card {
  background-color: var(--card);
  padding: 32rpx;
  margin-bottom: 16rpx;
}

.post-author-row {
  display: flex;
  align-items: center;
  margin-bottom: 24rpx;
}

.post-avatar {
  width: 80rpx;
  height: 80rpx;
  border-radius: 50%;
  overflow: hidden;
  margin-right: 16rpx;
  flex-shrink: 0;
  background: linear-gradient(135deg, var(--primary), var(--accent));
  display: flex;
  align-items: center;
  justify-content: center;
}

.post-avatar-img {
  width: 100%;
  height: 100%;
}

.avatar-placeholder {
  color: #ffffff;
  font-size: 36rpx;
  font-weight: bold;
}

.avatar-placeholder.small {
  width: 60rpx;
  height: 60rpx;
  font-size: 28rpx;
}

.author-info {
  flex: 1;
}

.author-name {
  font-size: 28rpx;
  font-weight: 600;
  color: var(--text);
  margin-bottom: 4rpx;
  display: flex;
  align-items: center;
  gap: 8rpx;
}

.role-badge {
  font-size: 20rpx;
  padding: 2rpx 12rpx;
  border-radius: 8rpx;
}

.role-OWNER {
  background: linear-gradient(135deg, #FFD700, #FFA500);
  color: #ffffff;
}

.role-ADMIN {
  background: linear-gradient(135deg, var(--primary), var(--accent));
  color: #ffffff;
}

.role-MEMBER {
  background: var(--bg);
  color: var(--text-soft);
}

.post-time {
  font-size: 22rpx;
  color: var(--text-muted);
}

.post-title {
  font-size: 36rpx;
  font-weight: bold;
  color: var(--text);
  margin-bottom: 16rpx;
  line-height: 1.4;
  display: block;
}

.post-content {
  font-size: 28rpx;
  color: var(--text-soft);
  line-height: 1.6;
  margin-bottom: 24rpx;
  display: block;
}

.post-images {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8rpx;
  margin-bottom: 24rpx;
}

.post-image {
  width: 100%;
  height: 200rpx;
  border-radius: 12rpx;
  background-color: var(--bg);
}

.post-actions {
  display: flex;
  align-items: center;
  gap: 32rpx;
  padding-top: 16rpx;
  border-top: 1rpx solid var(--card-border);
}

.action-btn {
  display: flex;
  align-items: center;
  gap: 8rpx;
  padding: 8rpx 16rpx;
  border-radius: 100rpx;
}

.action-btn.liked {
  color: #ff4757;
}

.action-btn.danger {
  color: #ff6b6b;
}

.action-icon {
  font-size: 32rpx;
}

.action-text {
  font-size: 24rpx;
  color: var(--text-muted);
}

.comments-section {
  background-color: var(--card);
  padding: 32rpx;
}

.section-title {
  font-size: 32rpx;
  font-weight: bold;
  color: var(--text);
  margin-bottom: 24rpx;
  display: block;
}

.comment-input {
  display: flex;
  gap: 16rpx;
  margin-bottom: 24rpx;
}

.comment-input-field {
  flex: 1;
  padding: 16rpx 24rpx;
  background-color: var(--bg);
  border: 1rpx solid var(--card-border);
  border-radius: 100rpx;
  font-size: 26rpx;
}

.btn-send {
  padding: 16rpx 32rpx;
  background: linear-gradient(135deg, var(--primary), var(--accent));
  color: #ffffff;
  border-radius: 100rpx;
  font-size: 26rpx;
  border: none;
}

.comment-item {
  display: flex;
  gap: 16rpx;
  padding: 16rpx 0;
  border-bottom: 1rpx solid var(--card-border);
}

.comment-item:last-child {
  border-bottom: none;
}

.comment-avatar {
  flex-shrink: 0;
}

.comment-avatar-img {
  width: 60rpx;
  height: 60rpx;
  border-radius: 50%;
}

.comment-body {
  flex: 1;
}

.comment-author {
  font-size: 26rpx;
  font-weight: 600;
  color: var(--text);
  margin-bottom: 8rpx;
  display: flex;
  align-items: center;
  gap: 8rpx;
}

.me-badge {
  font-size: 20rpx;
  color: var(--primary);
}

.comment-text {
  font-size: 26rpx;
  color: var(--text-soft);
  line-height: 1.5;
  margin-bottom: 8rpx;
  display: block;
}

.comment-time {
  font-size: 22rpx;
  color: var(--text-muted);
}

.comment-footer {
  display: flex;
  align-items: center;
  gap: 16rpx;
}

.comment-like-btn {
  font-size: 22rpx;
  color: var(--text-muted);
  padding: 4rpx 8rpx;
}

.comment-like-btn.liked {
  color: #ff4757;
}

.edited-tag {
  font-size: 22rpx;
  color: var(--primary);
  background: var(--primary-soft, rgba(99, 102, 241, 0.1));
  padding: 2rpx 12rpx;
  border-radius: 8rpx;
  margin-bottom: 8rpx;
  display: inline-block;
}

.action-btn.favourited {
  color: #f59e0b;
}

.delete-comment {
  font-size: 22rpx;
  color: #ff6b6b;
  margin-left: 16rpx;
}

.no-comments {
  text-align: center;
  padding: 80rpx 0;
  color: var(--text-muted);
  font-size: 28rpx;
}
</style>
