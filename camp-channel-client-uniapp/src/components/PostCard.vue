<template>
  <view class="post-card" @tap="handleClick">
    <view v-if="post.isPinned" class="pin-badge">
      <text>📌 置顶</text>
    </view>
    <view class="post-header">
      <view class="post-avatar" @tap.stop="onAvatarClick">
        <image 
          v-if="post.avatar && !avatarBroken" 
          :src="post.avatar" 
          mode="aspectFill" 
          class="avatar-img"
          @error="handleImageError"
        />
        <view v-else class="avatar-placeholder">
          <text>{{ post.author ? post.author.charAt(0) : '?' }}</text>
        </view>
      </view>
      <view class="post-meta">
        <text class="post-author">{{ post.author || '未知用户' }}</text>
        <text v-if="post.userChannelRole" class="role-badge" :class="'role-' + post.userChannelRole">{{ roleLabel }}</text>
        <text class="post-time">{{ post.time || '' }}</text>
      </view>
      <text class="post-channel">{{ post.channelName || '' }}</text>
    </view>
    
    <text class="post-title">{{ post.title }}</text>
    <text class="post-content">{{ post.content }}</text>
    
    <view v-if="post.images && post.images.length" class="post-images">
      <image 
        v-for="(img, i) in post.images.slice(0, 3)" 
        :key="i" 
        :src="img" 
        mode="aspectFill"
        class="post-image"
        @tap.stop
      />
    </view>
    
    <view class="post-actions">
      <view class="action-btn" :class="{ liked: post.isLiked }" @tap.stop="onLike">
        <text class="action-icon">{{ post.isLiked ? '❤' : '♡' }}</text>
        <text class="action-text">{{ post.likeCount || 0 }}</text>
      </view>
      <view class="action-btn" @tap.stop="onComment">
        <text class="action-icon">💬</text>
        <text class="action-text">{{ post.commentCount || 0 }}</text>
      </view>
      <view class="action-btn" @tap.stop="onShare">
        <text class="action-icon">↗</text>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'

const avatarBroken = ref(false)

interface Post {
  id: number
  author?: string
  avatar?: string
  userId?: number
  time?: string
  channelName?: string
  userChannelRole?: string
  title: string
  content: string
  images?: string[]
  likeCount?: number
  commentCount?: number
  isLiked?: boolean
  isPinned?: boolean
}

const props = defineProps<{
  post: Post
}>()

const emit = defineEmits<{
  click: [postId: number]
  avatarClick: [userId: number]
  like: [post: Post, event: any]
  comment: [postId: number]
  share: [post: Post]
}>()

const roleLabel = computed(() => {
  const roles: Record<string, string> = {
    owner: '创建者',
    admin: '管理员',
    member: '成员'
  }
  return roles[props.post.userChannelRole || ''] || ''
})

function handleClick() {
  emit('click', props.post.id)
}

function onAvatarClick() {
  if (props.post.userId) {
    emit('avatarClick', props.post.userId)
  }
}

function onLike(event: any) {
  emit('like', props.post, event)
}

function onComment() {
  emit('comment', props.post.id)
}

function onShare() {
  emit('share', props.post)
}

function handleImageError() {
  avatarBroken.value = true
}
</script>

<style scoped>
.post-card {
  background: var(--card);
  border-radius: var(--radius);
  padding: 28rpx;
  margin-bottom: 20rpx;
  box-shadow: var(--shadow-sm);
  position: relative;
}

.pin-badge {
  position: absolute;
  top: 16rpx;
  right: 16rpx;
  font-size: 22rpx;
  color: var(--warning);
  background: rgba(245, 158, 11, 0.1);
  padding: 4rpx 16rpx;
  border-radius: 100rpx;
  font-weight: 600;
}

.post-header {
  display: flex;
  align-items: center;
  margin-bottom: 20rpx;
}

.post-avatar {
  width: 76rpx;
  height: 76rpx;
  border-radius: 50%;
  overflow: hidden;
  margin-right: 16rpx;
  flex-shrink: 0;
  background: var(--primary-gradient);
  display: flex;
  align-items: center;
  justify-content: center;
}

.avatar-img {
  width: 100%;
  height: 100%;
}

.avatar-placeholder {
  color: #ffffff;
  font-size: 32rpx;
  font-weight: 700;
}

.post-meta {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4rpx;
}

.post-author {
  font-size: 28rpx;
  font-weight: 700;
  color: var(--text);
}

.role-badge {
  font-size: 20rpx;
  padding: 2rpx 12rpx;
  border-radius: 8rpx;
  display: inline-block;
  width: fit-content;
}

.role-owner {
  background: rgba(245, 158, 11, 0.12);
  color: var(--warning);
}

.role-admin {
  background: var(--accent-soft);
  color: var(--accent);
}

.role-member {
  background: var(--primary-soft);
  color: var(--primary);
}

.post-time {
  font-size: 22rpx;
  color: var(--text-muted);
}

.post-channel {
  font-size: 22rpx;
  color: var(--primary);
  padding: 6rpx 16rpx;
  background: var(--primary-soft);
  border-radius: 100rpx;
  flex-shrink: 0;
  font-weight: 500;
}

.post-title {
  font-size: 30rpx;
  font-weight: 700;
  color: var(--text);
  margin-bottom: 12rpx;
  line-height: 1.5;
  display: block;
}

.post-content {
  font-size: 26rpx;
  color: var(--text-secondary);
  line-height: 1.7;
  margin-bottom: 16rpx;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
  text-overflow: ellipsis;
}

.post-images {
  display: flex;
  gap: 8rpx;
  margin-bottom: 16rpx;
}

.post-image {
  flex: 1;
  height: 200rpx;
  border-radius: 16rpx;
  background: var(--bg);
}

.post-actions {
  display: flex;
  align-items: center;
  gap: 8rpx;
  padding-top: 16rpx;
  border-top: 1rpx solid var(--card-border);
}

.action-btn {
  display: flex;
  align-items: center;
  gap: 6rpx;
  padding: 10rpx 20rpx;
  border-radius: 100rpx;
  transition: all 0.2s ease;
  background: transparent;
}

.action-btn:active {
  background: var(--bg);
}

.action-btn.liked {
  color: var(--accent);
}

.action-btn.liked .action-text {
  color: var(--accent);
}

.action-icon {
  font-size: 32rpx;
}

.action-text {
  font-size: 24rpx;
  color: var(--text-muted);
}
</style>
