<template>
  <view class="test-page">
    <view class="test-header">
      <text class="title">连接测试</text>
    </view>

    <view class="test-section">
      <text class="section-title">后端连接状态</text>
      <view class="status-card" :class="apiStatus.class">
        <text class="status-icon">{{ apiStatus.icon }}</text>
        <text class="status-text">{{ apiStatus.message }}</text>
      </view>
      <button class="test-btn" @tap="testApiConnection">测试API连接</button>
    </view>

    <view class="test-section">
      <text class="section-title">WebSocket状态</text>
      <view class="status-card" :class="wsStatus.class">
        <text class="status-icon">{{ wsStatus.icon }}</text>
        <text class="status-text">{{ wsStatus.message }}</text>
      </view>
      <button class="test-btn" @tap="testWebSocket">测试WebSocket</button>
    </view>

    <view class="test-section">
      <text class="section-title">当前配置</text>
      <view class="config-item">
        <text class="label">API地址:</text>
        <text class="value">{{ apiUrl }}</text>
      </view>
      <view class="config-item">
        <text class="label">Token:</text>
        <text class="value">{{ hasToken ? '已登录' : '未登录' }}</text>
      </view>
    </view>

    <view v-if="logs.length > 0" class="test-section">
      <text class="section-title">日志</text>
      <scroll-view scroll-y class="log-container">
        <text v-for="(log, i) in logs" :key="i" class="log-line">{{ log }}</text>
      </scroll-view>
      <button class="clear-btn" @tap="logs = []">清除日志</button>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { request } from '../../utils/request'
import wsManager from '../../utils/websocket'
import { useAuthStore } from '../../stores/auth'

const authStore = useAuthStore()

interface StatusInfo {
  icon: string
  message: string
  class: string
}

const apiUrl = ref('http://localhost:8080/api')
const hasToken = ref(!!authStore.token)
const logs = ref<string[]>([])

const apiStatus = ref<StatusInfo>({
  icon: '❓',
  message: '未测试',
  class: 'pending'
})

const wsStatus = ref<StatusInfo>({
  icon: '❓',
  message: '未测试',
  class: 'pending'
})

onMounted(() => {
  addLog('页面加载完成')
  const storedUrl = uni.getStorageSync('api_base_url')
  if (storedUrl) {
    apiUrl.value = storedUrl + '/api'
    addLog(`使用配置的API地址: ${storedUrl}`)
  } else {
    addLog('使用默认API地址: http://localhost:8080/api')
  }
})

function addLog(message: string) {
  const time = new Date().toLocaleTimeString()
  logs.value.unshift(`[${time}] ${message}`)
  if (logs.value.length > 50) {
    logs.value.pop()
  }
}

async function testApiConnection() {
  addLog('开始测试API连接...')
  apiStatus.value = {
    icon: '⏳',
    message: '测试中...',
    class: 'pending'
  }

  try {
    // Try to get posts (public endpoint might work)
    const res = await request<any>({
      url: '/posts?page=1&size=1',
      method: 'GET'
    })
    
    if (res?.code === 200 || res?.code === 401) {
      apiStatus.value = {
        icon: '✅',
        message: res.code === 200 ? '连接成功' : '连接成功（需要登录）',
        class: 'success'
      }
      addLog(`API响应: code=${res.code}`)
    } else {
      apiStatus.value = {
        icon: '❌',
        message: `连接失败: ${res?.message || '未知错误'}`,
        class: 'error'
      }
      addLog(`API错误: ${JSON.stringify(res)}`)
    }
  } catch (err: any) {
    apiStatus.value = {
      icon: '❌',
      message: '连接失败',
      class: 'error'
    }
    addLog(`API异常: ${err.errMsg || err.message}`)
  }
}

