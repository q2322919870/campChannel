<template>
  <view class="settings-page">
    <view class="settings-header">
      <text class="page-title">设置</text>
    </view>

    <view class="settings-section">
      <view class="section-title">外观</view>
      <view class="setting-item" @tap="showThemePicker">
        <text class="setting-label">主题模式</text>
        <text class="setting-value">{{ themeLabel }}</text>
        <text class="setting-arrow">›</text>
      </view>
    </view>

    <view class="settings-section">
      <view class="section-title">账号设置</view>
      <view class="setting-item" @tap="changePassword">
        <text class="setting-label">修改密码</text>
        <text class="setting-arrow">›</text>
      </view>
      <view class="setting-item" @tap="manageDevices">
        <text class="setting-label">设备管理</text>
        <text class="setting-arrow">›</text>
      </view>
    </view>

    <view class="settings-section">
      <view class="section-title">关于</view>
      <view class="about-item">
        <text class="about-label">版本</text>
        <text class="about-value">1.0.0</text>
      </view>
    </view>

    <!-- Theme Picker Modal -->
    <view v-if="showThemeModal" class="modal-overlay" @tap="closeThemeModal">
      <view class="modal-content" @tap.stop>
        <text class="modal-title">选择主题模式</text>
        <view class="theme-options">
          <view
            class="theme-option"
            :class="{ active: themeStore.mode === 'light' }"
            @tap="selectTheme('light')"
          >
            <text class="theme-icon">☀️</text>
            <text class="theme-name">浅色模式</text>
          </view>
          <view
            class="theme-option"
            :class="{ active: themeStore.mode === 'dark' }"
            @tap="selectTheme('dark')"
          >
            <text class="theme-icon">🌙</text>
            <text class="theme-name">深色模式</text>
          </view>
          <view
            class="theme-option"
            :class="{ active: themeStore.mode === 'system' }"
            @tap="selectTheme('system')"
          >
            <text class="theme-icon">⚙️</text>
            <text class="theme-name">跟随系统</text>
          </view>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { onShow } from '@dcloudio/uni-app'
import { useThemeStore, type ThemeMode } from '../../stores/theme'

const themeStore = useThemeStore()
const showThemeModal = ref(false)

const themeLabel = computed(() => {
  const labels: Record<ThemeMode, string> = {
    light: '浅色模式',
    dark: '深色模式',
    system: '跟随系统',
  }
  return labels[themeStore.mode] || '浅色模式'
})

onShow(() => {
  // Apply theme class to page on every show
  applyThemeClass()
})

function applyThemeClass() {
  const pages = getCurrentPages()
  const currentPage = pages[pages.length - 1] as any
  if (currentPage?.$page?.el) {
    const pageEl = currentPage.$page.el
    if (themeStore.isDark()) {
      pageEl.classList.add('dark-mode')
    } else {
      pageEl.classList.remove('dark-mode')
    }
  }
}

function showThemePicker() {
  showThemeModal.value = true
}

function closeThemeModal() {
  showThemeModal.value = false
}

function selectTheme(mode: ThemeMode) {
  themeStore.setMode(mode)
  closeThemeModal()
  applyThemeClass()
}

function changePassword() {
  uni.navigateTo({ url: '/pages/settings/change-password' })
}

function manageDevices() {
  uni.navigateTo({ url: '/pages/settings/devices' })
}
</script>

<style scoped>
.settings-page {
  min-height: 100vh;
  background: transparent;
}

.settings-header {
  padding: 32rpx;
  background: var(--card);
  margin: 20rpx;
  border-radius: var(--radius-lg);
  border: 1rpx solid var(--card-border);
  box-shadow: var(--shadow-sm);
}

.page-title {
  font-size: 40rpx;
  font-weight: bold;
  color: var(--text);
}

.settings-section {
  margin: 0 20rpx 16rpx 20rpx;
  background: var(--card);
  border-radius: var(--radius);
  border: 1rpx solid var(--card-border);
  overflow: hidden;
  box-shadow: var(--shadow-sm);
}

.section-title {
  padding: 24rpx 32rpx;
  font-size: 26rpx;
  font-weight: 600;
  color: var(--text-muted);
  background: transparent;
  border-bottom: 1rpx solid var(--card-border);
}

.setting-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 28rpx 32rpx;
  border-bottom: 1rpx solid var(--card-border);
}

.setting-item:last-child {
  border-bottom: none;
}

.setting-item:active {
  background: var(--bg);
}

.setting-label {
  font-size: 28rpx;
  color: var(--text);
}

.setting-arrow {
  font-size: 36rpx;
  color: var(--text-muted);
}

.about-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 28rpx 32rpx;
}

.about-label {
  font-size: 28rpx;
  color: var(--text);
}

.about-value {
  font-size: 28rpx;
  color: var(--text-secondary);
}

.setting-value {
  font-size: 26rpx;
  color: var(--text-muted);
  margin-right: 8rpx;
}

/* Modal Styles */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
}

.modal-content {
  width: 80%;
  max-width: 600rpx;
  background: var(--card);
  border-radius: var(--radius-lg);
  padding: 40rpx;
  box-shadow: var(--shadow-lg);
}

.modal-title {
  font-size: 32rpx;
  font-weight: bold;
  color: var(--text);
  display: block;
  margin-bottom: 32rpx;
  text-align: center;
}

.theme-options {
  display: flex;
  flex-direction: column;
  gap: 20rpx;
}

.theme-option {
  display: flex;
  align-items: center;
  padding: 24rpx;
  border: 2rpx solid var(--card-border);
  border-radius: var(--radius);
  background: var(--bg);
  transition: all 0.2s ease;
}

.theme-option:active {
  opacity: 0.8;
}

.theme-option.active {
  border-color: var(--primary);
  background: var(--primary-soft);
}

.theme-icon {
  font-size: 40rpx;
  margin-right: 16rpx;
}

.theme-name {
  font-size: 28rpx;
  color: var(--text);
  font-weight: 500;
}
</style>
