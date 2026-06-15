<template>
  <view class="create-post-page">
    <scroll-view scroll-y class="page-content">
      <view class="create-post-card">
        <text class="page-title">{{ editId ? '编辑帖子' : '发布帖子' }}</text>

        <view class="user-info-row">
          <view class="user-avatar">
            <image v-if="currentUser?.avatar" :src="currentUser.avatar" mode="aspectFill" class="avatar-img" />
            <text v-else>{{ (currentUser?.username || '?').charAt(0) }}</text>
          </view>
          <text class="user-name">{{ currentUser?.username || '未知用户' }}</text>
        </view>
        
        <view class="post-form">
          <view class="form-group">
            <text class="form-label">选择频道 *</text>
            <picker 
              mode="selector" 
              :range="channels" 
              range-key="name"
              :value="channelIndex"
              @change="onChannelChange"
            >
              <view class="picker-value">
                <text v-if="channelId">{{ channels[channelIndex]?.name || '请选择频道' }}</text>
                <text v-else class="placeholder">请选择频道</text>
              </view>
            </picker>
          </view>

          <view class="form-group">
            <text class="form-label">内容 *</text>
            <textarea 
              v-model="content" 
              placeholder="写点什么..." 
              maxlength="2000"
              class="content-textarea"
            />
            <text class="char-count">{{ content.length }}/2000</text>
          </view>

          <view class="form-group">
            <text class="form-label">图片（选填，最多9张）</text>
            <view class="image-upload-area">
              <view v-for="(url, i) in images" :key="i" class="image-preview">
                <image :src="url" mode="aspectFill" class="preview-img" />
                <view class="remove-img" @tap="removeImage(i)">×</view>
              </view>
              <view v-if="images.length < 9" class="upload-btn" @tap="chooseImages">
                <text class="upload-icon">+</text>
              </view>
            </view>
          </view>

          <view class="form-group">
            <text class="form-label">话题（选填，格式 #话题#）</text>
            <input 
              v-model="topic" 
              placeholder="#话题名称#" 
              class="form-input"
            />
          </view>

          <view v-if="error" class="error-msg">
            <text>{{ error }}</text>
          </view>

          <view class="form-actions">
            <button class="btn cancel" @tap="goBack">取消</button>
            <button 
              class="btn submit" 
              :disabled="loading || !channelId || !content.trim()"
              @tap="handleSubmit"
            >
              {{ loading ? (editId ? '更新中...' : '发布中...') : (editId ? '更新' : '发布') }}
            </button>
          </view>
        </view>
      </view>
    </scroll-view>
  </view>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '../../stores/auth'
import request, { BASE_URL } from '../../utils/request'

const authStore = useAuthStore()
const currentUser = computed(() => authStore.userInfo)

interface Channel {
  id: number
  name: string
}

const channels = ref<Channel[]>([])
const channelIndex = ref(0)
const channelId = ref<number | null>(null)
const content = ref('')
const images = ref<string[]>([])
const topic = ref('')
const loading = ref(false)
const error = ref('')
const editId = ref<number | null>(null)

onMounted(() => {
  if (!authStore.token) {
    uni.reLaunch({ url: '/pages/login/login' })
    return
  }
  // Check for edit mode
  const pages = getCurrentPages()
  const page = pages[pages.length - 1] as any
  const editParam = page?.options?.editId
  if (editParam) {
    editId.value = parseInt(editParam)
    loadPostForEdit(editId.value)
  }
  fetchChannels()
})

async function fetchChannels() {
  try {
    const res = await request<any>('/channels/my')
    if (res?.code === 200 && Array.isArray(res.data)) {
      channels.value = res.data
      // If in edit mode and channelId already set, find the right index
      if (editId.value && channelId.value) {
        const idx = channels.value.findIndex((c: Channel) => c.id === channelId.value)
        if (idx >= 0) channelIndex.value = idx
      }
    }
  } catch (_) {}
}

