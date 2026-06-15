<template>
  <view class="devices-page">
    <view class="header-card">
      <text class="page-title">设备管理</text>
      <text class="page-subtitle">管理已登录的设备，可疑设备可远程下线</text>
    </view>

    <view v-if="loading" class="loading-state">
      <text class="loading-text">加载中...</text>
    </view>

    <view v-else-if="devices.length === 0" class="empty-state">
      <text class="empty-icon">📱</text>
      <text class="empty-text">暂无登录设备记录</text>
    </view>

    <view v-else class="device-list">
      <view v-for="d in devices" :key="d.id" class="device-item">
        <view class="device-icon">
          <text>{{ getDeviceIcon(d.deviceName) }}</text>
        </view>
        <view class="device-info">
          <text class="device-name">{{ d.deviceName || '未知设备' }}</text>
          <text class="device-ip">IP: {{ d.ipAddress || '未知' }}</text>
          <text class="device-time">登录: {{ formatTime(d.loginTime) }}</text>
          <text v-if="d.lastActiveTime" class="device-time">最后活跃: {{ formatTime(d.lastActiveTime) }}</text>
        </view>
        <button class="btn-logout" @tap="logoutDevice(d)">下线</button>
      </view>
    </view>

    <button v-if="devices.length > 0" class="btn-logout-all" @tap="logoutAll">
      所有设备下线
    </button>
  </view>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useAuthStore } from '../../stores/auth'
import request from '../../utils/request'

const authStore = useAuthStore()

interface Device {
  id: number
  deviceName: string
  ipAddress: string
  loginTime: string
  lastActiveTime: string
}

const devices = ref<Device[]>([])
const loading = ref(true)

onMounted(() => {
  loadDevices()
})

async function loadDevices() {
  loading.value = true
  try {
    const res = await request<any>('/users/devices')
    if (res?.code === 200) {
      devices.value = (res.data || []).map((d: any) => ({
        id: d.id,
        deviceName: d.deviceName || '未知设备',
        ipAddress: d.ipAddress || '未知',
        loginTime: d.loginTime || d.login_time || '',
        lastActiveTime: d.lastActiveTime || d.last_active_time || '',
      }))
    }
  } catch (_) {
    uni.showToast({ title: '加载失败', icon: 'none' })
  } finally {
    loading.value = false
  }
}

function getDeviceIcon(name: string): string {
  if (!name) return '📱'
  const lower = name.toLowerCase()
  if (lower.includes('iphone') || lower.includes('android') || lower.includes('phone')) return '📱'
  if (lower.includes('ipad') || lower.includes('tablet')) return '📟'
  if (lower.includes('windows') || lower.includes('mac') || lower.includes('linux')) return '💻'
  if (lower.includes('chrome') || lower.includes('firefox') || lower.includes('safari')) return '🌐'
  if (lower.includes('wechat') || lower.includes('微信') || lower.includes('miniprogram')) return '💬'
  return '📱'
}

function formatTime(t: string): string {
  if (!t) return ''
  const d = new Date(t)
  const now = new Date()
  const diff = now.getTime() - d.getTime()
  if (diff < 60000) return '刚刚'
  if (diff < 3600000) return `${Math.floor(diff / 60000)}分钟前`
  if (diff < 86400000) return `${Math.floor(diff / 3600000)}小时前`
  return `${d.getMonth() + 1}/${d.getDate()} ${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`
}

async function logoutDevice(device: Device) {
  uni.showModal({
    title: '确认下线',
    content: `确定要让设备 "${device.deviceName}" 下线吗？`,
    success: async (res) => {
      if (res.confirm) {
        try {
          const r = await request<any>({
            url: `/users/devices/${device.id}`,
            method: 'DELETE',
          })
          if (r?.code === 200) {
            devices.value = devices.value.filter((d) => d.id !== device.id)
            uni.showToast({ title: '已下线', icon: 'success' })
          }
        } catch (_) {
          uni.showToast({ title: '操作失败', icon: 'none' })
        }
      }
    },
  })
}

async function logoutAll() {
  uni.showModal({
    title: '确认全部下线',
    content: '确定要让所有设备下线吗？当前设备除外。',
    success: async (res) => {
      if (res.confirm) {
        try {
          const r = await request<any>({
            url: '/users/devices/logout-all',
            method: 'POST',
          })
          if (r?.code === 200) {
            devices.value = []
            uni.showToast({ title: '已全部下线', icon: 'success' })
          }
        } catch (_) {
          uni.showToast({ title: '操作失败', icon: 'none' })
        }
      }
    },
  })
}
</script>

<style scoped>
.devices-page {
  min-height: 100vh;
  background: var(--bg);
  padding: 32rpx;
}

.header-card {
  background: var(--card);
  border: 1rpx solid var(--card-border);
  border-radius: var(--radius-lg);
  padding: 32rpx;
  margin-bottom: 24rpx;
  box-shadow: var(--shadow-sm);
}

.page-title {
  font-size: 40rpx;
  font-weight: 700;
  color: var(--text);
  display: block;
  margin-bottom: 8rpx;
}

.page-subtitle {
  font-size: 24rpx;
  color: var(--text-muted);
}

.device-list {
  display: flex;
  flex-direction: column;
  gap: 16rpx;
}

.device-item {
  display: flex;
  align-items: center;
  background: var(--card);
  border: 1rpx solid var(--card-border);
  border-radius: var(--radius);
  padding: 24rpx;
  box-shadow: var(--shadow-sm);
}

.device-icon {
  width: 80rpx;
  height: 80rpx;
  border-radius: 20rpx;
  background: var(--primary-soft);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 36rpx;
  margin-right: 20rpx;
  flex-shrink: 0;
}

.device-info {
  flex: 1;
  min-width: 0;
}

.device-name {
  font-size: 28rpx;
  font-weight: 600;
  color: var(--text);
  display: block;
  margin-bottom: 4rpx;
}

.device-ip,
.device-time {
  font-size: 22rpx;
  color: var(--text-muted);
  display: block;
}

.btn-logout {
  height: 56rpx;
  padding: 0 24rpx;
  background: var(--accent-soft);
  border-radius: 28rpx;
  color: var(--accent);
  font-size: 24rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
  flex-shrink: 0;
}

.btn-logout-all {
  width: 100%;
  height: 88rpx;
  background: rgba(239, 68, 68, 0.08);
  border: 1rpx solid rgba(239, 68, 68, 0.2);
  border-radius: 44rpx;
  color: #ef4444;
  font-size: 28rpx;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-top: 32rpx;
}

.loading-state,
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 120rpx 0;
}

.loading-text,
.empty-text {
  font-size: 28rpx;
  color: var(--text-muted);
}

.empty-icon {
  font-size: 80rpx;
  margin-bottom: 20rpx;
}
</style>
