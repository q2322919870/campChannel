<template>
  <div class="shader-card-wrapper">
    <div ref="cardRef" class="shader-card" @mouseenter="onEnter" @mouseleave="onLeave">
      <slot />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import { useThemeStore } from '@/stores/theme'
import { MoodShaderEffect, type MoodColors } from '@/canvas/MoodShaderEffect'

const props = withDefaults(defineProps<{
  mood?: 'glass' | 'glitch'
  intensity?: number
}>(), { mood: 'glass', intensity: 0.2 })

const cardRef = ref<HTMLDivElement>()
const themeStore = useThemeStore()
let effect: MoodShaderEffect | null = null

function themeToColors(theme: any): MoodColors {
  return { primary: theme.primary || '#7C9FCB', accent: theme.accent || '#F2B5D4', glowColor: theme.glowColor || '#7C9FCB' }
}

function onEnter() {
  if (effect) effect.setIntensity(0.6)
}

function onLeave() {
  if (effect) effect.setIntensity(props.intensity)
}

onMounted(async () => {
  await nextTick()
  if (!cardRef.value || cardRef.value.clientHeight === 0) return
  try {
    effect = new MoodShaderEffect(cardRef.value, themeToColors(themeStore.currentTheme))
    effect.setMode(props.mood === 'glitch' ? 'glitch' : 'glass')
    effect.setIntensity(props.intensity)
    effect.start()
  } catch (err) {
    console.warn('Shader effect init failed', err)
  }
})

onUnmounted(() => {
  effect?.destroy()
})
</script>

<style scoped>
.shader-card-wrapper { border-radius: inherit; }
.shader-card { position: relative; overflow: hidden; border-radius: inherit; }
</style>
