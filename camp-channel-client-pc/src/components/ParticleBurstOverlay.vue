<template>
  <canvas ref="burstCanvas" class="particle-burst-canvas"></canvas>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, provide } from 'vue'
import { ParticleBurstSystem } from '../canvas/ParticleBurst'

const burstCanvas = ref<HTMLCanvasElement>()
let system: ParticleBurstSystem | null = null

function triggerBurst(x: number, y: number, color?: string) {
  system?.burst({ x, y, color })
}

// Provide at setup level, not inside onMounted
provide('particleBurst', triggerBurst)

onMounted(() => {
  if (!burstCanvas.value) return
  system = new ParticleBurstSystem(burstCanvas.value)
})

onUnmounted(() => {
  system?.destroy()
})
</script>

<style scoped>
.particle-burst-canvas {
  position: fixed;
  inset: 0;
  z-index: 9999;
  pointer-events: none;
}
</style>
