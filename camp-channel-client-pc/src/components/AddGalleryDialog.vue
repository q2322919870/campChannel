<template>
  <div v-if="visible" class="dialog-overlay" @click.self="$emit('close')">
    <div class="dialog-card">
      <h3>添加画作到画廊</h3>
      <div class="upload-area" @click="triggerUpload">
        <img v-if="previewUrl" :src="previewUrl" class="preview-img" />
        <div v-else class="upload-placeholder">
          <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><path d="M21 15l-5-5L5 21"/></svg>
          <span>点击上传图片</span>
        </div>
        <input ref="fileInput" type="file" accept="image/*" hidden @change="onFileSelected" />
      </div>
      <input v-model="title" placeholder="画作标题（选填）" class="gallery-input" />
      <textarea v-model="description" placeholder="画作描述（选填）" rows="3" class="gallery-textarea"></textarea>
      <p v-if="error" class="error-msg">{{ error }}</p>
      <div class="dialog-actions">
        <button class="btn-cancel" @click="$emit('close')">取消</button>
        <button class="btn-submit" :disabled="!imageUrl || submitting" @click="submit">{{ submitting ? '上传中...' : '发布' }}</button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { api } from '../api/client'

defineProps<{ visible: boolean }>()
const emit = defineEmits<{ close: []; added: [] }>()

const fileInput = ref<HTMLInputElement>()
const previewUrl = ref('')
const imageUrl = ref('')
const title = ref('')
const description = ref('')
const submitting = ref(false)
const error = ref('')

function triggerUpload() { fileInput.value?.click() }

async function onFileSelected(e: Event) {
  const input = e.target as HTMLInputElement
  if (!input.files?.length) return
  const file = input.files[0]
  if (file.size > 10 * 1024 * 1024) { error.value = '图片不能超过10MB'; return }
  const formData = new FormData()
  formData.append('file', file)
  try {
    const res = await api.post('/upload/image', formData, { headers: { 'Content-Type': 'multipart/form-data' } })
    if (res.data.code === 200 && res.data.data?.url) {
      previewUrl.value = res.data.data.url
      imageUrl.value = res.data.data.url
      error.value = ''
    } else {
      error.value = res.data.message || '上传失败'
    }
  } catch (e: any) { error.value = e.response?.data?.message || '上传失败' }
  input.value = ''
}

async function submit() {
  if (!imageUrl.value) { error.value = '请先上传图片'; return }
  submitting.value = true
  error.value = ''
  try {
    const res = await api.post('/gallery', { 
      imageUrl: imageUrl.value, 
      title: title.value, 
      description: description.value,
      channelId: 0
    })
    if (res.data.code === 200) {
      emit('added')
      emit('close')
    } else { error.value = res.data.message || '发布失败' }
  } catch (e: any) { error.value = e.response?.data?.message || '发布失败' }
  finally { submitting.value = false }
}
</script>

<style scoped>
.dialog-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.6); display: flex; align-items: center; justify-content: center; z-index: 2000; }
.dialog-card { background: var(--surface); border: 1px solid var(--outline-variant); border-radius: 20px; padding: 28px; width: 440px; max-width: 90vw; max-height: 90vh; overflow-y: auto; }
.dialog-card h3 { font-size: 18px; font-weight: 700; margin-bottom: 20px; }
.upload-area { width: 100%; height: 200px; border: 2px dashed var(--outline-variant); border-radius: 16px; display: flex; align-items: center; justify-content: center; cursor: pointer; margin-bottom: 16px; overflow: hidden; transition: border-color 0.2s; }
.upload-area:hover { border-color: var(--primary); }
.upload-placeholder { display: flex; flex-direction: column; align-items: center; gap: 8px; color: var(--on-surface-variant); font-size: 14px; }
.preview-img { width: 100%; height: 100%; object-fit: cover; }
.gallery-input, .gallery-textarea { width: 100%; padding: 12px 16px; border: 1px solid var(--outline-variant); border-radius: 12px; background: rgba(255,255,255,0.03); color: var(--on-surface); font-size: 14px; outline: none; margin-bottom: 12px; box-sizing: border-box; }
.gallery-input:focus, .gallery-textarea:focus { border-color: var(--primary); }
.gallery-textarea { resize: vertical; font-family: inherit; }
.error-msg { color: #ff6b6b; font-size: 13px; margin-bottom: 12px; }
.dialog-actions { display: flex; gap: 12px; justify-content: flex-end; }
.btn-cancel, .btn-submit { padding: 10px 24px; border-radius: 10px; font-size: 14px; font-weight: 600; cursor: pointer; }
.btn-cancel { border: 1px solid var(--outline-variant); background: var(--surface); color: var(--on-surface-variant); }
.btn-submit { border: none; background: linear-gradient(135deg, var(--primary), var(--secondary)); color: #fff; }
.btn-submit:disabled { opacity: 0.5; cursor: default; }
</style>
