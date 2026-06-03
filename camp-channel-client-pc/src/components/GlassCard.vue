﻿﻿﻿<template>
  <div class="glass-card" :style="cardStyle">
    <slot></slot>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useThemeStore } from '@/stores/theme'

const props = withDefaults(defineProps<{
  padding?: string
  hover?: boolean
}>(), {
  padding: '24px',
  hover: true,
})

const themeStore = useThemeStore()

const cardStyle = computed(() => ({
  padding: props.padding,
  background: themeStore.currentTheme.card,
  border: `1px solid ${themeStore.currentTheme.border}`,
  color: themeStore.currentTheme.text,
}))
</script>

<style scoped>
.glass-card {
  border-radius: var(--card-radius);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  overflow: hidden;
}

.glass-card:hover {
  transform: translateY(-2px);
  box-shadow: var(--card-shadow);
}

.glass-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  border-radius: var(--card-radius);
  background: linear-gradient(
    135deg,
    rgba(255, 255, 255, 0.1) 0%,
    rgba(255, 255, 255, 0.05) 50%,
    transparent 100%
  );
  pointer-events: none;
}
</style>
