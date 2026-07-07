<template>
  <div v-if="!compatible" class="browser-warning">
    <div class="warning-content">
      <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
        <line x1="12" y1="9" x2="12" y2="13"/>
        <line x1="12" y1="17" x2="12.01" y2="17"/>
      </svg>
      <h2>浏览器不兼容</h2>
      <p>{{ message }}</p>
      <p class="hint">建议使用 Chrome 90+、Firefox 88+、Edge 90+ 或 Safari 14+ 浏览器</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'

const compatible = ref(true)
const message = ref('')

const checkBrowserCompatibility = () => {
  const requiredFeatures = [
    'fetch',
    'Promise',
    'localStorage',
    'WebSocket',
    'Map',
    'Set',
    'Array.from',
  ]

  for (const feature of requiredFeatures) {
    const parts = feature.split('.')
    let exists = window as any
    for (const p of parts) {
      exists = exists?.[p]
      if (exists === undefined) break
    }
    if (exists === undefined) {
      return {
        compatible: false,
        message: `您的浏览器不支持 ${feature}，请升级浏览器以获得最佳体验`,
      }
    }
  }

  // 检查 IntersectionObserver（用于懒加载）
  if (!('IntersectionObserver' in window)) {
    return {
      compatible: false,
      message: '您的浏览器版本过旧，部分功能可能无法正常使用，建议升级浏览器',
    }
  }

  return { compatible: true, message: '' }
}

onMounted(() => {
  const result = checkBrowserCompatibility()
  compatible.value = result.compatible
  message.value = result.message
})
</script>

<style scoped>
.browser-warning {
  position: fixed;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #1a1a2e, #16213e);
  color: #fff;
  z-index: 9999;
}
.warning-content {
  text-align: center;
  max-width: 500px;
  padding: 40px;
}
.warning-content h2 {
  margin: 16px 0 8px;
  font-size: 24px;
}
.warning-content p {
  margin: 8px 0;
  opacity: 0.9;
}
.warning-content .hint {
  margin-top: 20px;
  font-size: 14px;
  opacity: 0.6;
}
</style>
