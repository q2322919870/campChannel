<template>
  <div class="search-page">
    <div class="search-header">
      <div class="search-bar">
        <svg class="search-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="11" cy="11" r="8"></circle>
          <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
        </svg>
        <input 
          v-model="keyword" 
          placeholder="搜索帖子内容、话题..." 
          @keyup.enter="handleSearch"
          ref="searchInput"
        />
        <button @click="handleSearch" :disabled="!keyword.trim()">搜索</button>
      </div>
    </div>

    <div class="search-results">
      <div v-if="isLoading" class="loading">
        <div class="spinner"></div>
        <p>搜索中...</p>
      </div>
      
      <div v-else-if="hasSearched && results.length === 0" class="empty">
        <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
          <circle cx="11" cy="11" r="8"></circle>
          <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
        </svg>
        <p>没有找到相关帖子</p>
      </div>

      <div v-else-if="!hasSearched" class="recent-searches">
        <h3>最近搜索</h3>
        <div class="tags">
          <span 
            v-for="tag in recentSearches" 
            :key="tag" 
            class="tag"
            @click="searchByTag(tag)"
          >
            {{ tag }}
          </span>
        </div>
        <div v-if="recentSearches.length === 0" class="empty-hint">
          <p>输入关键词开始搜索</p>
        </div>
      </div>

      <div v-else class="posts-list">
        <div v-for="post in results" :key="post.id" class="post-card" @click="goToPost(post)">
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
            <p>{{ post.content }}</p>
          </div>
          <div class="post-stats">
            <span>❤️ {{ post.likeCount || 0 }}</span>
            <span>💬 {{ post.commentCount || 0 }}</span>
            <span>👁️ {{ post.viewCount || 0 }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '../api/client'

const router = useRouter()
const keyword = ref('')
const results = ref<any[]>([])
const isLoading = ref(false)
const hasSearched = ref(false)
const recentSearches = ref<string[]>([])
const searchInput = ref<HTMLInputElement>()

function handleSearch() {
  if (!keyword.value.trim()) return
  
  // Save to recent searches
  const tag = keyword.value.trim()
  recentSearches.value = recentSearches.value.filter(t => t !== tag)
  recentSearches.value.unshift(tag)
  if (recentSearches.value.length > 10) {
    recentSearches.value = recentSearches.value.slice(0, 10)
  }
  localStorage.setItem('recentSearches', JSON.stringify(recentSearches.value))
  
  performSearch()
}

async function performSearch() {
  isLoading.value = true
  hasSearched.value = true
  
  try {
    const res = await api.get('/posts/search', {
      params: {
        keyword: keyword.value,
        page: 1,
        size: 20
      }
    })
    
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      results.value = res.data.data
    }
  } catch (e) {
    console.error('Search failed:', e)
  } finally {
    isLoading.value = false
  }
}

function searchByTag(tag: string) {
  keyword.value = tag
  performSearch()
  nextTick(() => {
    searchInput.value?.focus()
  })
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
  const saved = localStorage.getItem('recentSearches')
  if (saved) {
    try {
      recentSearches.value = JSON.parse(saved)
    } catch {}
  }
  searchInput.value?.focus()
})
</script>

<style scoped>
.search-page {
  max-width: 800px;
  margin: 0 auto;
}

.search-header {
  margin-bottom: 24px;
}

.search-bar {
  display: flex;
  gap: 12px;
  padding: 16px;
  background: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: 16px;
  align-items: center;
}

.search-icon {
  color: var(--on-surface-variant);
  flex-shrink: 0;
}

.search-bar input {
  flex: 1;
  border: none;
  background: transparent;
  color: var(--on-surface);
  font-size: 16px;
  outline: none;
}

.search-bar input::placeholder {
  color: var(--on-surface-variant);
}

.search-bar button {
  padding: 10px 24px;
  background: var(--primary);
  color: #fff;
  border: none;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.search-bar button:hover:not(:disabled) {
  opacity: 0.9;
}

.search-bar button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.search-results {
  min-height: 400px;
}

.loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 80px 0;
  color: var(--on-surface-variant);
}

.spinner {
  width: 40px;
  height: 40px;
  border: 3px solid var(--outline-variant);
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
  color: var(--on-surface-variant);
}

.empty svg {
  margin-bottom: 16px;
  opacity: 0.3;
}

.recent-searches {
  padding: 24px;
  background: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: 16px;
}

.recent-searches h3 {
  font-size: 16px;
  margin-bottom: 16px;
  color: var(--on-surface);
}

.tags {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.tag {
  padding: 8px 16px;
  background: rgba(124, 159, 203, 0.1);
  border: 1px solid var(--primary);
  border-radius: 20px;
  color: var(--primary);
  font-size: 13px;
  cursor: pointer;
  transition: all 0.2s;
}

.tag:hover {
  background: rgba(124, 159, 203, 0.2);
}

.empty-hint {
  text-align: center;
  color: var(--on-surface-variant);
  padding: 40px 0;
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
  border-radius: 14px;
  cursor: pointer;
  transition: all 0.2s;
  position: relative;
}

.post-card:hover {
  border-color: var(--primary);
  transform: translateX(4px);
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
  color: var(--on-surface-variant);
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
  color: var(--on-surface);
}

.post-stats {
  display: flex;
  gap: 16px;
  font-size: 12px;
  color: var(--on-surface-variant);
}
</style>
