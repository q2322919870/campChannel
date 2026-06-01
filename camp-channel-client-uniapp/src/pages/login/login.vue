<template>
  <view class="login-container">
    <view class="logo-area">
      <view class="logo-box">
        <text class="logo-icon">🏫</text>
      </view>
      <text class="app-title">Camp Channel</text>
      <text class="app-subtitle">广东机电职业技术学院专属校园频道</text>
    </view>

    <view class="form-card">
      <view class="form-item">
        <text class="label">学校认证邮箱</text>
        <input 
          v-model="email" 
          type="text" 
          placeholder="请输入以 @stu.gdmec.edu.cn 结尾的邮箱" 
          class="input-box"
          placeholder-class="placeholder-style"
        />
      </view>

      <view class="form-item">
        <text class="label">登录密码</text>
        <input 
          v-model="password" 
          type="password" 
          placeholder="请输入密码" 
          class="input-box"
          placeholder-class="placeholder-style"
        />
      </view>

      <view v-if="errorMsg" class="error-area">
        <text class="error-icon">⚠️</text>
        <text class="error-text">{{ errorMsg }}</text>
      </view>

      <button :disabled="isLoading" class="btn-login" @tap="handleLogin">
        <text v-if="!isLoading">立即登录</text>
        <text v-else>正在认证中...</text>
      </button>

      <view class="register-link" @tap="goRegister">
        <text>还没有账号？立即注册</text>
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
  background: linear-gradient(135deg, #0F1923 0%, #1a2a3a 50%, #2d3748 100%);
  background-attachment: fixed;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 0 40rpx;
  box-sizing: border-box;
  position: relative;
}

.login-container::before {
  content: '';
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: 
    radial-gradient(circle at 20% 50%, rgba(124, 159, 203, 0.15) 0%, transparent 50%),
    radial-gradient(circle at 80% 80%, rgba(242, 181, 212, 0.12) 0%, transparent 50%),
    radial-gradient(circle at 40% 20%, rgba(124, 159, 203, 0.1) 0%, transparent 50%);
  z-index: 0;
  pointer-events: none;
}

.logo-area {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-bottom: 60rpx;
  position: relative;
  z-index: 1;
}

.logo-box {
  width: 140rpx;
  height: 140rpx;
  background: linear-gradient(135deg, #7C9FCB, #F2B5D4);
  border-radius: 40rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 16rpx 32rpx rgba(124, 159, 203, 0.3);
  margin-bottom: 30rpx;
}

.logo-icon {
  font-size: 70rpx;
}

.app-title {
  color: #E8EFF7;
  font-size: 52rpx;
  font-weight: bold;
  letter-spacing: 2rpx;
  margin-bottom: 12rpx;
}

.app-subtitle {
  color: rgba(232, 239, 247, 0.6);
  font-size: 26rpx;
}

.form-card {
  width: 100%;
  background: rgba(124, 159, 203, 0.08);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1rpx solid rgba(124, 159, 203, 0.15);
  border-radius: 36rpx;
  padding: 48rpx;
  box-sizing: border-box;
  position: relative;
  overflow: hidden;
  z-index: 1;
}

.form-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(
    135deg,
    rgba(255, 255, 255, 0.05) 0%,
    rgba(255, 255, 255, 0.02) 50%,
    transparent 100%
  );
  pointer-events: none;
  border-radius: 36rpx;
}

.form-item {
  margin-bottom: 36rpx;
  position: relative;
  z-index: 1;
}

.label {
  color: #E8EFF7;
  font-size: 28rpx;
  margin-bottom: 16rpx;
  display: block;
  font-weight: 500;
}

.input-box {
  width: 100%;
  height: 90rpx;
  background: rgba(15, 25, 35, 0.5);
  border-radius: 20rpx;
  padding: 0 30rpx;
  box-sizing: border-box;
  color: #E8EFF7;
  font-size: 28rpx;
  border: 1rpx solid rgba(124, 159, 203, 0.15);
}

.placeholder-style {
  color: rgba(232, 239, 247, 0.6);
}

.error-area {
  display: flex;
  align-items: center;
  margin-bottom: 24rpx;
  position: relative;
  z-index: 1;
}

.error-icon {
  font-size: 28rpx;
  margin-right: 12rpx;
}

.error-text {
  color: #F2B5D4;
  font-size: 24rpx;
}

.btn-login {
  width: 100%;
  height: 96rpx;
  background: linear-gradient(135deg, #7C9FCB, #F2B5D4);
  border-radius: 20rpx;
  color: #ffffff;
  font-size: 32rpx;
  font-weight: bold;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
  margin-top: 12rpx;
  box-shadow: 0 8rpx 24rpx rgba(124, 159, 203, 0.3);
  position: relative;
  z-index: 1;
}

.btn-login::after {
  border: none;
}

.register-link {
  text-align: center;
  margin-top: 32rpx;
  color: #7C9FCB;
  font-size: 26rpx;
  position: relative;
  z-index: 1;
}

.agreement {
  color: rgba(232, 239, 247, 0.6);
  font-size: 24rpx;
  margin-top: 40rpx;
  text-align: center;
  position: relative;
  z-index: 1;
}
</style>
