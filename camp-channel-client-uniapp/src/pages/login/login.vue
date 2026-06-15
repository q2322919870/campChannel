<template>
  <view class="login-container">
    <view class="logo-area">
      <view class="logo-box">
        <text class="logo-text">CC</text>
      </view>
      <text class="app-title">Camp Channel</text>
      <text class="app-subtitle">广东机电职业技术学院专属校园频道</text>
    </view>

    <view class="form-card">
      <view class="form-item">
        <text class="label">学校认证邮箱</text>
        <view class="input-wrapper">
          <text class="input-icon">✉</text>
          <input 
            v-model="email" 
            type="text" 
            placeholder="请输入以 @stu.gdmec.edu.cn 结尾的邮箱" 
            class="input-box"
            placeholder-class="placeholder-style"
          />
        </view>
      </view>

      <view class="form-item">
        <text class="label">登录密码</text>
        <view class="input-wrapper">
          <text class="input-icon">🔒</text>
          <input 
            v-model="password" 
            type="password" 
            placeholder="请输入密码" 
            class="input-box"
            placeholder-class="placeholder-style"
          />
        </view>
      </view>

      <view v-if="errorMsg" class="error-area">
        <text class="error-text">{{ errorMsg }}</text>
      </view>

      <button :disabled="isLoading" class="btn-login" @tap="handleLogin">
        <text v-if="!isLoading">立即登录</text>
        <text v-else>正在认证中...</text>
      </button>

      <view class="register-link" @tap="goRegister">
        <text>还没有账号？</text>
        <text class="register-text">立即注册</text>
      </view>
    </view>

    <text class="agreement">登录即代表您同意并接受《用户使用许可协议》</text>
  </view>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { request } from '../../utils/request';
import { useAuthStore } from '../../stores/auth';

const email = ref('admin@stu.gdmec.edu.cn');
const password = ref('admin123');
const isLoading = ref(false);
const errorMsg = ref('');

const authStore = useAuthStore();

const goRegister = () => {
  uni.navigateTo({ url: '/pages/register/register' })
}

const handleLogin = async () => {
  errorMsg.value = '';

  if (!email.value.trim()) {
    errorMsg.value = '邮箱不能为空';
    return;
  }
  if (!email.value.trim().endsWith('@stu.gdmec.edu.cn')) {
    errorMsg.value = '邮箱后缀必须为 @stu.gdmec.edu.cn';
    return;
  }
  if (!password.value) {
    errorMsg.value = '密码不能为空';
    return;
  }

  isLoading.value = true;
  try {
    const res = await request({
      url: '/auth/login',
      method: 'POST',
      data: {
        email: email.value.trim(),
        password: password.value
      }
    });

    if (res && res.code === 200) {
      const data = res.data;
      // 保存至 Pinia Store & 本地缓存
      authStore.setAuth(data.token, {
        userId: data.userId,
        username: data.username,
        email: data.email,
        role: data.role,
        avatar: data.avatar
      });

      uni.showToast({
        title: '登录成功',
        icon: 'success'
      });

      setTimeout(() => {
        uni.reLaunch({
          url: '/pages/index/index'
        });
      }, 1000);
    } else {
      errorMsg.value = res.message || '登录失败，请检查账号密码';
    }
  } catch (err: any) {
    errorMsg.value = err.message || '网络连接故障，请检查后端运行状态';
  } finally {
    isLoading.value = false;
  }
};
</script>

<style>
.login-container {
  min-height: 100vh;
  background: var(--bg, #F3F4F8);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 0 48rpx;
  box-sizing: border-box;
}

.logo-area {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-bottom: 72rpx;
}

.logo-box {
  width: 128rpx;
  height: 128rpx;
  background: var(--primary-gradient, linear-gradient(135deg, #6366F1, #A855F7));
  border-radius: 36rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 16rpx 40rpx rgba(99, 102, 241, 0.3);
  margin-bottom: 28rpx;
}

.logo-text {
  font-size: 48rpx;
  font-weight: 800;
  color: #ffffff;
  letter-spacing: 2rpx;
}

.app-title {
  color: var(--text, #1A1D26);
  font-size: 48rpx;
  font-weight: 800;
  letter-spacing: 2rpx;
  margin-bottom: 12rpx;
}

.app-subtitle {
  color: var(--text-secondary, #6B7280);
  font-size: 26rpx;
}

.form-card {
  width: 100%;
  background: var(--card, #FFFFFF);
  border-radius: var(--radius-lg, 32rpx);
  padding: 48rpx;
  box-sizing: border-box;
  box-shadow: var(--shadow-lg, 0 8rpx 40rpx rgba(0, 0, 0, 0.08));
}

.form-item {
  margin-bottom: 32rpx;
}

.label {
  color: var(--text, #1A1D26);
  font-size: 26rpx;
  margin-bottom: 12rpx;
  display: block;
  font-weight: 600;
}

.input-wrapper {
  display: flex;
  align-items: center;
  width: 100%;
  height: 96rpx;
  background: var(--bg, #F3F4F8);
  border-radius: 20rpx;
  padding: 0 28rpx;
  box-sizing: border-box;
  border: 2rpx solid transparent;
  transition: border-color 0.2s ease;
}

.input-wrapper:focus-within {
  border-color: var(--primary, #6366F1);
}

.input-icon {
  font-size: 32rpx;
  margin-right: 16rpx;
  flex-shrink: 0;
}

.input-box {
  flex: 1;
  height: 100%;
  color: var(--text, #1A1D26);
  font-size: 28rpx;
  background: transparent;
}

.placeholder-style {
  color: var(--text-muted, #9CA3AF);
}

.error-area {
  padding: 16rpx 24rpx;
  background: rgba(239, 68, 68, 0.06);
  border-radius: 12rpx;
  margin-bottom: 20rpx;
}

.error-text {
  color: var(--danger, #EF4444);
  font-size: 24rpx;
}

.btn-login {
  width: 100%;
  height: 96rpx;
  background: var(--primary-gradient, linear-gradient(135deg, #6366F1, #A855F7));
  border-radius: 20rpx;
  color: #ffffff;
  font-size: 32rpx;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
  margin-top: 8rpx;
  box-shadow: 0 8rpx 24rpx rgba(99, 102, 241, 0.25);
}

.btn-login[disabled] {
  opacity: 0.6;
  box-shadow: none;
}

.btn-login::after {
  border: none;
}

.register-link {
  text-align: center;
  margin-top: 32rpx;
  color: var(--text-secondary, #6B7280);
  font-size: 26rpx;
}

.register-text {
  color: var(--primary, #6366F1);
  font-weight: 600;
}

.agreement {
  color: var(--text-muted, #9CA3AF);
  font-size: 22rpx;
  margin-top: 48rpx;
  text-align: center;
}
</style>
