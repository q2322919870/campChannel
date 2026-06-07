<template>
  <div class="fluid-bg-blur">
    <div ref="containerRef" class="fluid-bg-container"></div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue'
import { FluidBackground, type FluidColors } from '@/canvas/FluidBackground'
import { useThemeStore } from '@/stores/theme'

const containerRef = ref<HTMLDivElement>()
const engine = ref<FluidBackground | null>(null)
const themeStore = useThemeStore()
let canvasEl: HTMLCanvasElement | null = null

function themeToColors(theme: any): FluidColors {
  return {
    primary: theme.brand || theme.primary || '#35bfab',
    secondary: theme.brandSecondary || theme.secondary || '#1fc9e7',
    glowColor: theme.brand || theme.primary || '#35bfab',
  }
}

onMounted(() => {
  if (!containerRef.value) return
  try {
    const e = new FluidBackground(themeToColors(themeStore.currentTheme))
    canvasEl = e.getCanvas()
    canvasEl.style.cssText = 'position:absolute;top:0;left:0;width:100%;height:100%;pointer-events:none;display:block;'
    containerRef.value.appendChild(canvasEl)
    e.start()
    engine.value = e
  } catch (err) {
    console.warn('WebGL init failed, falling back to CSS background', err)
    if (containerRef.value) {
      containerRef.value.style.cssText = 'position:fixed;inset:0;z-index:0;pointer-events:none;background:var(--background, #141218);'
    }
  }
})

onUnmounted(() => {
  engine.value?.destroy()
})

watch(() => themeStore.themeIndex, () => {
  if (engine.value) engine.value.updateColors(themeToColors(themeStore.currentTheme))
})
</script>

<style scoped>
.fluid-bg-blur {
  position: fixed;
  inset: 0;
  z-index: 0;
  overflow: hidden;
  filter: blur(50px);
  opacity: 0.88;
  pointer-events: none;
}

.fluid-bg-container {
  width: 100%;
  height: 100%;
  pointer-events: none;
}
</style>
