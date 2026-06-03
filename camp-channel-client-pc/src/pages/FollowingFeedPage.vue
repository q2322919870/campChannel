<template>
  <div class="following-feed-page">
    <div class="page-header">
      <h1>关注动态</h1>
      <p class="subtitle">查看你关注的人发布的帖子</p>
    </div>

    <div v-if="isLoading" class="loading">
      <div class="spinner"></div>
    </div>

    <div v-else-if="posts.length === 0" class="empty-state">
      <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
        <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
        <circle cx="8.5" cy="7" r="4"/>
        <line x1="20" y1="8" x2="20" y2="14"/>
        <line x1="23" y1="11" x2="17" y2="11"/>
      </svg>
      <h3>暂无关注动态</h3>
      <p>关注更多人，获取更多精彩内容</p>
      <button class="btn-primary" @click="router.push('/home')">去首页发现</button>
    </div>

    <div v-else class="posts-list">
      <div v-for="post in posts" :key="post.id" class="post-card" @click="viewPost(post.id)">
        <div class="post-header">
          <div class="author" @click.stop="viewProfile(post.authorId)">
            <div class="avatar" :style="{ background: `linear-gradient(135deg, var(--primary), var(--secondary))` }">
              <img v-if="post.authorAvatar" :src="post.authorAvatar" />
              <span v-else>{{ (post.authorName || '?').charAt(0) }}</span>
            </div>
            <div class="author-info">
              <h3>{{ post.authorName }}</h3>
              <span class="time">{{ formatTime(post.createTime) }}</span>
            </div>
          </div>
        </div>
        <div class="post-content">
          <h2 v-if="post.topic" class="topic">{{ post.topic }}</h2>
          <p class="text">{{ post.content }}</p>
          <div v-if="post.images && post.images.length" class="images">
            <div v-for="(img, i) in post.images.slice(0, 9)" :key="i" class="image-cell">
              <img :src="img" />
            </div>
          </div>
        </div>
        <div class="post-footer">
          <span class="channel" v-if="post.channelName"># {{ post.channelName }}</span>
          <div class="stats">
            <span><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg> {{ post.viewCount || 0 }}</span>
            <span><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg> {{ post.commentCount || 0 }}</span>
            <span><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg> {{ post.likeCount || 0 }}</span>
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
const posts = ref<any[]>([])
const isLoading = ref(true)

async function fetchFeed() {
  try {
    const res = await api.get('/follow/feed', { params: { page: 1, size: 20 } })
    if (res.data.code === 200) {
      posts.value = (res.data.data || []).map((p: any) => ({
        ...p,
        images: p.images || [],
      }))
    }
  } catch {}
  isLoading.value = false
}

function viewPost(id: number) {
  router.push({ name: 'PostDetail', params: { id: id.toString() } })
}

function viewProfile(id: number) {
  router.push({ path: `/user/${id}` })
}

function formatTime(time: string) {
  if (!time) return ''
  const date = new Date(time)
  const now = new Date()
  const diff = now.getTime() - date.getTime()
  const minutes = Math.floor(diff / 60000)
  const hours = Math.floor(diff / 3600000)
  const days = Math.floor(diff / 86400000)
  
  if (minutes < 1) return '刚刚'
  if (minutes < 60) return `${minutes}分钟前`
  if (hours < 24) return `${hours}小时前`
  if (days < 7) return `${days}天前`
  return date.toLocaleDateString('zh-CN')
}

onMounted(() => {
  fetchFeed()
})
</script>

<style scoped>
.following-feed-page {
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
}

.page-header {
  margin-bottom: 24px;
}

.page-header h1 {
  font-size: 28px;
  font-weight: 700;
  margin-bottom: 4px;
}

.subtitle {
  font-size: 14px;
  color: var(--on-surface-variant);
}

.loading {
  display: flex;
  justify-content: center;
  padding: 60px;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 3px solid var(--outline-variant);
  border-top-color: var(--primary);
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: var(--on-surface-variant);
}

.empty-state svg {
  margin-bottom: 16px;
  opacity: 0.3;
}

.empty-state h3 {
  font-size: 18px;
  margin-bottom: 8px;
}

.empty-state p {
  margin-bottom: 20px;
}

.btn-primary {
  padding: 12px 24px;
  border-radius: 12px;
  border: none;
  background: linear-gradient(135deg, var(--primary), var(--secondary));
  color: #fff;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-primary:hover {
  opacity: 0.9;
  transform: translateY(-1px);
}

.posts-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.post-card {
  background: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: 20px;
  padding: 20px;
  cursor: pointer;
  transition: all 0.2s;
}

.post-card:hover {
  border-color: var(--primary);
  transform: translateY(-2px);
}

.post-header {
  margin-bottom: 12px;
}

.author {
  display: flex;
  align-items: center;
  gap: 12px;
}

.avatar {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
  font-weight: 600;
  color: #fff;
  overflow: hidden;
  flex-shrink: 0;
}

.avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.author-info h3 {
  font-size: 14px;
  font-weight: 600;
  margin: 0;
}

.time {
  font-size: 12px;
  color: var(--on-surface-variant);
}

.post-content {
  margin-bottom: 12px;
}

.topic {
  font-size: 16px;
  font-weight: 600;
  margin-bottom: 8px;
  color: var(--primary);
}

.text {
  font-size: 14px;
  line-height: 1.6;
  margin-bottom: 12px;
}

.images {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 4px;
}

.image-cell {
  aspect-ratio: 1;
  overflow: hidden;
  border-radius: 8px;
}

.image-cell img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.post-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 12px;
  border-top: 1px solid var(--outline-variant);
}

.channel {
  font-size: 13px;
  color: var(--primary);
  font-weight: 500;
}

.stats {
  display: flex;
  gap: 16px;
  font-size: 13px;
  color: var(--on-surface-variant);
}

.stats span {
  display: flex;
  align-items: center;
  gap: 4px;
}
</style>