async function loadPostForEdit(id: number) {
  try {
    const res = await request<any>(`/posts/${id}`)
    if (res?.code === 200 && res.data) {
      const p = res.data
      content.value = p.content || ''
      channelId.value = p.channelId
      // Parse images
      if (p.images) {
        if (Array.isArray(p.images)) {
          images.value = p.images
        } else if (typeof p.images === 'string') {
          try {
            const parsed = JSON.parse(p.images)
            if (Array.isArray(parsed)) images.value = parsed
          } catch (_) {}
        }
      }
      // Extract topic from content
      const topicMatch = (p.content || '').match(/#([^#]+)#/)
      if (topicMatch) {
        topic.value = topicMatch[1]
        content.value = content.value.replace(/#[^#]+#/, '').trim()
      }
    }
  } catch (_) {
    uni.showToast({ title: '加载帖子失败', icon: 'none' })
  }
}

function onChannelChange(e: any) {
  channelIndex.value = e.detail.value
  channelId.value = channels.value[channelIndex.value]?.id || null
}

async function chooseImages() {
  uni.chooseImage({
    count: 9 - images.value.length,
    sizeType: ['compressed'],
    sourceType: ['album', 'camera'],
    success: async (res) => {
      for (const tempFilePath of res.tempFilePaths) {
        await uploadImage(tempFilePath)
      }
    },
  })
}

async function uploadImage(filePath: string) {
  try {
    uni.showLoading({ title: '上传中...' })
    
    const res = await new Promise((resolve, reject) => {
      uni.uploadFile({
        url: `${BASE_URL}/upload/image`,
        filePath: filePath,
        name: 'file',
        header: {
          'Authorization': `Bearer ${authStore.token}`,
        },
        success: (uploadRes) => {
          try {
            const data = JSON.parse(uploadRes.data)
            resolve(data)
          } catch (e) {
            reject(e)
          }
        },
        fail: reject,
      })
    }) as any
    
    if (res.code === 200 && res.data?.url) {
      if (images.value.length < 9) {
        images.value.push(res.data.url)
      }
    }
  } catch (_) {
    uni.showToast({ title: '图片上传失败', icon: 'none' })
  } finally {
    uni.hideLoading()
  }
}

function removeImage(index: number) {
  images.value.splice(index, 1)
}

async function handleSubmit() {
  if (!channelId.value || !content.value.trim()) {
    uni.showToast({ title: '请填写必填项', icon: 'none' })
    return
  }
  
  loading.value = true
  error.value = ''
  
  let finalContent = content.value
  if (topic.value.trim()) {
    const t = topic.value.trim().startsWith('#') ? topic.value.trim() : '#' + topic.value.trim()
    finalContent += '\n' + (t.endsWith('#') ? t : t + '#')
  }
  
  try {
    const url = editId.value ? `/posts/${editId.value}` : '/posts'
    const method = editId.value ? 'PUT' : 'POST'
    const res = await request<any>({
      url,
      method,
      data: {
        channelId: channelId.value,
        content: finalContent,
        images: images.value.length > 0 ? images.value : null,
        videoUrls: null,
      },
    })
    
    if (res?.code === 200) {
      uni.showToast({ title: editId.value ? '更新成功' : '发布成功', icon: 'success' })
      setTimeout(() => {
        uni.navigateBack()
      }, 1500)
    } else {
      error.value = res.message || '发布失败'
    }
  } catch (e: any) {
    error.value = e.message || '发布失败'
  } finally {
    loading.value = false
  }
}

function goBack() {
  uni.navigateBack()
}
</script>

<style scoped>
.create-post-page {
  min-height: 100vh;
  background-color: var(--bg);
}

.page-content {
  height: 100vh;
}

.create-post-card {
  padding: 32rpx;
  background: var(--card);
}

.page-title {
  font-size: 40rpx;
  font-weight: 700;
  color: var(--text);
  margin-bottom: 24rpx;
  display: block;
}

.user-info-row {
  display: flex;
  align-items: center;
  gap: 16rpx;
  margin-bottom: 32rpx;
  padding-bottom: 24rpx;
  border-bottom: 1rpx solid var(--card-border);
}

.user-avatar {
  width: 72rpx;
  height: 72rpx;
  border-radius: 16rpx;
  background: linear-gradient(135deg, var(--primary), var(--accent));
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28rpx;
  font-weight: 700;
  color: #fff;
  overflow: hidden;
}

.avatar-img {
  width: 100%;
  height: 100%;
}

.user-name {
  font-size: 28rpx;
  font-weight: 600;
  color: var(--text);
}

.post-form {
  display: flex;
  flex-direction: column;
  gap: 24rpx;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 12rpx;
}

.form-label {
  font-size: 28rpx;
  font-weight: 600;
  color: var(--text);
}

.picker-value {
  padding: 20rpx 24rpx;
  background: var(--bg);
  border: 1rpx solid var(--card-border);
  border-radius: 12rpx;
  font-size: 28rpx;
  color: var(--text);
}

.placeholder {
  color: var(--text-muted);
}

.content-textarea {
  padding: 20rpx 24rpx;
  background: var(--bg);
  border: 1rpx solid var(--card-border);
  border-radius: 12rpx;
  font-size: 28rpx;
  min-height: 200rpx;
  color: var(--text);
}

.char-count {
  font-size: 24rpx;
  color: var(--text-muted);
  text-align: right;
}

.image-upload-area {
  display: flex;
  flex-wrap: wrap;
  gap: 12rpx;
}

.image-preview {
  position: relative;
  width: 160rpx;
  height: 160rpx;
  border-radius: 12rpx;
  overflow: hidden;
}

.preview-img {
  width: 100%;
  height: 100%;
}

.remove-img {
  position: absolute;
  top: 4rpx;
  right: 4rpx;
  width: 40rpx;
  height: 40rpx;
  background: rgba(0, 0, 0, 0.6);
  color: #ffffff;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 32rpx;
  line-height: 1;
}

.upload-btn {
  width: 160rpx;
  height: 160rpx;
  border: 2rpx dashed var(--card-border);
  border-radius: 12rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--bg);
}

.upload-icon {
  font-size: 64rpx;
  color: var(--text-muted);
  font-weight: 300;
}

.form-input {
  padding: 20rpx 24rpx;
  background: var(--bg);
  border: 1rpx solid var(--card-border);
  border-radius: 12rpx;
  font-size: 28rpx;
  color: var(--text);
}

.error-msg {
  padding: 16rpx 24rpx;
  background: rgba(255, 107, 107, 0.1);
  border: 1rpx solid rgba(255, 107, 107, 0.3);
  border-radius: 12rpx;
  color: #ff6b6b;
  font-size: 26rpx;
}

.form-actions {
  display: flex;
  gap: 16rpx;
  margin-top: 16rpx;
}

.btn {
  flex: 1;
  padding: 24rpx;
  border-radius: 12rpx;
  font-size: 28rpx;
  font-weight: 600;
  border: none;
}

.btn.cancel {
  background: var(--bg);
  color: var(--text);
  border: 1rpx solid var(--card-border);
}

.btn.submit {
  background: linear-gradient(135deg, var(--primary), var(--accent));
  color: #ffffff;
}

.btn.submit[disabled] {
  opacity: 0.5;
}
</style>
