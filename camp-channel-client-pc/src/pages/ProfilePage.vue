<template>
  <div class="profile-page">
    <!-- Weather effects canvas overlay -->
    <canvas ref="weatherCanvas" class="weather-canvas"></canvas>

    <div class="profile-header">
      <div class="avatar-wrapper" @click="previewAvatar">
        <div class="profile-avatar">
          <img v-if="avatarUrl" :src="avatarUrl" />
          <div v-else class="no-avatar">{{ username.charAt(0) }}</div>
        </div>
      </div>
      <div class="profile-info">
        <h1 class="profile-name">{{ username }}</h1>
        <p class="profile-email">{{ email }}</p>
        <div class="profile-stats">
          <div class="stat-item"><span class="stat-value">{{ posts }}</span><span class="stat-label">帖子</span></div>
          <div class="stat-item"><span class="stat-value">{{ friends }}</span><span class="stat-label">好友</span></div>
          <div class="stat-item"><span class="stat-value">{{ likes }}</span><span class="stat-label">获赞</span></div>
        </div>
      </div>
    </div>

    <!-- Badge showcase -->
    <BadgeShowcase />

    <div class="profile-nav">
      <div class="nav-item" @click="$router.push('/home')">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/></svg>
        <span>我的帖子</span>
      </div>
      <div class="nav-item" @click="$router.push('/friends')">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
        <span>好友管理</span>
      </div>
      <div class="nav-item" @click="$router.push('/liked-posts')">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>
        <span>赞过的贴</span>
      </div>
      <div class="nav-item" @click="$router.push('/favourites')">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"/></svg>
        <span>我的收藏</span>
      </div>
      <div class="nav-item" @click="$router.push('/drafts')">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>
        <span>我的草稿</span>
      </div>
      <div class="nav-item" @click="$router.push('/settings')">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>
        <span>设置</span>
      </div>
    </div>

    <button class="logout-btn" @click="handleLogout">退出登录</button>

    <input ref="fileInput" type="file" accept="image/png,image/jpeg,image/gif,image/webp" hidden @change="uploadAvatar" />

    <teleport to="body">
      <div v-if="showPreview" class="avatar-preview-overlay" @click.self="showPreview = false">
        <div class="avatar-preview-card" @click.stop>
          <img :src="avatarUrl" class="avatar-preview-img" />
          <div class="avatar-preview-actions">
            <button class="preview-btn" @click="triggerUpload">更改图片</button>
            <button class="preview-btn" @click="downloadAvatar">下载图片</button>
          </div>
          <button class="close-preview" @click="showPreview = false">关闭</button>
        </div>
      </div>
    </teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '../api/client'
import { useAuthStore } from '../stores/auth'
import BadgeShowcase from '../components/BadgeShowcase.vue'
import { WeatherEffectsRenderer, getCurrentTimePeriod } from '../canvas/WeatherEffects'

const router = useRouter()
const authStore = useAuthStore()
const fileInput = ref<HTMLInputElement>()
const username = ref(authStore.user?.username || '未登录')
const email = ref(authStore.user?.email || '')
const avatarUrl = ref('')
const posts = ref(0)
const friends = ref(0)
const likes = ref(0)
const showPreview = ref(false)
const weatherCanvas = ref<HTMLCanvasElement>()
let weatherRenderer: WeatherEffectsRenderer | null = null

function previewAvatar() {
  if (avatarUrl.value) showPreview.value = true
}

function downloadAvatar() {
  if (avatarUrl.value) {
    const a = document.createElement('a')
    a.href = avatarUrl.value
    a.download = 'avatar.jpg'
    a.click()
  }
}

async function fetchProfile() {
  try {
    const res = await api.get('/users/me')
    if (res.data.code === 200) {
      username.value = res.data.data.username || '未登录'
      email.value = res.data.data.email || ''
      avatarUrl.value = res.data.data.avatar || ''
    }
    const pRes = await api.get('/posts/my', { params: { page: 1, size: 100 } })
    if (pRes.data.code === 200 && Array.isArray(pRes.data.data)) posts.value = pRes.data.data.length
    const fRes = await api.get('/friends')
    if (fRes.data.code === 200 && Array.isArray(fRes.data.data)) friends.value = fRes.data.data.length
  } catch {}
}

function handleLogout() { authStore.logout(); router.push('/login') }

function triggerUpload() { fileInput.value?.click() }

