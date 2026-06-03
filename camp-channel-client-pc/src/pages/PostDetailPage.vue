﻿﻿﻿<template>
  <div class="post-detail">
    <div class="post-main">
      <div class="post-card">
        <div class="post-author-row">
          <div class="post-avatar" @click.stop="cardUserId = post.userId || 1; showCard = true">
            <img v-if="post.avatar" :src="post.avatar" class="post-avatar-img" />
            <span v-else>{{ (post.author || '?').charAt(0) }}</span>
          </div>
          <div>
            <div class="author-name">{{ post.author || '未知用户' }}
              <span v-if="post.userChannelRole" class="role-badge" :class="'role-' + post.userChannelRole">{{ roleLabel(post.userChannelRole) }}</span>
            </div>
            <div class="post-time">{{ post.time || '' }}</div>
          </div>
        </div>
        <h1 class="post-title">{{ post.title }}</h1>
        <p class="post-content">{{ post.content }}</p>
        <div v-if="post.isPinned" class="pin-indicator">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M16 12V4h1V2H7v2h1v8l-2 2v2h5.2v6h1.6v-6H18v-2l-2-2z"/></svg>
          此帖已被置顶
        </div>
        <div class="post-actions">
          <button class="action-btn" :class="{ liked: isLiked }" @click="toggleLike">
            <svg width="18" height="18" viewBox="0 0 24 24" :fill="isLiked ? 'currentColor' : 'none'" stroke="currentColor" stroke-width="2"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>
            {{ likeCount }}
          </button>
          <button class="action-btn" :class="{ liked: isFavourited }" @click="toggleFavourite">
            <svg width="18" height="18" viewBox="0 0 24 24" :fill="isFavourited ? 'currentColor' : 'none'" stroke="currentColor" stroke-width="2"><path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"/></svg>
            {{ favouriteCount }}
          </button>
          <button v-if="canPinPost" class="action-btn" :class="{ pinned: post.isPinned }" @click="togglePin">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M16 12V4h1V2H7v2h1v8l-2 2v2h5.2v6h1.6v-6H18v-2l-2-2z"/></svg>
            {{ post.isPinned ? '取消置顶' : '置顶' }}
          </button>
          <button v-if="currentUserId === post.userId" class="action-btn danger" @click="deletePost">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
          </button>
          <button class="action-btn" @click="sharePost">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><line x1="8.59" y1="13.51" x2="15.42" y2="17.49"/><line x1="15.41" y1="6.51" x2="8.59" y2="10.49"/></svg>
          </button>
          <button class="action-btn" @click="showReport = true">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z"/><line x1="4" y1="22" x2="4" y2="15"/></svg>
          </button>
        </div>
      </div>

      <div class="comments-section">
        <h3>评论 ({{ comments.length }})</h3>
        <div class="comment-input">
          <input v-model="newComment" placeholder="写下你的评论...（使用 @用户名 可以提及他人）" @keyup.enter="addComment" />
          <button @click="addComment">发送</button>
        </div>
        <div v-for="c in comments" :key="c.id" class="comment-item">
          <div class="comment-avatar">
            <img v-if="c.avatar" :src="c.avatar" class="comment-avatar-img" />
            <span v-else>{{ (c.username || '?').charAt(0) }}</span>
          </div>
          <div class="comment-body">
            <div class="comment-author">
              {{ c.username || '匿名' }}
              <span v-if="c.userId === currentUserId" class="me-badge">(我)</span>
            </div>
            <p class="comment-text">{{ c.content }}</p>
            <span class="comment-time">{{ c.time || '' }}</span>
            <button v-if="currentUserId === c.userId" class="delete-comment" @click="deleteComment(c.id)">删除</button>
          </div>
        </div>
        <div v-if="comments.length === 0" class="no-comments">暂无评论，快来抢沙发</div>
      </div>
    </div>
    <ReportDialog :visible="showReport" target-type="post" :target-id="Number(route.params.id)" @close="showReport = false" @submitted="onReportSubmitted" />
    <UserCard :visible="showCard" :user-id="cardUserId" @close="showCard = false" />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { api } from '../api/client'
import { useAuthStore } from '../stores/auth'
import ReportDialog from '../components/ReportDialog.vue'
import UserCard from '../components/UserCard.vue'

const route = useRoute()
const authStore = useAuthStore()
const currentUserId = computed(() => authStore.user?.id || 0)
const canPinPost = computed(() => {
  const role = post.value.userChannelRole
  return role === 'owner' || role === 'admin'
})
const post = ref<any>({})
const cardUserId = ref(0)
const showCard = ref(false)
const isLiked = ref(false)
const likeCount = ref(0)
const isFavourited = ref(false)
const favouriteCount = ref(0)
const comments = ref<any[]>([])
const newComment = ref('')
const showReport = ref(false)

