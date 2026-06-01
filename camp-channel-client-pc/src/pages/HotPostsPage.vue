<template>
  <div class="hot-posts-page">
    <div class="page-header">
      <h1>
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M12 2c.5 2.5 2 4.5 2 7a4 4 0 1 1-8 0c0-2.5 1.5-4.5 2-7"></path>
          <path d="M12 2c.5 2.5 2 4.5 2 7a4 4 0 1 1-8 0c0-2.5 1.5-4.5 2-7" transform="translate(4, 0)"></path>
        </svg>
        热门帖子
      </h1>
      <p class="subtitle">最近 7 天的热门内容</p>
    </div>

    <div class="posts-container">
      <div v-if="isLoading" class="loading">
        <div class="spinner"></div>
        <p>加载中...</p>
      </div>

      <div v-else-if="hotPosts.length === 0" class="empty">
        <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
          <path d="M12 2c.5 2.5 2 4.5 2 7a4 4 0 1 1-8 0c0-2.5 1.5-4.5 2-7"></path>
        </svg>
        <p>暂无热门帖子</p>
      </div>

      <div v-else class="posts-grid">
        <div 
          v-for="(post, index) in hotPosts" 
          :key="post.id" 
          class="post-card"
          :class="{ 'top-3': index < 3 }"
          @click="goToPost(post)"
        >
          <div v-if="index < 3" class="rank-badge" :class="`rank-${index + 1}`">
            {{ index + 1 }}
          </div>
          <div v-if="post.isPinned" class="pin-badge">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor">
              <path d="M16 12V4h1V2H7v2h1v8l-2 2v2h5.2v6h1.6v-6H18v-2l-2-2z"/>
            </svg>
            置顶
          </div>
          <div class="post-header">
            <div class="avatar">
              <img v-if="post.avatar" :src="post.avatar" />
              <span v-else>{{ (post.username || '?').charAt(0) }}</span>
            </div>
            <div class="meta">
              <div class="username">{{ post.username }}</div>
              <div class="time">{{ formatTime(post.createTime) }}</div>
            </div>
          </div>
          <div class="post-content">
            <div v-if="post.topic" class="topic">{{ post.topic }}</div>
            <p>{{ truncateContent(post.content, 150) }}</p>
          </div>
          <div class="post-stats">
            <span class="stat">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/>
              </svg>
              {{ post.likeCount || 0 }}
            </span>
            <span class="stat">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
              </svg>
              {{ post.commentCount || 0 }}
            </span>
            <span class="stat">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 4.5C7 4.5 2.73 7.61 1 12c1.73 4.39 6 7.5 11 7.5s9.27-3.11 11-7.5c-1.73-4.39-6-7.5-11-7.5zM12 17c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5zm0-8c-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3-1.34-3-3-3z"/>
              </svg>
              {{ post.viewCount || 0 }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '../api/client'

const router = useRouter()
const hotPosts = ref<any[]>([])
const isLoading = ref(true)

async function fetchHotPosts() {
  try {
    const res = await api.get('/posts/hot', {
      params: { limit: 20 }
    })
    
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      hotPosts.value = res.data.data
    }
  } catch (e) {
    console.error('Failed to fetch hot posts:', e)
  } finally {
    isLoading.value = false
  }
}

function truncateContent(content: string, maxLength: number): string {
  if (!content) return ''
  if (content.length <= maxLength) return content
  return content.substring(0, maxLength) + '...'
}

function goToPost(post: any) {
  router.push({
    name: 'PostDetail',
    params: { id: post.id }
  })
}

function formatTime(timeStr: string): string {
  if (!timeStr) return ''
  try {
    const date = new Date(timeStr)
    const now = new Date()
    const diff = now.getTime() - date.getTime()
    const hours = Math.floor(diff / 3600000)
    const days = Math.floor(diff / 86400000)
    
    if (hours < 1) return '刚刚'
    if (hours < 24) return `${hours}小时前`
    if (days < 7) return `${days}天前`
    return `${date.getMonth() + 1}月${date.getDate()}日`
  } catch {
    return timeStr
  }
}

onMounted(() => {
  fetchHotPosts()
})
</script>

<style scoped>
.hot-posts-page {
  max-width: 1200px;
  margin: 0 auto;
}

.page-header {
  margin-bottom: 32px;
  text-align: center;
}

.page-header h1 {
  font-size: 28px;
  font-weight: 700;
  margin-bottom: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
}

.page-header h1 svg {
  color: #ff6b35;
}

.subtitle {
  font-size: 14px;
  color: var(--text-secondary);
}

.posts-container {
  min-height: 400px;
}

.loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 80px 0;
  color: var(--text-secondary);
}

.spinner {
  width: 40px;
  height: 40px;
  border: 3px solid var(--border);
  border-top-color: var(--primary);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
  margin-bottom: 16px;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 80px 0;
  color: var(--text-secondary);
}

.empty svg {
  margin-bottom: 16px;
  opacity: 0.3;
}

.posts-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 16px;
}

.post-card {
  padding: 20px;
  background: var(--card);
  border: 1px solid var(--border);
  border-radius: 16px;
  cursor: pointer;
  transition: all 0.2s;
  position: relative;
}

.post-card:hover {
  border-color: var(--primary);
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.2);
}

.post-card.top-3 {
  border-color: #ff6b35;
  background: linear-gradient(135deg, rgba(255, 107, 53, 0.05), rgba(255, 107, 53, 0.02));
}

.rank-badge {
  position: absolute;
  top: -10px;
  left: 16px;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  font-weight: 700;
  color: #fff;
}

.rank-1 {
  background: linear-gradient(135deg, #ffd700, #ffed4e);
}

.rank-2 {
  background: linear-gradient(135deg, #c0c0c0, #e8e8e8);
}

.rank-3 {
  background: linear-gradient(135deg, #cd7f32, #e8a862);
}

.pin-badge {
  position: absolute;
  top: -8px;
  right: 12px;
  padding: 2px 8px;
  background: var(--primary);
  color: #fff;
  font-size: 10px;
  font-weight: 600;
  border-radius: 6px;
  display: flex;
  align-items: center;
  gap: 4px;
}

.post-header {
  display: flex;
  gap: 12px;
  margin-bottom: 12px;
}

.avatar {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  background: linear-gradient(135deg, var(--primary), var(--accent));
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

.meta {
  flex: 1;
}

.username {
  font-size: 14px;
  font-weight: 600;
  margin-bottom: 4px;
}

.time {
  font-size: 12px;
  color: var(--text-secondary);
}

.post-content {
  margin-bottom: 12px;
}

.topic {
  display: inline-block;
  padding: 4px 8px;
  background: rgba(124, 159, 203, 0.1);
  color: var(--primary);
  font-size: 12px;
  border-radius: 6px;
  margin-bottom: 8px;
}

.post-content p {
  font-size: 14px;
  line-height: 1.6;
  color: var(--text);
}

.post-stats {
  display: flex;
  gap: 16px;
  font-size: 13px;
  color: var(--text-secondary);
}

.stat {
  display: flex;
  align-items: center;
  gap: 4px;
}

.stat svg {
  opacity: 0.6;
}
</style>
