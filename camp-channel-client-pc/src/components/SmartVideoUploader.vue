<template>
  <div class="smart-video-uploader">
    <input
      ref="fileInput"
      type="file"
      accept="video/*"
      class="hidden"
      @change="onFileSelected"
    />

    <!-- 上传按钮 -->
    <button
      v-if="status === 'idle' || status === 'success' || status === 'error'"
      class="upload-btn"
      @click="triggerSelect"
      :disabled="disabled"
    >
      <slot>
        <span class="icon">📹</span>
        <span>{{ status === 'success' ? '上传成功' : status === 'error' ? '重试' : '选择视频' }}</span>
      </slot>
    </button>

    <!-- 进度条 -->
    <div v-if="isUploading" class="progress-container">
      <div class="progress-bar">
        <div
          class="progress-fill"
          :style="{ width: progress + '%' }"
        ></div>
      </div>
      <div class="progress-text">
        <span class="status-label">{{ statusText }}</span>
        <span class="progress-percent">{{ progress }}%</span>
      </div>
    </div>

    <!-- 错误提示 -->
    <div v-if="status === 'error' && errorMsg" class="error-msg">
      {{ errorMsg }}
    </div>

    <!-- 秒传提示 -->
    <div v-if="isDuplicated" class="success-msg">
      视频已存在，秒传成功！
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useVideoUploader } from '../composables/useVideoUploader'

const props = defineProps<{
  disabled?: boolean
  onUploaded?: (url: string) => void
}>()

const emit = defineEmits<{
  (e: 'uploaded', url: string): void
  (e: 'error', msg: string): void
}>()

const fileInput = ref<HTMLInputElement | null>(null)

const {
  status,
  progress,
  errorMsg,
  videoUrl,
  isDuplicated,
  isUploading,
  uploadVideo,
  reset,
} = useVideoUploader({
  onUploaded: (url) => {
    emit('uploaded', url)
  },
})

const statusText = computed(() => {
  const map: Record<string, string> = {
    idle: '',
    hashing: '正在计算文件指纹...',
    checking: '正在检查秒传...',
    uploading: '正在上传...',
    success: '上传成功',
    error: '上传失败',
  }
  return map[status.value] || ''
})

function triggerSelect() {
  if (status.value === 'error') {
    reset()
  }
  fileInput.value?.click()
}

async function onFileSelected(e: Event) {
  const input = e.target as HTMLInputElement
  if (!input.files?.length) return
  const file = input.files[0]
  const result = await uploadVideo(file)
  if (!result) {
    emit('error', errorMsg.value)
  }
  input.value = ''
}
</script>

<style scoped>
.smart-video-uploader {
  display: inline-block;
}

.hidden {
  display: none;
}

.upload-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 8px 16px;
  background: #409eff;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 14px;
  transition: background 0.2s;
}

.upload-btn:hover:not(:disabled) {
  background: #66b1ff;
}

.upload-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.icon {
  font-size: 16px;
}

.progress-container {
  width: 100%;
  min-width: 200px;
}

.progress-bar {
  height: 8px;
  background: #ebeef5;
  border-radius: 4px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: #409eff;
  transition: width 0.3s ease;
}

.progress-text {
  display: flex;
  justify-content: space-between;
  margin-top: 4px;
  font-size: 12px;
  color: #606266;
}

.error-msg {
  color: #f56c6c;
  font-size: 12px;
  margin-top: 4px;
}

.success-msg {
  color: #67c23a;
  font-size: 12px;
  margin-top: 4px;
}
</style>
