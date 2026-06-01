<script setup lang="ts">
import { onHide, onLaunch, onShow } from '@dcloudio/uni-app'
import { useAuthStore } from './stores/auth'
import request from './utils/request'

const authStore = useAuthStore()

onLaunch(() => {
  if (authStore.token) {
    loadUnreadCount()
  }
  
  // Set custom tab bar style with glassmorphism
  uni.setTabBarStyle({
    backgroundColor: '#0F1923',
    borderStyle: 'black',
    color: 'rgba(232, 239, 247, 0.6)',
    selectedColor: '#7C9FCB'
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
page {
  background: linear-gradient(135deg, #0F1923 0%, #1a2a3a 50%, #2d3748 100%);
  background-attachment: fixed;
  color: #E8EFF7;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
  min-height: 100vh;
  position: relative;
}

/* Animated gradient background */
page::before {
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

view,
text,
input,
textarea,
button {
  transition: background-color 0.3s ease, color 0.3s ease, border-color 0.3s ease;
}

/* Remove custom scrollbar styles */

::-webkit-scrollbar {
  width: 0;
  height: 0;
}
</style>
