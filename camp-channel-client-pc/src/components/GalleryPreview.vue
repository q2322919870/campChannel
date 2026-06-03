﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿<template>
  <div v-if="visible" class="preview-overlay" @click.self="$emit('close')">
    <div class="preview-card">
      <button class="close-btn" @click="$emit('close')">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
      </button>

      <img v-if="!isVideo" :src="item.imageUrl" class="preview-img" />
      <video v-else :src="item.videoUrl || item.imageUrl" class="preview-video" controls autoplay />

      <div class="preview-info">
        <div class="preview-author">
          <img v-if="item.avatar" :src="item.avatar" class="author-avatar" />
          <span v-else class="author-avatar-text">{{ (item.username || '?').charAt(0) }}</span>
          <span>{{ item.username || '用户' }}</span>
        </div>
        <div v-if="item.title" class="preview-title">{{ item.title }}</div>
        <div v-if="item.description" class="preview-desc">{{ item.description }}</div>
      </div>

      <div class="interaction-row">
        <button class="action-btn" :class="{ liked: isLiked }" @click="toggleLike">
          <svg width="18" height="18" viewBox="0 0 24 24" :fill="isLiked ? 'currentColor' : 'none'" stroke="currentColor" stroke-width="2"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>
          {{ likeCount }}
        </button>
        <button class="action-btn" @click="showComment = !showComment">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
          {{ commentCount }}
        </button>
        <button class="action-btn" @click="showShare = !showShare">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><line x1="8.59" y1="13.51" x2="15.42" y2="17.49"/><line x1="15.41" y1="6.51" x2="8.59" y2="10.49"/></svg>
        </button>
        <button v-if="isOwner" class="action-btn danger" @click="handleDelete">删除</button>
        <button v-else class="action-btn report" @click="handleReport">举报</button>
      </div>

      <div v-if="showComment" class="comment-section">
        <div class="comment-input-row">
          <input v-model="newComment" placeholder="写评论..." @keyup.enter="addComment" />
          <button @click="addComment">发送</button>
        </div>
        <div v-for="c in comments" :key="c.id" class="comment-item">
          <span class="comment-user">{{ c.username || '用户' }}</span>
          <span class="comment-text">{{ c.content }}</span>
        </div>
        <div v-if="comments.length === 0" class="no-comments">暂无评论</div>
      </div>

      <div v-if="showShare" class="share-section">
        <input v-model="shareUserId" placeholder="输入目标用户ID分享" />
        <button @click="shareToUser">分享</button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { api } from '../api/client'
import { useAuthStore } from '@/stores/auth'

const props = defineProps<{ visible: boolean; item: any }>()
const emit = defineEmits<{ close: []; deleted: [] }>()
const authStore = useAuthStore()
const isOwner = computed(() => props.item?.userId === authStore.user?.id)
const isVideo = computed(() => props.item?.mediaType === 2 || (props.item?.videoUrl && !props.item?.imageUrl))

const isLiked = ref(false)
const likeCount = ref(props.item?.likeCount || 0)
const showComment = ref(false)
const newComment = ref('')
const comments = ref<any[]>([])
const commentCount = ref(props.item?.commentCount || 0)
const showShare = ref(false)
const shareUserId = ref('')

watch(() => props.visible, async (v) => {
  if (v && props.item?.id) {
    await fetchLikeStatus()
    await fetchComments()
  }
})

async function fetchLikeStatus() {
  try {
    const res = await api.get(`/gallery/${props.item.id}/like/status`)
    if (res.data.code === 200) {
      isLiked.value = res.data.data.hasLiked || false
      likeCount.value = res.data.data.likeCount || 0
    }
  } catch {}
}

async function fetchComments() {
  try {
    const res = await api.get(`/gallery/${props.item.id}/comments`)
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      comments.value = res.data.data
      commentCount.value = res.data.data.length
    }
  } catch {}
}

async function toggleLike() {
  try {
    const res = await api.post(`/gallery/${props.item.id}/like`)
    if (res.data.code === 200 && res.data.data) {
      isLiked.value = res.data.data.liked
      likeCount.value = res.data.data.likeCount
    }
  } catch {}
}

async function addComment() {
  if (!newComment.value.trim()) return
  try {
    const res = await api.post(`/gallery/${props.item.id}/comment`, { content: newComment.value.trim() })
    if (res.data.code === 200 && res.data.data) {
      comments.value.unshift(res.data.data)
      commentCount.value++
      newComment.value = ''
    }
  } catch {}
}

