<template>
  <view class="edit-profile-page">
    <view class="page-header">
      <text class="page-title">编辑资料</text>
    </view>

    <view class="form-section">
      <view class="form-item">
        <text class="form-label">用户名</text>
        <input
          v-model="formData.username"
          type="text"
          placeholder="请输入用户名"
          class="form-input"
          maxlength="20"
        />
        <text class="char-count">{{ formData.username.length }}/20</text>
      </view>

      <view class="form-item">
        <text class="form-label">手机号</text>
        <input
          v-model="formData.phone"
          type="tel"
          placeholder="请输入手机号"
          class="form-input"
          maxlength="11"
        />
      </view>

      <view class="form-item">
        <text class="form-label">个人简介</text>
        <textarea
          v-model="formData.bio"
          placeholder="介绍一下自己吧..."
          class="form-textarea"
          maxlength="200"
        />
        <text class="char-count">{{ formData.bio.length }}/200</text>
      </view>
    </view>

    <view class="action-buttons">
      <button class="btn-save" :disabled="saving" @tap="saveProfile">
        {{ saving ? '保存中...' : '保存' }}
      </button>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import request from '../../utils/request'

const formData = ref({
  username: '',
  phone: '',
  bio: '',
})

const saving = ref(false)

onMounted(() => {
  loadProfile()
})

async function loadProfile() {
  try {
    const res = await request<any>('/users/me')
    if (res?.code === 200 && res.data) {
      formData.value.username = res.data.username || ''
      formData.value.phone = res.data.phone || ''
      formData.value.bio = res.data.bio || ''
    }
  } catch (error) {
    uni.showToast({ title: '加载失败', icon: 'none' })
  }
}

async function saveProfile() {
  if (!formData.value.username.trim()) {
    uni.showToast({ title: '用户名不能为空', icon: 'none' })
    return
  }

  if (formData.value.phone && !/^1[3-9]\d{9}$/.test(formData.value.phone)) {
    uni.showToast({ title: '手机号格式不正确', icon: 'none' })
    return
  }

  saving.value = true
  try {
    const res = await request<any>({
      url: '/users/profile',
      method: 'PUT',
      data: {
        username: formData.value.username,
        phone: formData.value.phone,
        bio: formData.value.bio,
      },
    })

    if (res?.code === 200) {
      uni.showToast({ title: '保存成功', icon: 'success' })
      setTimeout(() => {
        uni.navigateBack()
      }, 1500)
    } else {
      uni.showToast({ title: res?.message || '保存失败', icon: 'none' })
    }
  } catch (error) {
    uni.showToast({ title: '保存失败', icon: 'none' })
  } finally {
    saving.value = false
  }
}
</script>

<style scoped>
.edit-profile-page {
  min-height: 100vh;
  background: var(--bg);
  padding: 32rpx;
}

.page-header {
  background: var(--card);
  border: 1rpx solid var(--card-border);
  border-radius: var(--radius-lg);
  padding: 32rpx;
  margin-bottom: 24rpx;
  box-shadow: var(--shadow);
}

.page-title {
  font-size: 40rpx;
  font-weight: 700;
  color: var(--text);
  display: block;
}

.form-section {
  background: var(--card);
  border: 1rpx solid var(--card-border);
  border-radius: var(--radius-lg);
  padding: 32rpx;
  margin-bottom: 24rpx;
  box-shadow: var(--shadow);
}

.form-item {
  margin-bottom: 32rpx;
  position: relative;
}

.form-item:last-child {
  margin-bottom: 0;
}

.form-label {
  font-size: 28rpx;
  font-weight: 600;
  color: var(--text);
  display: block;
  margin-bottom: 12rpx;
}

.form-input {
  width: 100%;
  height: 88rpx;
  padding: 0 24rpx;
  background: var(--bg);
  border: 1rpx solid var(--card-border);
  border-radius: 16rpx;
  font-size: 28rpx;
  color: var(--text);
}

.form-textarea {
  width: 100%;
  min-height: 200rpx;
  padding: 20rpx 24rpx;
  background: var(--bg);
  border: 1rpx solid var(--card-border);
  border-radius: 16rpx;
  font-size: 28rpx;
  color: var(--text);
  resize: none;
}

.char-count {
  position: absolute;
  right: 24rpx;
  bottom: 12rpx;
  font-size: 22rpx;
  color: var(--text-muted);
}

.action-buttons {
  margin-top: 32rpx;
}

.btn-save {
  width: 100%;
  height: 88rpx;
  background: var(--primary-gradient);
  border-radius: 44rpx;
  color: #ffffff;
  font-size: 30rpx;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
  box-shadow: 0 8rpx 24rpx rgba(99, 102, 241, 0.25);
}

.btn-save[disabled] {
  opacity: 0.5;
}
</style>
