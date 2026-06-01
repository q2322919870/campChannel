<template>
  <WebGLBackground />
  <div class="app-layout" v-if="showLayout">
    <NavSidebar v-if="!isMobile" />
    <main class="main-content" :class="{ mobile: isMobile }" id="app-content">
      <router-view />
    </main>
    <MobileNav v-if="isMobile" />
    <ParticleBurstOverlay />
  </div>
  <div v-else class="auth-wrapper" id="app-content">
    <router-view />
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import { useThemeStore } from './stores/theme'
import { useAuthStore } from './stores/auth'
import WebGLBackground from './components/WebGLBackground.vue'
import NavSidebar from './components/NavSidebar.vue'
import MobileNav from './components/MobileNav.vue'
import ParticleBurstOverlay from './components/ParticleBurstOverlay.vue'

const route = useRoute()
const themeStore = useThemeStore()
const authStore = useAuthStore()

const isMobile = ref(window.innerWidth <= 768)
let resizeHandler: (() => void) | null = null

onMounted(() => {
  authStore.loadFromStorage()
  themeStore.applyTheme()
  const mq = window.matchMedia('(max-width: 768px)')
  const handler = (e: MediaQueryListEvent | MediaQueryList) => {
    isMobile.value = e.matches
  }
  mq.addEventListener('change', handler as any)
  resizeHandler = () => mq.removeEventListener('change', handler as any)
})

onUnmounted(() => {
  if (resizeHandler) resizeHandler()
})

const showLayout = computed(() => {
  const noLayoutPages = ['/login', '/register']
  return !noLayoutPages.includes(route.path)
})
</script>

<style scoped>
.app-layout {
  display: flex;
  height: 100vh;
  position: relative;
  z-index: 1;
}

.main-content {
  flex: 1;
  margin-left: 72px;
  overflow-y: auto;
  padding: 32px;
}

.main-content.mobile {
  margin-left: 0;
  margin-bottom: 68px;
  padding: 16px 12px;
  padding-bottom: calc(68px + env(safe-area-inset-bottom));
}

.auth-wrapper {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
}
</style>
