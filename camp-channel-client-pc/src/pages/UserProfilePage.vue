<template>
  <div class="user-profile-page">
    <div v-if="isLoading" class="loading-container">
      <div class="spinner"></div>
    </div>
    <template v-else>
      <!-- User Info Header -->
      <div class="user-header">
        <div class="avatar-section" @click="previewAvatar">
          <div class="avatar" :style="{ background: `linear-gradient(135deg, var(--primary), var(--secondary))` }">
            <img v-if="profile.avatar" :src="profile.avatar" />
            <span v-else>{{ (profile.username || '?').charAt(0) }}</span>
          </div>
        </div>
        <h1 class="username">{{ profile.username || '未知用户' }}</h1>
        <p v-if="profile.email" class="email">{{ profile.email }}</p>

        <!-- Stats -->
        <div class="stats">
          <div class="stat-item" @click="showFollowList('followers')">
            <span class="stat-num">{{ followerCount }}</span>
            <span class="stat-label">粉丝</span>
          </div>
          <div class="stat-item" @click="showFollowList('following')">
            <span class="stat-num">{{ followingCount }}</span>
            <span class="stat-label">关注</span>
          </div>
          <div class="stat-item">
            <span class="stat-num">{{ posts.length }}</span>
            <span class="stat-label">帖子</span>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="actions" v-if="profile.id !== currentUserId">
          <button class="action-btn primary" @click="startChat">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
            </svg>
            私聊
          </button>
          <button v-if="!profile.isFriend" class="action-btn outline" @click="addFriend">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
              <circle cx="8.5" cy="7" r="4"/>
              <line x1="20" y1="8" x2="20" y2="14"/>
              <line x1="23" y1="11" x2="17" y2="11"/>
            </svg>
            加好友
          </button>
          <button class="action-btn" :class="isFollowing ? 'outline' : 'primary'" @click="toggleFollow">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
              <circle cx="8.5" cy="7" r="4"/>
              <polyline v-if="isFollowing" points="17 11 19 13 23 9"/>
              <template v-else>
                <line x1="12" y1="5" x2="12" y2="19"/>
                <line x1="5" y1="12" x2="19" y2="12"/>
              </template>
            </svg>
            {{ isFollowing ? '已关注' : '关注' }}
          </button>
        </div>
      </div>

      <!-- Posts Section -->
      <div class="posts-section">
        <div class="section-header">
          <h2>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
              <polyline points="14 2 14 8 20 8"/>
              <line x1="16" y1="13" x2="8" y2="13"/>
              <line x1="16" y1="17" x2="8" y2="17"/>
              <polyline points="10 9 9 9 8 9"/>
            </svg>
            TA 的帖子
          </h2>
          <span class="post-count">{{ posts.length }} 篇</span>
        </div>

        <div v-if="isLoadingPosts" class="loading-posts">
          <div class="spinner"></div>
        </div>
        <div v-else-if="posts.length === 0" class="no-posts">
          <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
            <polyline points="14 2 14 8 20 8"/>
          </svg>
          <p>暂无帖子</p>
        </div>
        <div v-else class="posts-list">
          <div v-for="post in posts" :key="post.id" class="post-card" @click="viewPost(post.id)">
            <div class="post-content">
              <h3 v-if="post.topic" class="post-topic">{{ post.topic }}</h3>
              <p class="post-text">{{ post.content?.substring(0, 100) }}{{ post.content?.length > 100 ? '...' : '' }}</p>
            </div>
            <div v-if="post.images && post.images.length" class="post-images">
              <div v-for="(img, i) in post.images.slice(0, 4)" :key="i" class="image-cell">
                <img :src="img" />
              </div>
              <div v-if="post.images.length > 4" class="more-images">+{{ post.images.length - 4 }}</div>
            </div>
            <div class="post-footer">
              <span class="post-time">{{ formatTime(post.createTime) }}</span>
            </div>
          </div>
        </div>
      </div>
    </template>

    <!-- Avatar Preview -->
    <teleport to="body" v-if="showPreview">
      <div class="preview-overlay" @click="showPreview = false">
        <img :src="profile.avatar" class="preview-img" />
      </div>
    </teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api } from '../api/client'
import { useAuthStore } from '../stores/auth'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const currentUserId = computed(() => authStore.user?.id || 0)

const userId = computed(() => Number(route.params.id))

const isLoading = ref(true)
const isLoadingPosts = ref(true)
const profile = reactive({
  id: 0,
  username: '',
  email: '',
  avatar: '',
  isFriend: false,
})
const followerCount = ref(0)
const followingCount = ref(0)
const isFollowing = ref(false)
const posts = ref<any[]>([])
const showPreview = ref(false)