async function testWebSocket() {
  addLog('开始测试WebSocket...')
  wsStatus.value = {
    icon: '⏳',
    message: '连接中...',
    class: 'pending'
  }

  try {
    await wsManager.connect()
    
    setTimeout(() => {
      if (wsManager.isConnected()) {
        wsStatus.value = {
          icon: '✅',
          message: '连接成功',
          class: 'success'
        }
        addLog('WebSocket连接成功')
      } else {
        wsStatus.value = {
          icon: '❌',
          message: '连接失败',
          class: 'error'
        }
        addLog('WebSocket连接失败')
      }
    }, 2000)
  } catch (err: any) {
    wsStatus.value = {
      icon: '❌',
      message: '连接失败',
      class: 'error'
    }
    addLog(`WebSocket异常: ${err.message}`)
  }
}
</script>

<style scoped>
.test-page {
  min-height: 100vh;
  background: transparent;
  padding: 32rpx;
  position: relative;
  z-index: 1;
}

.test-header {
  margin-bottom: 32rpx;
}

.title {
  font-size: 48rpx;
  font-weight: bold;
  color: #E8EFF7;
}

.test-section {
  margin-bottom: 32rpx;
  background: rgba(124, 159, 203, 0.08);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1rpx solid rgba(124, 159, 203, 0.15);
  border-radius: 16rpx;
  padding: 24rpx;
  position: relative;
  overflow: hidden;
}

.test-section::before {
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
  border-radius: 16rpx;
}

.section-title {
  font-size: 32rpx;
  font-weight: 600;
  color: #E8EFF7;
  margin-bottom: 16rpx;
  display: block;
  position: relative;
  z-index: 1;
}

.status-card {
  display: flex;
  align-items: center;
  gap: 16rpx;
  padding: 24rpx;
  border-radius: 12rpx;
  margin-bottom: 16rpx;
  position: relative;
  z-index: 1;
}

.status-card.pending {
  background: rgba(255, 193, 7, 0.1);
  border: 1rpx solid rgba(255, 193, 7, 0.3);
}

.status-card.success {
  background: rgba(76, 175, 80, 0.1);
  border: 1rpx solid rgba(76, 175, 80, 0.3);
}

.status-card.error {
  background: rgba(242, 181, 212, 0.1);
  border: 1rpx solid rgba(242, 181, 212, 0.3);
}

.status-icon {
  font-size: 48rpx;
}

.status-text {
  font-size: 28rpx;
  color: #E8EFF7;
}

.test-btn {
  width: 100%;
  padding: 20rpx;
  background: linear-gradient(135deg, #7C9FCB, #F2B5D4);
  color: #ffffff;
  border-radius: 12rpx;
  font-size: 28rpx;
  border: none;
  position: relative;
  z-index: 1;
}

.config-item {
  display: flex;
  justify-content: space-between;
  padding: 16rpx 0;
  border-bottom: 1rpx solid rgba(124, 159, 203, 0.15);
  position: relative;
  z-index: 1;
}

.config-item:last-child {
  border-bottom: none;
}

.label {
  font-size: 26rpx;
  color: rgba(232, 239, 247, 0.6);
}

.value {
  font-size: 26rpx;
  color: #E8EFF7;
}

.log-container {
  max-height: 400rpx;
  background: rgba(15, 25, 35, 0.5);
  border-radius: 8rpx;
  padding: 16rpx;
  margin-bottom: 16rpx;
  position: relative;
  z-index: 1;
}

.log-line {
  display: block;
  font-size: 22rpx;
  color: rgba(232, 239, 247, 0.6);
  font-family: monospace;
  line-height: 1.6;
  margin-bottom: 4rpx;
}

.clear-btn {
  width: 100%;
  padding: 16rpx;
  background: rgba(15, 25, 35, 0.5);
  color: #E8EFF7;
  border: 1rpx solid rgba(124, 159, 203, 0.15);
  border-radius: 12rpx;
  font-size: 26rpx;
  position: relative;
  z-index: 1;
}
</style>
