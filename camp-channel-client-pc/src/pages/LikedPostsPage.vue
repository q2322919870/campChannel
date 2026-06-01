<template>
  <div class="liked-posts-page">
    <h1 class="page-title">赞过的贴</h1>
    <div v-if="loading" class="loading-state">加载中...</div>
    <div v-else-if="posts.length === 0" class="empty-state">暂无点赞记录</div>
    <div v-else class="posts-grid">
      <div v-for="post in posts" :key="post.id" class="post-card" @click="$router.push('/post/' + post.id)">
        <div class="post-header">
          <div class="post-avatar" @click.stop>
            <img v-if="post.avatar" :src="post.avatar" class="post-avatar-img" />
            <span v-else>{{ post.author ? post.author.charAt(0) : '?' }}</span>
          </div>
          <div class="post-meta">
            <span class="post-author">{{ post.author || '用户' }}</span>
            <span class="post-time">{{ post.time || '' }}</span>
          </div>
        </div>
        <h3 class="post-title">{{ post.title }}</h3>
        <p class="post-content">{{ post.content }}</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { api } from '../api/client'

const posts = ref<any[]>([])
const loading = ref(false)

async function fetchLikedPosts() {
  loading.value = true
  try {
    const res = await api.get('/posts/liked', { params: { page: 1, size: 20 } })
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      posts.value = res.data.data.map((p: any) => ({
        ...p,
        id: p.id,
        title: p.topic || '帖子',
        content: p.content || '',
        author: p.username || '用户',
        avatar: p.avatar || '',
        time: p.createTime || '',
      }))
    }
  } catch {}
  finally { loading.value = false }
}

onMounted(() => { fetchLikedPosts() })
</script>

<style scoped>
.liked-posts-page { max-width: 800px; margin: 0 auto; }
.page-title { font-size: 28px; font-weight: 700; margin-bottom: 24px; }
.loading-state, .empty-state { text-align: center; padding: 60px 20px; color: var(--on-surface-variant); font-size: 15px; }
.posts-grid { display: flex; flex-direction: column; gap: 12px; }
.post-card { padding: 20px; background: var(--surface); border: 1px solid var(--outline-variant); border-radius: 16px; cursor: pointer; transition: all 0.2s; }
.post-card:hover { border-color: var(--primary); }
.post-header { display: flex; align-items: center; gap: 10px; margin-bottom: 12px; }
.post-avatar { width: 36px; height: 36px; border-radius: 10px; background: linear-gradient(135deg, var(--primary), var(--secondary)); display: flex; align-items: center; justify-content: center; font-size: 14px; font-weight: 700; color: #fff; overflow: hidden; flex-shrink: 0; }
.post-avatar img { width: 100%; height: 100%; object-fit: cover; }
.post-meta { flex: 1; }
.post-author { font-size: 14px; font-weight: 600; display: block; }
.post-time { font-size: 11px; color: var(--on-surface-variant); }
.post-title { font-size: 16px; font-weight: 600; margin-bottom: 6px; }
.post-content { font-size: 14px; color: var(--on-surface-variant); line-height: 1.6; overflow: hidden; text-overflow: ellipsis; display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; }
</style>
