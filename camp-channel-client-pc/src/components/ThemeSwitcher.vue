﻿﻿﻿<template>
  <div class="theme-switcher" :class="{ open: isOpen }">
    <button class="toggle-btn" @click="isOpen = !isOpen">
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <circle cx="12" cy="12" r="5"/><path d="M12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42"/>
      </svg>
    </button>
    <div class="theme-panel" v-if="isOpen">
      <div class="theme-header">
        <span>主题切换</span>
        <button class="close-btn" @click="isOpen = false">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
        </button>
      </div>
      <div class="theme-grid">
        <div
          v-for="(theme, index) in themeStore.themeList"
          :key="index"
          class="theme-item"
          :class="{ active: themeStore.themeIndex === index }"
          @click="themeStore.setTheme(index)"
        >
          <div class="theme-preview" :style="{ background: `linear-gradient(135deg, ${theme.primary}, ${theme.secondary})` }"></div>
          <span class="theme-name">{{ theme.name }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useThemeStore } from '../stores/theme'

const isOpen = ref(false)
const themeStore = useThemeStore()
</script>

<style scoped>
.theme-switcher {
  position: fixed;
  right: 24px;
  top: 88px;
  z-index: 1000;
}

.toggle-btn {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: var(--surface);
  backdrop-filter: blur(12px);
  border: 1px solid var(--outline-variant);
  color: var(--on-surface);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s;
  box-shadow: 0 4px 20px rgba(0,0,0,0.2);
}
.toggle-btn:hover { transform: scale(1.05); border-color: var(--primary); }

.theme-panel {
  position: absolute;
  bottom: 60px;
  right: 0;
  width: 340px;
  max-height: 480px;
  overflow-y: auto;
  background: var(--surface);
  backdrop-filter: blur(24px);
  border: 1px solid var(--outline-variant);
  border-radius: var(--card-radius);
  padding: 16px;
  box-shadow: var(--card-shadow);
}

.theme-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  font-size: 14px;
  font-weight: 600;
}
.close-btn {
  background: none;
  border: none;
  color: var(--on-surface-variant);
  cursor: pointer;
  padding: 4px;
  border-radius: 6px;
}
.close-btn:hover { background: var(--surface); }

.theme-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
}

.theme-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  padding: 8px;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s;
}
.theme-item:hover { background: var(--surface); }
.theme-item.active { background: var(--surface); }

.theme-preview {
  width: 100%;
  height: 36px;
  border-radius: 8px;
  transition: transform 0.2s;
}
.theme-item:hover .theme-preview { transform: scale(1.03); }

.theme-name {
  font-size: 10px;
  color: var(--on-surface-variant);
  text-align: center;
  line-height: 1.2;
}
.theme-item.active .theme-name { color: var(--primary); font-weight: 600; }
</style>
