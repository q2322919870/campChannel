<template>
  <teleport to="body">
    <div class="user-card-overlay" v-if="visible" @click.self="$emit('close')">
      <div class="user-card">
        <div class="card-header">
          <div class="card-avatar" @click="previewAvatar">
            <img v-if="profile.avatar" :src="profile.avatar" />
            <span v-else>{{ (profile.username || '?').charAt(0) }}</span>
          </div>
          <h3>{{ profile.username || '用户' }}</h3>
          <p class="card-email">{{ profile.email || '' }}</p>
        </div>

        <div class="card-actions">
          <button v-if="profile.isFriend" class="action-btn primary" @click="startChat">发消息</button>
          <button v-else class="action-btn outline" @click="addFriend">加好友</button>
        </div>

        <div class="card-posts">
          <h4>帖子 ({{ profile.posts?.length || 0 }})</h4>
          <div v-for="p in profile.posts" :key="p.id" class="post-item" @click="$router.push('/post/' + p.id); $emit('close')">
            <p v-if="p.content" class="post-text">{{ p.content?.substring(0, 60) }}{{ p.content?.length > 60 ? '...' : '' }}</p>
            <div v-if="p.images && p.images.length" class="post-images-grid" :class="'grid-count-' + Math.min(p.images.length, 9)">
              <div v-for="(img, i) in p.images.slice(0, 9)" :key="i" class="grid-image-cell">
                <img :src="img" @click.stop="$router.push('/post/' + p.id); $emit('close')" />
              </div>
            </div>
          </div>
          <div v-if="!profile.posts?.length" class="no-posts">暂无帖子</div>
        </div>
      </div>
    </div>

    <teleport to="body" v-if="showPreview">
      <div class="preview-overlay" @click="showPreview = false">
        <img :src="profile.avatar" class="preview-img" />
      </div>
    </teleport>
  </teleport>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '../api/client'

const props = defineProps<{ visible: boolean; userId: number }>()
const emit = defineEmits<{ close: [] }>()
const router = useRouter()

const profile = reactive({
  id: 0,
  username: '',
  email: '',
  avatar: '',
  posts: [] as any[],
  isFriend: false,
})
const showPreview = ref(false)

async function fetchProfile() {
  // Don't fetch if userId is invalid
  if (!props.userId || props.userId <= 0) return
  
  try {
    const res = await api.get(`/users/${props.userId}/profile`)
    if (res.data.code === 200) {
      const d = res.data.data
      profile.id = d.id
      profile.username = d.username || ''
      profile.avatar = d.avatar || ''
      profile.email = d.email || ''
      profile.isFriend = d.isFriend || false
      profile.posts = d.posts || []
    }
  } catch (e) {
    // fallback: try individual endpoints
    try {
      const res = await api.get(`/users/${props.userId}`)
      if (res.data.code === 200) {
        profile.username = res.data.data.username || ''
        profile.avatar = res.data.data.avatar || ''
        profile.email = res.data.data.email || ''
      }
    } catch {}
    try {
      const pRes = await api.get(`/posts/user/${props.userId}`, { params: { page: 1, size: 20 } })
      if (pRes.data.code === 200) profile.posts = pRes.data.data || []
    } catch {}
    try {
      const fRes = await api.get('/friends/list')
      if (fRes.data.code === 200) {
        profile.isFriend = (fRes.data.data || []).some((f: any) => f.id === props.userId || f.friendId === props.userId)
      }
    } catch {}
  }
}

function previewAvatar() {
  if (profile.avatar) showPreview.value = true
}

async function addFriend() {
  try {
    await api.post('/friends/request', { friendId: props.userId })
    alert('好友申请已发送')
  } catch (e: any) { alert(e.response?.data?.message || '发送失败') }
}

function startChat() {
  emit('close')
  router.push('/chat?friendId=' + props.userId)
}

fetchProfile()
</script>

<style scoped>
.user-card-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; z-index: 2000; }
.user-card { width: 360px; max-height: 540px; overflow-y: auto; padding: 24px; background: var(--surface); backdrop-filter: blur(24px); border: 1px solid var(--outline-variant); border-radius: 20px; }
.card-header { text-align: center; margin-bottom: 16px; }
.card-avatar { width: 72px; height: 72px; border-radius: 18px; background: linear-gradient(135deg, var(--primary), var(--secondary)); display: flex; align-items: center; justify-content: center; font-size: 28px; font-weight: 700; color: #fff; margin: 0 auto 12px; overflow: hidden; cursor: pointer; }
.card-avatar img { width: 100%; height: 100%; object-fit: cover; }
.card-header h3 { font-size: 18px; font-weight: 600; }
.card-email { font-size: 12px; color: var(--on-surface-variant); }
.card-actions { display: flex; gap: 8px; justify-content: center; margin-bottom: 16px; }
.action-btn { padding: 10px 24px; border-radius: 10px; border: none; font-size: 14px; font-weight: 600; cursor: pointer; }
.action-btn.primary { background: linear-gradient(135deg, var(--primary), var(--secondary)); color: #fff; }
.action-btn.outline { border: 1px solid var(--primary); background: none; color: var(--primary); }
.card-posts h4 { font-size: 14px; margin-bottom: 8px; color: var(--on-surface-variant); }
.post-item { padding: 10px; background: rgba(255,255,255,0.03); border-radius: 10px; margin-bottom: 6px; cursor: pointer; }
.post-item:hover { background: rgba(255,255,255,0.06); }
.post-text { font-size: 13px; color: var(--on-surface); margin-bottom: 6px; }
/* 9-grid thumbnail layout */
.post-images-grid { display: grid; gap: 3px; max-width: 246px; }
.post-images-grid.grid-count-1 { grid-template-columns: 1fr; }
.post-images-grid.grid-count-2 { grid-template-columns: 1fr 1fr; }
.post-images-grid.grid-count-3 { grid-template-columns: 1fr 1fr 1fr; }
.post-images-grid.grid-count-4 { grid-template-columns: 1fr 1fr; }
.post-images-grid.grid-count-5 { grid-template-columns: 1fr 1fr 1fr; }
.post-images-grid.grid-count-6 { grid-template-columns: 1fr 1fr 1fr; }
.post-images-grid.grid-count-7 { grid-template-columns: 1fr 1fr 1fr; }
.post-images-grid.grid-count-8 { grid-template-columns: 1fr 1fr 1fr; }
.post-images-grid.grid-count-9 { grid-template-columns: 1fr 1fr 1fr; }
.grid-image-cell { width: 80px; height: 80px; overflow: hidden; border-radius: 6px; }
.grid-image-cell img { width: 100%; height: 100%; object-fit: cover; display: block; }
.no-posts { text-align: center; padding: 20px; color: var(--on-surface-variant); font-size: 13px; }
.preview-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.8); display: flex; align-items: center; justify-content: center; z-index: 3000; cursor: pointer; }
.preview-img { max-width: 80vw; max-height: 80vh; border-radius: 16px; }
</style>
