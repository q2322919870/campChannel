<template>
  <view class="post-card" @tap="handleClick">
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
  background: rgba(124, 159, 203, 0.08);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1rpx solid rgba(124, 159, 203, 0.15);
  border-radius: 24rpx;
  padding: 24rpx;
  margin-bottom: 16rpx;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  overflow: hidden;
}

.post-card::before {
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
  border-radius: 24rpx;
}

.post-header {
  display: flex;
  align-items: center;
  margin-bottom: 16rpx;
  position: relative;
  z-index: 1;
}

.post-avatar {
  width: 72rpx;
  height: 72rpx;
  border-radius: 14rpx;
  overflow: hidden;
  margin-right: 16rpx;
  flex-shrink: 0;
  background: linear-gradient(135deg, #7C9FCB, #F2B5D4);
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  z-index: 1;
}

.avatar-img {
  width: 100%;
  height: 100%;
}

.avatar-placeholder {
  color: #ffffff;
  font-size: 32rpx;
  font-weight: bold;
}

.post-meta {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4rpx;
  position: relative;
  z-index: 1;
}

.post-author {
  font-size: 28rpx;
  font-weight: 600;
  color: #E8EFF7;
}

.role-badge {
  font-size: 20rpx;
  padding: 2rpx 12rpx;
  border-radius: 8rpx;
  display: inline-block;
  width: fit-content;
  position: relative;
  z-index: 1;
}

.role-owner {
  background: rgba(240, 173, 78, 0.2);
  color: #f0ad4e;
}

.role-admin {
  background: rgba(242, 181, 212, 0.2);
  color: #F2B5D4;
}

.role-member {
  background: rgba(255, 255, 255, 0.08);
  color: rgba(232, 239, 247, 0.6);
}

.post-time {
  font-size: 22rpx;
  color: rgba(232, 239, 247, 0.6);
}

.post-channel {
  font-size: 22rpx;
  color: #7C9FCB;
  padding: 4rpx 16rpx;
  background: rgba(124, 159, 203, 0.15);
  border-radius: 100rpx;
  flex-shrink: 0;
  position: relative;
  z-index: 1;
}

.post-title {
  font-size: 32rpx;
  font-weight: bold;
  color: #E8EFF7;
  margin-bottom: 12rpx;
  line-height: 1.4;
  display: block;
  position: relative;
  z-index: 1;
}

.post-content {
  font-size: 26rpx;
  color: rgba(232, 239, 247, 0.6);
  line-height: 1.6;
  margin-bottom: 16rpx;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
  text-overflow: ellipsis;
  position: relative;
  z-index: 1;
}

.post-images {
  display: flex;
  gap: 8rpx;
  margin-bottom: 16rpx;
  position: relative;
  z-index: 1;
}

.post-image {
  flex: 1;
  height: 200rpx;
  border-radius: 12rpx;
  background: rgba(15, 25, 35, 0.5);
}

.post-actions {
  display: flex;
  align-items: center;
  gap: 32rpx;
  padding-top: 16rpx;
  border-top: 1rpx solid rgba(124, 159, 203, 0.15);
  position: relative;
  z-index: 1;
}

.action-btn {
  display: flex;
  align-items: center;
  gap: 8rpx;
  padding: 8rpx 16rpx;
  border-radius: 100rpx;
  transition: all 0.2s ease;
  position: relative;
  z-index: 1;
}

.action-btn.liked {
  color: #F2B5D4;
}

.action-icon {
  font-size: 32rpx;
}

.action-text {
  font-size: 24rpx;
  color: rgba(232, 239, 247, 0.6);
}
</style>