async function uploadAvatar(e: Event) {
  const input = e.target as HTMLInputElement
  if (!input.files?.length) return
  const file = input.files[0]
  if (file.size > 10 * 1024 * 1024) { alert('图片不能超过10MB'); input.value = ''; return }
  const formData = new FormData()
  formData.append('file', file)
  try {
    const res = await api.post('/users/avatar', formData, { headers: { 'Content-Type': 'multipart/form-data' } })
    if (res.data.code === 200 && res.data.data?.url) {
      avatarUrl.value = res.data.data.url
      if (authStore.user) authStore.user.avatar = res.data.data.url
      alert('头像更新成功')
    } else { alert(res.data.message || '上传失败') }
  } catch (e: any) { alert(e.response?.data?.message || e.message || '上传失败') }
  input.value = ''
}

onMounted(() => {
  fetchProfile()
  initWeatherEffects()
})

onUnmounted(() => {
  weatherRenderer?.stop()
})

function initWeatherEffects() {
  const canvas = weatherCanvas.value
  if (!canvas) return
  const parent = canvas.parentElement
  if (!parent) return
  canvas.width = parent.clientWidth
  canvas.height = parent.clientHeight
  const period = getCurrentTimePeriod()
  weatherRenderer = new WeatherEffectsRenderer(canvas, period)
  weatherRenderer.start()
}
</script>

<style scoped>
.profile-page { max-width: 600px; margin: 0 auto; padding: 40px 0; position: relative; }
.weather-canvas { position: absolute; inset: 0; width: 100%; height: 100%; pointer-events: none; z-index: 0; }
.profile-header { display: flex; gap: 24px; align-items: center; padding: 32px; background: var(--surface); border: 1px solid var(--outline-variant); border-radius: 20px; margin-bottom: 16px; }
.avatar-wrapper { position: relative; cursor: pointer; flex-shrink: 0; }
.profile-avatar { width: 80px; height: 80px; border-radius: 20px; background: linear-gradient(135deg, var(--primary), var(--secondary)); display: flex; align-items: center; justify-content: center; font-size: 32px; font-weight: 700; color: #fff; overflow: hidden; }
.profile-avatar img { width: 100%; height: 100%; object-fit: cover; }
.no-avatar { width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; font-size: 32px; font-weight: 700; color: #fff; }
.profile-info { flex: 1; }
.profile-name { font-size: 24px; font-weight: 700; margin-bottom: 4px; }
.profile-email { font-size: 14px; color: var(--on-surface-variant); margin-bottom: 16px; }
.profile-stats { display: flex; gap: 24px; }
.stat-item { text-align: center; }
.stat-value { display: block; font-size: 22px; font-weight: 700; color: var(--primary); }
.stat-label { font-size: 12px; color: var(--on-surface-variant); }
.profile-nav { display: flex; flex-direction: column; gap: 8px; margin-bottom: 16px; }
.nav-item { display: flex; align-items: center; gap: 12px; padding: 16px; background: var(--surface); border: 1px solid var(--outline-variant); border-radius: 14px; cursor: pointer; transition: all 0.2s; color: var(--on-surface); }
.nav-item:hover { border-color: var(--primary); transform: translateX(4px); }
.logout-btn { width: 100%; padding: 14px; border: 1px solid rgba(255,107,107,0.3); border-radius: 14px; background: rgba(255,107,107,0.05); color: #ff6b6b; font-size: 15px; font-weight: 600; cursor: pointer; transition: all 0.2s; }
.logout-btn:hover { background: rgba(255,107,107,0.1); }

.avatar-preview-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.7); display: flex; align-items: center; justify-content: center; z-index: 3000; animation: fadeIn 0.2s ease; }
@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
.avatar-preview-card { text-align: center; max-width: 400px; width: 90%; animation: scaleIn 0.25s cubic-bezier(0.34, 1.56, 0.64, 1); }
@keyframes scaleIn { from { transform: scale(0.5); opacity: 0; } to { transform: scale(1); opacity: 1; } }
.avatar-preview-img { width: 100%; max-height: 60vh; object-fit: contain; border-radius: 16px; box-shadow: 0 8px 40px rgba(0,0,0,0.4); margin-bottom: 16px; }
.avatar-preview-actions { display: flex; gap: 12px; justify-content: center; margin-bottom: 12px; }
.preview-btn { padding: 10px 24px; border: none; border-radius: 10px; background: linear-gradient(135deg, var(--primary), var(--secondary)); color: #fff; font-size: 14px; font-weight: 600; cursor: pointer; }
.close-preview { padding: 8px 24px; border: 1px solid var(--outline-variant); border-radius: 10px; background: var(--surface); color: var(--on-surface-variant); font-size: 13px; cursor: pointer; }
</style>