async function fetchPost() {
  let postData: any = {}
  try {
    const postId = route.params.id
    const res = await api.get(`/posts/${postId}`)
    if (res.data.code === 200) {
      postData = res.data.data
      post.value = {
        ...postData,
        userId: postData.userId || 0,
        avatar: postData.avatar || '',
        username: postData.username || '',
        author: postData.username || '用户',
        title: postData.topic || '帖子',
        content: postData.content || '',
        time: postData.createTime || '',
        images: postData.images ? (typeof postData.images === 'string' ? JSON.parse(postData.images) : postData.images).map((url: string) => 
          url.startsWith('http') || url.startsWith('/') ? url : '/uploads/images/' + url
        ) : [],
      }
    }
  } catch (e) {}
  try {
    const postId = route.params.id
    const likeRes = await api.get(`/posts/${postId}/like/status`)
    if (likeRes.data.code === 200) {
      isLiked.value = likeRes.data.data.hasLiked || false
      likeCount.value = likeRes.data.data.likeCount || 0
    } else {
      isLiked.value = false
      likeCount.value = postData.likeCount || 0
    }
  } catch {
    isLiked.value = false
    likeCount.value = postData.likeCount || 0
  }
  // Load favourite status
  try {
    const postId = route.params.id
    const favRes = await api.get(`/posts/${postId}/favourite/status`)
    if (favRes.data.code === 200) {
      isFavourited.value = favRes.data.data.isFavourited || false
      favouriteCount.value = favRes.data.data.count || 0
    }
  } catch {
    isFavourited.value = false
    favouriteCount.value = postData.favouriteCount || 0
  }
}

async function fetchComments() {
  try {
    const postId = route.params.id
    const res = await api.get(`/posts/${postId}/comments`, { params: { page: 1, size: 50 } })
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      comments.value = res.data.data.map((c: any) => ({
        id: c.id,
        content: c.content,
        username: c.username || '匿名',
        avatar: c.avatar || '',
        userId: c.userId || 0,
        time: c.createTime || '',
      }))
    }
  } catch (e) {}
}

function roleLabel(role: string) {
  const labels: Record<string, string> = { owner: '频道主', admin: '管理员', member: '成员' }
  return labels[role] || '成员'
}

async function toggleLike() {
  try {
    const res = await api.post(`/posts/${route.params.id}/like`)
    if (res.data.code === 200 && res.data.data) {
      isLiked.value = res.data.data.liked
      likeCount.value = res.data.data.likeCount
    }
  } catch (e) {}
}

async function toggleFavourite() {
  try {
    const res = await api.post(`/posts/${route.params.id}/favourite`)
    if (res.data.code === 200 && res.data.data) {
      isFavourited.value = res.data.data.isFavourited
      favouriteCount.value = isFavourited.value ? favouriteCount.value + 1 : Math.max(0, favouriteCount.value - 1)
    }
  } catch (e) {}
}

async function togglePin() {
  try {
    const res = await api.post(`/posts/${route.params.id}/pin`)
    if (res.data.code === 200 && res.data.data) {
      post.value.isPinned = res.data.data.isPinned
      window.alert(res.data.data.message)
    }
  } catch (e: any) {
    window.alert(e.response?.data?.message || '操作失败')
  }
}

async function addComment() {
  if (!newComment.value.trim()) return
  try {
    const res = await api.post(`/posts/${route.params.id}/comments`, {
      content: newComment.value,
      parentId: null,
    })
    if (res.data.code === 200) {
      const c = res.data.data
      comments.value.unshift({
        id: c.id || Date.now(),
        content: c.content || newComment.value,
        username: c.username || authStore.user?.username || '我',
        avatar: c.avatar || '',
        userId: c.userId || currentUserId.value,
        time: '刚刚',
      })
      newComment.value = ''
    }
  } catch (e: any) {
    window.alert('评论失败：' + (e.response?.data?.message || e.message))
  }
}

function sharePost() {
  const url = window.location.origin + '/#/post/' + route.params.id
  if (navigator.share) {
    navigator.share({ title: 'Camp Channel 帖子', url }).catch(() => {})
  } else {
    navigator.clipboard.writeText(url).then(() => alert('链接已复制')).catch(() => {})
  }
}

function onReportSubmitted() {
  window.alert('举报已提交')
}

async function deletePost() {
  if (!window.confirm('确定删除此帖子？')) return
  try {
    await api.delete(`/posts/${route.params.id}`)
    window.alert('帖子已删除')
    window.history.back()
  } catch (e: any) {
    window.alert(e.response?.data?.message || '删除失败')
  }
}