async function fetchProfile() {
  try {
    const res = await api.get(`/users/${userId.value}/profile`)
    if (res.data.code === 200) {
      const d = res.data.data
      profile.id = d.id
      profile.username = d.username || ''
      profile.avatar = d.avatar || ''
      profile.email = d.email || ''
      profile.isFriend = d.isFriend || false
      
      // Parse posts
      if (d.posts && Array.isArray(d.posts)) {
        posts.value = d.posts.map((p: any) => ({
          ...p,
          images: p.images || [],
        }))
      }
      isLoadingPosts.value = false
    }
  } catch (e) {
    isLoadingPosts.value = false
  }
  isLoading.value = false

  // Fetch follow counts
  try {
    const countRes = await api.get(`/follow/${userId.value}/counts`)
    if (countRes.data.code === 200) {
      followerCount.value = countRes.data.data.followerCount || 0
      followingCount.value = countRes.data.data.followingCount || 0
    }
  } catch {}

  // Fetch follow status
  if (userId.value !== currentUserId.value) {
    try {
      const followRes = await api.get(`/follow/${userId.value}/is-following`)
      if (followRes.data.code === 200) {
        isFollowing.value = followRes.data.data || false
      }
    } catch {}
  }
}

async function toggleFollow() {
  try {
    const res = await api.post(`/follow/${userId.value}/toggle`)
    if (res.data.code === 200) {
      isFollowing.value = res.data.data
      followerCount.value += res.data.data ? 1 : -1
      if (followerCount.value < 0) followerCount.value = 0
    }
  } catch (e: any) { alert(e.response?.data?.message || '操作失败') }
}

async function addFriend() {
  try {
    await api.post('/friends/request', { friendId: userId.value })
    alert('好友申请已发送')
  } catch (e: any) { alert(e.response?.data?.message || '发送失败') }
}

function startChat() {
  router.push({ path: '/chat', query: { friendId: userId.value.toString() } })
}

function viewPost(postId: number) {
  router.push({ name: 'PostDetail', params: { id: postId.toString() } })
}

function showFollowList(tab: string) {
  router.push({
    path: '/follow-list',
    query: { userId: userId.value.toString(), username: profile.username, tab }
  })
}

function previewAvatar() {
  if (profile.avatar) showPreview.value = true
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
  fetchProfile()
})
</script>

<style scoped>
.user-profile-page {
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
}

.loading-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 400px;
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

.user-header {
  text-align: center;
  padding: 32px 24px;
  background: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: 20px;
  margin-bottom: 24px;
}

.avatar-section {
  margin-bottom: 16px;
}

.avatar {
  width: 96px;
  height: 96px;
  border-radius: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 36px;
  font-weight: 700;
  color: #fff;
  margin: 0 auto;
  overflow: hidden;
  cursor: pointer;
  transition: transform 0.2s;
}

.avatar:hover {
  transform: scale(1.05);
}

.avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.username {
  font-size: 24px;
  font-weight: 700;
  margin-bottom: 4px;
}

.email {
  font-size: 14px;
  color: var(--on-surface-variant);
  margin-bottom: 20px;
}

.stats {
  display: flex;
  justify-content: center;
  gap: 32px;
  margin-bottom: 20px;
}

.stat-item {
  text-align: center;
  cursor: pointer;
  padding: 8px 16px;
  border-radius: 12px;
  transition: background 0.2s;
}

.stat-item:hover {
  background: var(--surface-tint);
}

.stat-num {
  display: block;
  font-size: 20px;
  font-weight: 700;
}

.stat-label {
  font-size: 12px;
  color: var(--on-surface-variant);
}

.actions {
  display: flex;
  gap: 12px;
  justify-content: center;
  flex-wrap: wrap;
}

.action-btn {
  padding: 10px 24px;
  border-radius: 12px;
  border: none;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: all 0.2s;
}

.action-btn.primary {
  background: linear-gradient(135deg, var(--primary), var(--secondary));
  color: #fff;
}

.action-btn.primary:hover {
  opacity: 0.9;
  transform: translateY(-1px);
}

.action-btn.outline {
  border: 1px solid var(--primary);
  background: none;
  color: var(--primary);
}

.action-btn.outline:hover {
  background: var(--surface-tint);
}

.posts-section {
  background: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: 20px;
  padding: 24px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.section-header h2 {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 18px;
  font-weight: 600;
}

.post-count {
  font-size: 14px;
  color: var(--on-surface-variant);
}

.loading-posts {
  display: flex;
  justify-content: center;
  padding: 40px;
}

.no-posts {
  text-align: center;
  padding: 40px;
  color: var(--on-surface-variant);
}

.no-posts svg {
  margin-bottom: 12px;
  opacity: 0.3;
}

.posts-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.post-card {
  padding: 16px;
  background: var(--surface-variant);
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s;
}

.post-card:hover {
  border-color: var(--primary);
  transform: translateY(-2px);
}

.post-topic {
  font-size: 15px;
  font-weight: 600;
  margin-bottom: 6px;
  color: var(--primary);
}

.post-text {
  font-size: 14px;
  color: var(--on-surface);
  margin-bottom: 12px;
  line-height: 1.5;
}

.post-images {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(80px, 1fr));
  gap: 4px;
  margin-bottom: 12px;
}

.image-cell {
  width: 100%;
  aspect-ratio: 1;
  overflow: hidden;
  border-radius: 8px;
}

.image-cell img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.more-images {
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--surface);
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  color: var(--on-surface-variant);
}

.post-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.post-time {
  font-size: 12px;
  color: var(--on-surface-variant);
}

.preview-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.8);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 3000;
  cursor: pointer;
}

.preview-img {
  max-width: 80vw;
  max-height: 80vh;
  border-radius: 16px;
}
</style>
