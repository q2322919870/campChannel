<template>
  <div ref="containerRef" class="fluid-bg-container"></div>
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
  return { primary: theme.primary || '#D0BCFF', secondary: theme.secondary || '#CCC2DC', glowColor: theme.primary || '#D0BCFF' }
}

onMounted(() => {
  if (!containerRef.value) return
  try {
    const e = new FluidBackground(themeToColors(themeStore.currentTheme))
    canvasEl = e.getCanvas()
    canvasEl.style.cssText = 'position:fixed;top:0;left:0;width:100vw;height:100vh;z-index:0;pointer-events:none;'
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
.fluid-bg-container {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  z-index: 0;
  pointer-events: none;
}
</style>