async function deleteComment(commentId: number) {
  try {
    await api.delete(`/posts/${route.params.id}/comments/${commentId}`)
    comments.value = comments.value.filter(c => c.id !== commentId)
  } catch (e) {}
}

onMounted(() => {
  fetchPost()
  fetchComments()
})
</script>

<style scoped>
.post-detail { max-width: 720px; margin: 0 auto; }
.post-main { display: flex; flex-direction: column; gap: 20px; }
.post-card { padding: 28px; background: var(--surface); border: 1px solid var(--outline-variant); border-radius: var(--card-radius); }
.post-author-row { display: flex; gap: 12px; margin-bottom: 20px; }
.post-avatar { width: 44px; height: 44px; border-radius: var(--radius); background: linear-gradient(135deg, var(--primary), var(--secondary)); display: flex; align-items: center; justify-content: center; font-size: 18px; font-weight: 700; color: #fff; overflow: hidden; }
.post-avatar img { width: 100%; height: 100%; border-radius: 10px; object-fit: cover; }
.author-name { font-size: 15px; font-weight: 600; }
.post-time { font-size: 12px; color: var(--on-surface-variant); }
.role-badge { font-size: 10px; padding: 1px 6px; border-radius: 4px; margin-left: 6px; font-weight: 500; vertical-align: middle; }
.role-badge.role-owner { background: rgba(240, 173, 78, 0.2); color: #f0ad4e; }
.role-badge.role-admin { background: rgba(74, 222, 128, 0.2); color: #4ade80; }
.role-badge.role-member { background: rgba(255, 255, 255, 0.08); color: rgba(255, 255, 255, 0.5); }
.post-title { font-size: 24px; font-weight: 700; margin-bottom: 16px; }
.post-content { font-size: 15px; line-height: 1.8; color: var(--on-surface-variant); margin-bottom: 20px; }
.pin-indicator { display: flex; align-items: center; gap: 6px; padding: 8px 12px; background: rgba(240, 173, 78, 0.1); border: 1px solid rgba(240, 173, 78, 0.3); border-radius: 10px; color: #f0ad4e; font-size: 13px; font-weight: 500; margin-bottom: 16px; }
.post-actions { display: flex; gap: 8px; border-top: 1px solid var(--outline-variant); padding-top: 16px; }
.action-btn { display: flex; align-items: center; gap: 6px; padding: 8px 16px; background: none; border: none; color: var(--on-surface-variant); font-size: 14px; cursor: pointer; border-radius: 10px; transition: all 0.2s; }
.action-btn:hover { background: var(--surface); color: var(--primary); }
.action-btn.liked { color: var(--secondary); }
.action-btn.pinned { color: #f0ad4e; background: rgba(240, 173, 78, 0.1); }
.action-btn.danger { color: #ff6b6b; }
.delete-comment { background: none; border: none; color: #ff6b6b; font-size: 11px; cursor: pointer; margin-left: 8px; }
.comments-section { padding: 24px; background: var(--surface); border: 1px solid var(--outline-variant); border-radius: 20px; }
.comments-section h3 { font-size: 16px; font-weight: 600; margin-bottom: 16px; }
.comment-input { display: flex; gap: 8px; margin-bottom: 20px; }
.comment-input input { flex: 1; padding: 12px 16px; border: 1px solid var(--outline-variant); border-radius: 12px; background: rgba(255,255,255,0.03); color: var(--on-surface); font-size: 14px; outline: none; }
.comment-input input:focus { border-color: var(--primary); }
.comment-input button { padding: 12px 20px; border: none; border-radius: 12px; background: linear-gradient(135deg, var(--primary), var(--secondary)); color: #fff; font-weight: 600; cursor: pointer; }
.comment-item { display: flex; gap: 12px; padding: 12px 0; border-bottom: 1px solid var(--outline-variant); }
.comment-item:last-child { border-bottom: none; }
.comment-avatar { width: 32px; height: 32px; border-radius: 8px; background: linear-gradient(135deg, var(--secondary), var(--primary)); display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: 700; color: #fff; flex-shrink: 0; overflow: hidden; }
.comment-avatar-img { width: 100%; height: 100%; border-radius: 8px; object-fit: cover; }
.comment-body { flex: 1; }
.comment-author { font-size: 13px; font-weight: 600; margin-bottom: 4px; }
.me-badge { font-size: 10px; color: #fff; background: #e74c3c; padding: 1px 6px; border-radius: 4px; margin-left: 4px; font-weight: 700; vertical-align: middle; }
.comment-text { font-size: 14px; color: var(--on-surface-variant); margin-bottom: 4px; }
.comment-time { font-size: 11px; color: var(--on-surface-variant); }
.no-comments { text-align: center; padding: 32px; color: var(--on-surface-variant); font-size: 14px; }
</style>
