<template>
  <div class="create-post-page">
    <div class="create-post-card">
      <h1 class="page-title">{{ isEditMode ? '编辑帖子' : '发布帖子' }}</h1>

      <div class="user-info-row">
        <div class="user-avatar">
          <img v-if="currentUser?.avatar" :src="currentUser.avatar" />
          <span v-else>{{ (currentUser?.username || '?').charAt(0) }}</span>
        </div>
        <span class="user-name">{{ currentUser?.username || '未知用户' }}</span>
      </div>
      
      <form @submit.prevent="handleSubmit" class="post-form">
        <div class="form-group">
          <label>选择频道 *</label>
          <select v-model="channelId" required>
            <option value="">请选择频道</option>
            <option v-for="ch in channels" :key="ch.id" :value="ch.id">{{ ch.name }}</option>
          </select>
        </div>

        <div class="form-group">
          <label>内容 *</label>
          <textarea v-model="content" placeholder="写点什么..." rows="6" maxlength="2000" required></textarea>
          <span class="char-count">{{ content.length }}/2000</span>
        </div>

        <div class="form-group">
          <label>图片和视频（选填，最多9个）</label>
          <div class="media-upload-area">
            <div v-for="(item, i) in mediaItems" :key="i" class="media-preview">
              <img v-if="item.type === 'image'" :src="item.url" />
              <video v-else :src="item.url" class="video-preview" />
              <span class="media-type-badge">{{ item.type === 'image' ? '图' : '视频' }}</span>
              <button type="button" class="remove-media" @click="mediaItems.splice(i, 1)">×</button>
            </div>
            <label v-if="mediaItems.length < 9" class="upload-btn">
              <input type="file" accept="image/*" multiple @change="handleImageUpload" hidden />
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            </label>
            <SmartVideoUploader
              v-if="mediaItems.length < 9"
              :disabled="isUploadingVideo"
              @uploaded="onVideoUploaded"
            />
          </div>
          <span class="media-count">{{ mediaItems.length }}/9</span>
          <div v-if="isUploadingVideo" class="upload-progress">
            <div class="progress-bar">
              <div class="progress-fill" :style="{ width: videoUploadProgress + '%' }"></div>
            </div>
            <span class="progress-text">{{ videoUploadStatusText }}</span>
          </div>
        </div>

        <div class="form-group">
          <label>话题（选填，格式 #话题#）</label>
          <input v-model="topic" placeholder="#话题名称#" />
        </div>

        <div class="form-group">
          <label>@提及（选填）</label>
          <input v-model="mentionInput" placeholder="@用户名" />
        </div>

        <p v-if="error" class="error-msg">{{ error }}</p>

        <div class="form-actions">
          <button type="button" class="btn cancel" @click="$router.back()">取消</button>
          <button v-if="!isEditMode" type="button" class="btn draft" @click="saveDraft" :disabled="savingDraft || !content.trim()">
            {{ savingDraft ? '保存中...' : '存草稿' }}
          </button>
          <button type="submit" class="btn submit" :disabled="loading || !channelId || !content.trim()">
            {{ loading ? (isEditMode ? '保存中...' : '发布中...') : (isEditMode ? '保存' : '发布') }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { api } from '../api/client'
import { useAuthStore } from '../stores/auth'
import SmartVideoUploader from '../components/SmartVideoUploader.vue'
import { useVideoUploader } from '../composables/useVideoUploader'

interface MediaItem {
  type: 'image' | 'video'
  url: string
}

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()
const currentUser = computed(() => authStore.user)
const editId = computed(() => route.query.editId as string || '')
const isEditMode = computed(() => !!editId.value)
const channels = ref<any[]>([])
const channelId = ref('')
const content = ref('')
const mediaItems = ref<MediaItem[]>([])
const topic = ref('')
const mentionInput = ref('')
const loading = ref(false)
const savingDraft = ref(false)
const error = ref('')

// 视频上传状态
const {
  status: videoUploadStatus,
  progress: videoUploadProgress,
  errorMsg: videoUploadError,
  isUploading: isUploadingVideo,
} = useVideoUploader()

const videoUploadStatusText = computed(() => {
  const map: Record<string, string> = {
    idle: '',
    hashing: '正在计算文件指纹...',
    checking: '正在检查秒传...',
    uploading: '正在上传...',
    success: '上传成功',
    error: '上传失败',
  }
  return map[videoUploadStatus.value] || ''
})

function onVideoUploaded(url: string) {
  if (mediaItems.value.length < 9) {
    mediaItems.value.push({ type: 'video', url })
  }
}

async function fetchChannels() {
  try {
    const res = await api.get('/channels/my')
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      channels.value = res.data.data
    }
  } catch (e) {}
}

