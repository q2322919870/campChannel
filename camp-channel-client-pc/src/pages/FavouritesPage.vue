<template>
  <div class="favourites-page">
    <h2>我的收藏</h2>
    
    <div v-if="loading && posts.length === 0" class="loading">
      <div class="spinner"></div>
    </div>

    <div v-else-if="posts.length === 0" class="empty">
      <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
        <path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"/>
      </svg>
      <p>暂无收藏</p>
      <span>浏览帖子并点击收藏按钮</span>
    </div>

    <div v-else class="posts-list">
      <div v-for="post in posts" :key="post.id" class="post-card" @click="goToPost(post)">
        <div class="post-header">
          <div class="avatar">
            <img v-if="post.avatar" :src="post.avatar" />
            <span v-else>{{ (post.username || '?').charAt(0) }}</span>
          </div>
          <div class="post-info">
            <div class="username">{{ post.username || '匿名' }}</div>
            <div class="time">{{ formatTime(post.createTime) }} · {{ post.channelName || '' }}</div>
          </div>
          <button class="remove-btn" @click.stop="removeFavourite(post.id)" title="取消收藏">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" stroke-width="2">
              <path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"/>
            </svg>
          </button>
        </div>
        <div class="post-content">{{ post.content }}</div>
        <div class="post-stats">
          <span><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg> {{ post.likeCount || 0 }}</span>
          <span><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg> {{ post.commentCount || 0 }}</span>
        </div>
      </div>
    </div>

    <div v-if="loading && posts.length > 0" class="loading-more">加载中...</div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '../api/client'

const router = useRouter()
const posts = ref<any[]>([])
const loading = ref(false)
const page = ref(1)
const hasMore = ref(true)

async function loadFavourites(refresh = false) {
  if (refresh) {
    page.value = 1
    hasMore.value = true
  }

  if (!hasMore.value && !refresh) return

  loading.value = true

  try {
    const res = await api.get('/posts/favourites', {
      params: { page: page.value, size: 20 }
    })
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      const newPosts = res.data.data
      if (refresh) {
        posts.value = newPosts
      } else {
        posts.value.push(...newPosts)
      }
      hasMore.value = newPosts.length >= 20
      if (newPosts.length > 0) {
        page.value++
      }
    }
  } catch (e) {
    console.error('Failed to load favourites:', e)
  } finally {
    loading.value = false
  }
}

async function removeFavourite(postId: number) {
  try {
    const res = await api.post(`/posts/${postId}/favourite`)
    if (res.data.code === 200) {
      posts.value = posts.value.filter(p => p.id !== postId)
    }
  } catch (e) {
    console.error('Failed to remove favourite:', e)
  }
}

function goToPost(post: any) {
  router.push(`/post/${post.id}`)
}

function formatTime(timeStr: string): string {
  if (!timeStr) return ''
  try {
    const date = new Date(timeStr)
    const now = new Date()
    const diff = now.getTime() - date.getTime()
    const minutes = Math.floor(diff / 60000)
    const hours = Math.floor(diff / 3600000)
    const days = Math.floor(diff / 86400000)

    if (minutes < 1) return '刚刚'
    if (minutes < 60) return `${minutes}分钟前`
    if (hours < 24) return `${hours}小时前`
    if (days < 7) return `${days}天前`
    return `${date.getMonth() + 1}月${date.getDate()}日`
  } catch {
    return timeStr
  }
}

onMounted(() => {
  loadFavourites()
})
</script>

<style scoped>
.favourites-page {
  max-width: 720px;
  margin: 0 auto;
  padding: 20px;
}

h2 {
  font-size: 24px;
  font-weight: 700;
  margin-bottom: 20px;
}

.loading {
  display: flex;
  justify-content: center;
  padding: 60px 0;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 3px solid var(--outline-variant);
  border-top-color: var(--primary);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 80px 0;
  color: var(--on-surface-variant);
}

.empty svg {
  opacity: 0.3;
  margin-bottom: 16px;
}

.empty p {
  font-size: 18px;
  font-weight: 600;
  margin-bottom: 8px;
}

.empty span {
  font-size: 14px;
}

.posts-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.post-card {
  padding: 20px;
  background: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: 16px;
  cursor: pointer;
  transition: all 0.2s;
}

.post-card:hover {
  border-color: var(--primary);
  transform: translateY(-2px);
}

.post-header {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 12px;
}

.avatar {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  background: linear-gradient(135deg, var(--primary), var(--secondary));
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
  font-weight: 700;
  color: #fff;
  overflow: hidden;
  flex-shrink: 0;
}

.avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.post-info {
  flex: 1;
}

.username {
  font-size: 14px;
  font-weight: 600;
}

.time {
  font-size: 12px;
  color: var(--on-surface-variant);
}

.remove-btn {
  padding: 8px;
  background: none;
  border: none;
  color: var(--primary);
  cursor: pointer;
  border-radius: 8px;
  transition: all 0.2s;
}

.remove-btn:hover {
  background: var(--primary);
  color: #fff;
}

.post-content {
  font-size: 14px;
  line-height: 1.6;
  color: var(--on-surface-variant);
  margin-bottom: 12px;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.post-stats {
  display: flex;
  gap: 16px;
  font-size: 13px;
  color: var(--on-surface-variant);
}

.post-stats span {
  display: flex;
  align-items: center;
  gap: 4px;
}

.loading-more {
  text-align: center;
  padding: 20px 0;
  color: var(--on-surface-variant);
  font-size: 14px;
}
</style>
