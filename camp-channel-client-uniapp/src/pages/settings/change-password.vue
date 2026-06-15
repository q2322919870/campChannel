<template>
  <view class="change-password-page">
    <view class="form-card">
      <text class="page-title">修改密码</text>

      <view class="form-group">
        <text class="form-label">当前密码</text>
        <input
          v-model="oldPassword"
          type="text"
          password
          placeholder="请输入当前密码"
          class="form-input"
        />
      </view>

      <view class="form-group">
        <text class="form-label">新密码</text>
        <input
          v-model="newPassword"
          type="text"
          password
          placeholder="8-20位，需包含字母和数字"
          class="form-input"
        />
      </view>

      <view class="form-group">
        <text class="form-label">确认新密码</text>
        <input
          v-model="confirmPassword"
          type="text"
          password
          placeholder="再次输入新密码"
          class="form-input"
        />
      </view>

      <view v-if="error" class="error-msg">
        <text>{{ error }}</text>
      </view>

      <button
        class="btn-submit"
        :disabled="loading || !oldPassword || !newPassword || !confirmPassword"
        @tap="handleSubmit"
      >
        {{ loading ? '提交中...' : '确认修改' }}
      </button>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import request from '../../utils/request'

const oldPassword = ref('')
const newPassword = ref('')
const confirmPassword = ref('')
const loading = ref(false)
const error = ref('')

async function handleSubmit() {
  error.value = ''

  if (!oldPassword.value || !newPassword.value || !confirmPassword.value) {
    error.value = '请填写所有字段'
    return
  }

  if (newPassword.value.length < 8 || newPassword.value.length > 20) {
    error.value = '密码长度需为8-20位'
    return
  }

  const hasLetter = /[a-zA-Z]/.test(newPassword.value)
  const hasDigit = /\d/.test(newPassword.value)
  if (!hasLetter || !hasDigit) {
    error.value = '密码需包含字母和数字'
    return
  }

  if (newPassword.value !== confirmPassword.value) {
    error.value = '两次输入的密码不一致'
    return
  }

  loading.value = true
  try {
    const res = await request<any>({
      url: '/users/password',
      method: 'PUT',
      data: {
        oldPassword: oldPassword.value,
        newPassword: newPassword.value,
      },
    })
    if (res?.code === 200) {
      uni.showToast({ title: '密码修改成功', icon: 'success' })
      setTimeout(() => {
        uni.navigateBack()
      }, 1500)
    } else {
      error.value = res?.message || '修改失败，请检查当前密码是否正确'
    }
  } catch (e: any) {
    error.value = e.message || '修改失败'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.change-password-page {
  min-height: 100vh;
  background: var(--bg);
  padding: 32rpx;
}

.form-card {
  background: var(--card);
  border: 1rpx solid var(--card-border);
  border-radius: var(--radius-lg);
  padding: 40rpx 32rpx;
  box-shadow: var(--shadow);
}

.page-title {
  font-size: 40rpx;
  font-weight: 700;
  color: var(--text);
  display: block;
  margin-bottom: 40rpx;
}

.form-group {
  margin-bottom: 28rpx;
}

.form-label {
  font-size: 26rpx;
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

.error-msg {
  padding: 16rpx 24rpx;
  background: rgba(255, 107, 107, 0.1);
  border: 1rpx solid rgba(255, 107, 107, 0.3);
  border-radius: 12rpx;
  color: #ff6b6b;
  font-size: 26rpx;
  margin-bottom: 24rpx;
}

.btn-submit {
  width: 100%;
  height: 88rpx;
  background: linear-gradient(135deg, var(--primary), var(--accent));
  border-radius: 44rpx;
  color: #ffffff;
  font-size: 30rpx;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
  margin-top: 16rpx;
  box-shadow: 0 8rpx 24rpx rgba(99, 102, 241, 0.25);
}

.btn-submit[disabled] {
  opacity: 0.5;
}
</style>