async function handleImageUpload(e: Event) {
  const input = e.target as HTMLInputElement
  if (!input.files?.length) return
  for (const file of Array.from(input.files)) {
    if (mediaItems.value.length >= 9) break

    try {
      const formData = new FormData()
      formData.append('file', file)
      const res = await api.post('/upload/image', formData)
      if (res.data.code === 200 && res.data.data?.url) {
        if (mediaItems.value.length < 9) {
          mediaItems.value.push({
            type: 'image',
            url: res.data.data.url
          })
        }
      }
    } catch (e: any) {
      error.value = e.response?.data?.message || '图片上传失败'
    }
  }
  input.value = ''
}

async function handleSubmit() {
  if (!channelId.value || !content.value.trim()) return
  loading.value = true
  error.value = ''
  let finalContent = content.value
  if (topic.value.trim()) {
    const t = topic.value.trim().startsWith('#') ? topic.value.trim() : '#' + topic.value.trim()
    finalContent += '\n' + (t.endsWith('#') ? t : t + '#')
  }
  if (mentionInput.value.trim()) {
    finalContent += ' ' + mentionInput.value.trim()
  }

  const images = mediaItems.value.filter(m => m.type === 'image').map(m => m.url)
  const videoUrls = mediaItems.value.filter(m => m.type === 'video').map(m => m.url)

  try {
    let res
    if (isEditMode.value) {
      res = await api.put(`/posts/${editId.value}`, {
        content: finalContent,
        images: images.length > 0 ? images : null,
        videoUrls: videoUrls.length > 0 ? videoUrls : null,
      })
    } else {
      res = await api.post('/posts', {
        channelId: Number(channelId.value),
        content: finalContent,
        images: images.length > 0 ? images : null,
        videoUrls: videoUrls.length > 0 ? videoUrls : null,
      })
    }
    if (res.data.code === 200) {
      router.back()
    } else {
      error.value = res.data.message || (isEditMode.value ? '保存失败' : '发布失败')
    }
  } catch (e: any) {
    error.value = e.response?.data?.message || (isEditMode.value ? '保存失败' : '发布失败')
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  await fetchChannels()
  if (isEditMode.value) {
    try {
      const res = await api.get(`/posts/${editId.value}`)
      if (res.data.code === 200 && res.data.data) {
        const p = res.data.data
        content.value = p.content || ''
        topic.value = p.topic || ''
        if (p.channelId) channelId.value = String(p.channelId)
        if (p.images) {
          try {
            const imgs = typeof p.images === 'string' ? JSON.parse(p.images) : p.images
            if (Array.isArray(imgs)) {
              imgs.forEach((url: string) => {
                mediaItems.value.push({
                  type: 'image',
                  url: url.startsWith('http') || url.startsWith('/') ? url : '/uploads/images/' + url
                })
              })
            }
          } catch (_) {}
        }
        if (p.videoUrls) {
          try {
            const vids = typeof p.videoUrls === 'string' ? JSON.parse(p.videoUrls) : p.videoUrls
            if (Array.isArray(vids)) {
              vids.forEach((url: string) => {
                mediaItems.value.push({
                  type: 'video',
                  url: url.startsWith('http') || url.startsWith('/') ? url : '/uploads/videos/' + url
                })
              })
            }
          } catch (_) {}
        }
      }
    } catch (e) {}
  }
})

async function saveDraft() {
  if (!content.value.trim()) return
  savingDraft.value = true
  error.value = ''
  try {
    const res = await api.post('/drafts', {
      channelId: channelId.value ? Number(channelId.value) : null,
      content: content.value.trim(),
      images: mediaItems.value.length > 0 ? mediaItems.value.map(m => m.url).join(',') : null,
      topic: topic.value.trim() || null,
    })
    if (res.data.code === 200) {
      alert('草稿已保存')
      router.push('/drafts')
    } else {
      error.value = res.data.message || '保存失败'
    }
  } catch (e: any) {
    error.value = e.response?.data?.message || '保存失败'
  } finally {
    savingDraft.value = false
  }
}
</script>

