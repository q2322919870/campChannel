<script setup lang="ts">
import { onHide, onLaunch, onShow } from '@dcloudio/uni-app'
import { useAuthStore } from './stores/auth'
import { useThemeStore } from './stores/theme'
import request from './utils/request'

const authStore = useAuthStore()
const themeStore = useThemeStore()

onLaunch(() => {
  themeStore.init()

  if (authStore.token) {
    loadUnreadCount()
  }

  // Set custom tab bar style
  uni.setTabBarStyle({
    backgroundColor: themeStore.isDark() ? '#1A1D26' : '#FFFFFF',
    borderStyle: themeStore.isDark() ? 'black' : 'white',
    color: themeStore.isDark() ? '#6B7280' : '#9CA3AF',
    selectedColor: themeStore.isDark() ? '#818CF8' : '#6366F1'
  })
})

async function loadUnreadCount() {
  try {
    // Try notifications endpoint first
    const res = await request<any>('/notifications/unread/count')
    const count = res?.data ?? res?.count ?? 0
    if (count > 0) {
      uni.setTabBarBadge({
        index: 2,
        text: count > 99 ? '99+' : String(count),
      })
    }
  } catch (_) {
    // Endpoint might not exist, silently ignore
  }
}

onShow(() => {
  if (authStore.token) {
    loadUnreadCount()
  }
})
onHide(() => {})
</script>

<template>
  <view>
    <slot />
  </view>
</template>

<style>
/* ===== Global Design Tokens ===== */
page {
  --primary: #6366F1;
  --primary-light: #818CF8;
  --primary-soft: rgba(99, 102, 241, 0.08);
  --primary-gradient: linear-gradient(135deg, #6366F1, #A855F7);
  --accent: #EC4899;
  --accent-soft: rgba(236, 72, 153, 0.08);
  --bg: #F3F4F8;
  --card: #FFFFFF;
  --card-border: #E8EAF0;
  --text: #1A1D26;
  --text-secondary: #6B7280;
  --text-soft: #6B7280;
  --text-muted: #9CA3AF;
  --success: #10B981;
  --danger: #EF4444;
  --warning: #F59E0B;
  --shadow-sm: 0 2rpx 8rpx rgba(0, 0, 0, 0.04);
  --shadow: 0 4rpx 24rpx rgba(0, 0, 0, 0.06);
  --shadow-lg: 0 8rpx 40rpx rgba(0, 0, 0, 0.08);
  --radius: 24rpx;
  --radius-lg: 32rpx;

  background: var(--bg);
  color: var(--text);
  font-family: -apple-system, BlinkMacSystemFont, 'PingFang SC', 'Helvetica Neue', 'Microsoft YaHei', sans-serif;
  min-height: 100vh;
  -webkit-font-smoothing: antialiased;
}

/* ===== Dark Mode ===== */
page.dark-mode {
  --primary: #818CF8;
  --primary-light: #A5B4FC;
  --primary-soft: rgba(129, 140, 248, 0.12);
  --primary-gradient: linear-gradient(135deg, #818CF8, #C084FC);
  --accent: #F472B6;
  --accent-soft: rgba(244, 114, 182, 0.12);
  --bg: #0F1117;
  --card: #1A1D26;
  --card-border: #2D3148;
  --text: #F3F4F8;
  --text-secondary: #9CA3AF;
  --text-soft: #9CA3AF;
  --text-muted: #6B7280;
  --success: #34D399;
  --danger: #F87171;
  --warning: #FBBF24;
  --shadow-sm: 0 2rpx 8rpx rgba(0, 0, 0, 0.2);
  --shadow: 0 4rpx 24rpx rgba(0, 0, 0, 0.3);
  --shadow-lg: 0 8rpx 40rpx rgba(0, 0, 0, 0.4);
}

page.dark-mode {
  background: var(--bg);
  color: var(--text);
}

view,
text,
input,
textarea,
button {
  transition: background-color 0.2s ease, color 0.2s ease, border-color 0.2s ease, box-shadow 0.2s ease;
  box-sizing: border-box;
}

/* Remove scrollbar */
::-webkit-scrollbar {
  width: 0;
  height: 0;
}

/* Global button reset */
button::after {
  border: none;
}

button {
  margin: 0;
  padding: 0;
  line-height: inherit;
}
</style>