async function shareToUser() {
  if (!shareUserId.value.trim()) { alert('请输入用户ID'); return }
  try {
    await api.post(`/gallery/${props.item.id}/share`, { targetUserId: Number(shareUserId.value) })
    alert('已分享')
    shareUserId.value = ''
  } catch (e: any) { alert(e.response?.data?.message || '分享失败') }
}

async function handleDelete() {
  if (!confirm('确认删除这幅画？')) return
  try {
    const res = await api.delete(`/gallery/${props.item.id}`)
    if (res.data.code === 200) emit('deleted')
  } catch (e: any) { alert(e.response?.data?.message || '删除失败') }
}

async function handleReport() {
  try {
    await api.post('/reports', { targetType: 'gallery', targetId: props.item.id, reason: '违规画作举报' })
    alert('举报已提交')
    emit('close')
  } catch (e: any) { alert(e.response?.data?.message || '举报失败') }
}
</script>

<style scoped>
.preview-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.7); display: flex; align-items: center; justify-content: center; z-index: 3000; animation: fadeIn 0.2s; }
@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
.preview-card { position: relative; max-width: 520px; width: 90%; max-height: 90vh; overflow-y: auto; background: var(--surface); border: 1px solid var(--outline-variant); border-radius: var(--card-radius); padding: 24px; animation: scaleIn 0.25s cubic-bezier(0.34,1.56,0.64,1); }
@keyframes scaleIn { from { transform: scale(0.5); opacity: 0; } to { transform: scale(1); opacity: 1; } }
.close-btn { position: absolute; top: 12px; right: 12px; background: rgba(0,0,0,0.4); border: none; border-radius: 50%; width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; cursor: pointer; color: #fff; z-index: 1; }
.preview-img, .preview-video { width: 100%; max-height: 50vh; object-fit: contain; border-radius: var(--card-radius); margin-bottom: 16px; }
.preview-info { margin-bottom: 12px; }
.preview-author { display: flex; align-items: center; gap: 8px; font-size: 14px; font-weight: 600; margin-bottom: 6px; }
.author-avatar { width: 28px; height: 28px; border-radius: 8px; object-fit: cover; }
.author-avatar-text { width: 28px; height: 28px; border-radius: 8px; background: linear-gradient(135deg, var(--primary), var(--secondary)); display: flex; align-items: center; justify-content: center; font-size: 12px; color: #fff; }
.preview-title { font-size: 16px; font-weight: 700; margin-bottom: 4px; }
.preview-desc { font-size: 13px; color: var(--on-surface-variant); }
.interaction-row { display: flex; gap: 12px; margin-bottom: 12px; flex-wrap: wrap; }
.action-btn { display: flex; align-items: center; gap: 4px; padding: 8px 16px; border-radius: 10px; border: none; background: rgba(255,255,255,0.05); color: var(--on-surface-variant); font-size: 13px; cursor: pointer; transition: all 0.2s; }
.action-btn:hover { background: rgba(255,255,255,0.1); }
.action-btn.liked { color: var(--secondary); }
.action-btn.danger { background: rgba(255,107,107,0.12); color: #ff6b6b; }
.action-btn.danger:hover { background: rgba(255,107,107,0.2); }
.action-btn.report { background: rgba(255,165,0,0.12); color: #ffa500; }
.action-btn.report:hover { background: rgba(255,165,0,0.2); }
.comment-section, .share-section { border-top: 1px solid var(--outline-variant); padding-top: 12px; margin-top: 8px; }
.comment-input-row, .share-section { display: flex; gap: 8px; margin-bottom: 8px; }
.comment-input-row input, .share-section input { flex: 1; padding: 8px 12px; border: 1px solid var(--outline-variant); border-radius: 8px; background: rgba(255,255,255,0.03); color: var(--on-surface); font-size: 13px; outline: none; }
.comment-input-row input:focus, .share-section input:focus { border-color: var(--primary); }
.comment-input-row button, .share-section button { padding: 8px 16px; border: none; border-radius: 8px; background: linear-gradient(135deg, var(--primary), var(--secondary)); color: #fff; font-size: 13px; cursor: pointer; }
.comment-item { display: flex; gap: 6px; padding: 4px 0; font-size: 13px; }
.comment-user { font-weight: 600; color: var(--primary); white-space: nowrap; }
.comment-text { color: var(--on-surface); }
.no-comments { text-align: center; color: var(--on-surface-variant); font-size: 12px; padding: 8px; }
</style>