<style scoped>
.create-post-page { max-width: 640px; margin: 0 auto; }
.create-post-card { padding: 32px; background: var(--surface); border: 1px solid var(--outline-variant); border-radius: 24px; }
.page-title { font-size: 24px; font-weight: 700; margin-bottom: 24px; }
.user-info-row { display: flex; align-items: center; gap: 10px; margin-bottom: 20px; padding-bottom: 16px; border-bottom: 1px solid var(--outline-variant); }
.user-avatar { width: 36px; height: 36px; border-radius: 10px; background: linear-gradient(135deg, var(--primary), var(--secondary)); display: flex; align-items: center; justify-content: center; font-size: 14px; font-weight: 700; color: #fff; overflow: hidden; }
.user-avatar img { width: 100%; height: 100%; object-fit: cover; }
.user-name { font-size: 14px; font-weight: 600; }
.post-form { display: flex; flex-direction: column; gap: 20px; }
.form-group { display: flex; flex-direction: column; gap: 8px; }
.form-group label { font-size: 14px; font-weight: 500; }
.form-group select, .form-group input, .form-group textarea {
  padding: 12px 16px; border: 1px solid var(--outline-variant); border-radius: 12px;
  background: rgba(255,255,255,0.03); color: var(--on-surface); font-size: 14px; outline: none;
  font-family: inherit;
}
.form-group select:focus, .form-group input:focus, .form-group textarea:focus { border-color: var(--primary); }
.form-group textarea { resize: vertical; min-height: 120px; }
.char-count, .media-count { text-align: right; font-size: 12px; color: var(--on-surface-variant); }
.media-upload-area { display: flex; flex-wrap: wrap; gap: 8px; }
.media-preview { position: relative; width: 80px; height: 80px; border-radius: 10px; overflow: hidden; }
.media-preview img, .media-preview .video-preview { width: 100%; height: 100%; object-fit: cover; }
.media-type-badge { position: absolute; bottom: 2px; left: 2px; background: rgba(0,0,0,0.6); color: #fff; font-size: 10px; padding: 1px 4px; border-radius: 4px; }
.remove-media { position: absolute; top: 2px; right: 2px; width: 20px; height: 20px; border-radius: 50%; border: none; background: rgba(0,0,0,0.5); color: #fff; font-size: 14px; cursor: pointer; display: flex; align-items: center; justify-content: center; }
.upload-btn { width: 80px; height: 80px; border: 2px dashed var(--outline-variant); border-radius: 10px; display: flex; align-items: center; justify-content: center; cursor: pointer; color: var(--on-surface-variant); transition: all 0.2s; }
.upload-btn:hover { border-color: var(--primary); color: var(--primary); }
.upload-progress { width: 100%; margin-top: 8px; }
.upload-progress .progress-bar { height: 6px; background: var(--outline-variant); border-radius: 3px; overflow: hidden; }
.upload-progress .progress-fill { height: 100%; background: linear-gradient(90deg, var(--primary), var(--secondary)); transition: width 0.3s ease; }
.upload-progress .progress-text { font-size: 12px; color: var(--on-surface-variant); margin-top: 4px; display: block; }
.error-msg { color: #ff6b6b; font-size: 13px; }
.form-actions { display: flex; gap: 12px; justify-content: flex-end; }
.btn { padding: 12px 28px; border-radius: 12px; border: none; font-size: 15px; font-weight: 600; cursor: pointer; transition: all 0.2s; }
.btn.cancel { background: var(--surface); border: 1px solid var(--outline-variant); color: var(--on-surface-variant); }
.btn.draft { background: var(--surface); border: 1px solid var(--primary); color: var(--primary); }
.btn.draft:disabled { opacity: 0.5; cursor: not-allowed; }
.btn.submit { background: linear-gradient(135deg, var(--primary), var(--secondary)); color: #fff; }
.btn.submit:disabled { opacity: 0.5; cursor: not-allowed; }
</style>
