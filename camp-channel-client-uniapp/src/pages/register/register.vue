<template>
  <view class="register-container">
    <view class="register-card">
      <view class="form-item">
        <text class="label">学校认证邮箱</text>
        <input
          v-model="email"
          type="text"
          placeholder="请输入 @stu.gdmec.edu.cn 邮箱"
          class="input-box"
          placeholder-class="ph"
        />
      </view>

      <view class="form-item code-row">
        <view class="code-input-wrapper">
          <text class="label">邮箱验证码</text>
          <input
            v-model="code"
            type="text"
            placeholder="输入验证码"
            class="input-box code-input"
            placeholder-class="ph"
          />
        </view>
        <button :disabled="codeSending || codeCountdown > 0" class="btn-code" @tap="sendCode">
          {{ codeCountdown > 0 ? `${codeCountdown}s` : codeSending ? '发送中...' : '获取验证码' }}
        </button>
      </view>

      <view class="form-item">
        <text class="label">用户名</text>
        <input
          v-model="username"
          type="text"
          placeholder="请输入昵称"
          class="input-box"
          placeholder-class="ph"
        />
      </view>

      <view class="form-item">
        <text class="label">密码</text>
        <input
          v-model="password"
          type="password"
          placeholder="至少6位密码"
          class="input-box"
          placeholder-class="ph"
        />
      </view>

      <view class="form-item">
        <text class="label">确认密码</text>
        <input
          v-model="confirmPwd"
          type="password"
          placeholder="再次输入密码"
          class="input-box"
          placeholder-class="ph"
        />
      </view>

      <view v-if="errorMsg" class="error-area">
        <text class="error-text">{{ errorMsg }}</text>
      </view>

      <button :disabled="loading" class="btn-primary" @tap="handleRegister">
        {{ loading ? '注册中...' : '注册' }}
      </button>

      <view class="login-link" @tap="goLogin">
        <text>已有账号？去登录</text>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { request } from '../../utils/request'

const email = ref('')
const code = ref('')
const username = ref('')
const password = ref('')
const confirmPwd = ref('')
const loading = ref(false)
const codeSending = ref(false)
const codeCountdown = ref(0)
const errorMsg = ref('')

let countdownTimer: any = null

function goLogin() {
  uni.navigateTo({ url: '/pages/login/login' })
}

async function sendCode() {
  if (!email.value.trim() || !email.value.trim().endsWith('@stu.gdmec.edu.cn')) {
    errorMsg.value = '请输入正确的学校邮箱'
    return
  }
  errorMsg.value = ''
  codeSending.value = true
  try {
    const res = await request<any>({
      url: '/auth/send-code',
      method: 'POST',
      data: { email: email.value.trim() },
    })
    if (res?.code === 200) {
      uni.showToast({ title: '验证码已发送', icon: 'success' })
      codeCountdown.value = 60
      countdownTimer = setInterval(() => {
        codeCountdown.value--
        if (codeCountdown.value <= 0) {
          clearInterval(countdownTimer)
        }
      }, 1000)
    } else {
      errorMsg.value = res?.message || '发送失败'
    }
  } catch (err: any) {
    errorMsg.value = err.message || '发送失败'
  } finally {
    codeSending.value = false
  }
}

const handleRegister = async () => {
  errorMsg.value = ''
  if (!email.value.trim() || !username.value.trim() || !password.value || !code.value.trim()) {
    errorMsg.value = '请填写完整信息'
    return
  }
  if (!email.value.trim().endsWith('@stu.gdmec.edu.cn')) {
    errorMsg.value = '邮箱后缀必须为 @stu.gdmec.edu.cn'
    return
  }
  if (password.value.length < 6) {
    errorMsg.value = '密码至少6位'
    return
  }
  if (password.value !== confirmPwd.value) {
    errorMsg.value = '两次密码不一致'
    return
  }

  loading.value = true
  try {
    const res = await request<any>({
      url: '/auth/register',
      method: 'POST',
      data: {
        email: email.value.trim(),
        username: username.value.trim(),
        password: password.value,
        code: code.value.trim(),
      },
    })
    if (res?.code === 200) {
      uni.showToast({ title: '注册成功', icon: 'success' })
      setTimeout(() => uni.navigateTo({ url: '/pages/login/login' }), 1000)
    } else {
      errorMsg.value = res?.message || '注册失败'
    }
  } catch (err: any) {
    errorMsg.value = err.message || '网络错误'
  } finally {
    loading.value = false
  }
}
</script>

<style>
.register-container {
  min-height: 100vh;
  background-color: var(--bg);
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 60rpx 40rpx;
  box-sizing: border-box;
}

.register-card {
  width: 100%;
  background-color: var(--card);
  border-radius: 36rpx;
  padding: 48rpx;
  box-sizing: border-box;
  border: 1px solid var(--card-border);
}

.form-item {
  margin-bottom: 36rpx;
}

.code-row {
  display: flex;
  gap: 20rpx;
  align-items: flex-end;
}

.code-input-wrapper {
  flex: 1;
}

.code-input {
  width: 100%;
}

.btn-code {
  height: 90rpx;
  padding: 0 24rpx;
  background: linear-gradient(135deg, var(--primary), var(--primary));
  border-radius: 20rpx;
  color: #ffffff;
  font-size: 24rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
  white-space: nowrap;
  flex-shrink: 0;
}

.btn-code::after {
  border: none;
}

.label {
  color: var(--text);
  font-size: 28rpx;
  margin-bottom: 16rpx;
  display: block;
  font-weight: 500;
}

.input-box {
  width: 100%;
  height: 90rpx;
  background-color: var(--bg);
  border-radius: 20rpx;
  padding: 0 30rpx;
  box-sizing: border-box;
  color: var(--text);
  font-size: 28rpx;
  border: 1px solid var(--card-border);
}

.ph {
  color: var(--text-muted);
}

.error-area {
  margin-bottom: 24rpx;
}

.error-text {
  color: var(--danger);
  font-size: 24rpx;
}

.btn-primary {
  width: 100%;
  height: 96rpx;
  background: linear-gradient(135deg, var(--primary), var(--primary));
  border-radius: 20rpx;
  color: #ffffff;
  font-size: 32rpx;
  font-weight: bold;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
  margin-top: 12rpx;
}

.btn-primary::after {
  border: none;
}

.login-link {
  text-align: center;
  margin-top: 40rpx;
  color: var(--primary);
  font-size: 26rpx;
}
</style>
