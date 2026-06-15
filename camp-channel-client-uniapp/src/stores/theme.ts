import { defineStore } from 'pinia'
import { ref } from 'vue'

export type ThemeMode = 'light' | 'dark' | 'system'

export const useThemeStore = defineStore('theme', () => {
  const mode = ref<ThemeMode>('light')

  function init() {
    const saved = uni.getStorageSync('themeMode') as ThemeMode
    if (saved) {
      mode.value = saved
    }
    applyTheme()
  }

  function setMode(newMode: ThemeMode) {
    mode.value = newMode
    uni.setStorageSync('themeMode', newMode)
    applyTheme()
  }

  function isDark(): boolean {
    if (mode.value === 'system') {
      const res = uni.getSystemInfoSync()
      return res.theme === 'dark'
    }
    return mode.value === 'dark'
  }

  function applyTheme() {
    const dark = isDark()
    uni.setStorageSync('isDarkMode', dark ? '1' : '0')

    // Only update tab bar style if we're on a tab bar page
    const pages = getCurrentPages()
    if (pages.length > 0) {
      const currentPage = pages[pages.length - 1]
      const route = currentPage.route
      // Check if current page is a tab bar page
      const isTabBarPage = route === 'pages/index/index' || 
                           route === 'pages/channel/channel' || 
                           route === 'pages/chat/list' || 
                           route === 'pages/notification/notification' ||
                           route === 'pages/profile/profile'
      
      if (isTabBarPage) {
        if (dark) {
          uni.setTabBarStyle({
            backgroundColor: '#1A1D26',
            borderStyle: 'black',
            color: '#6B7280',
            selectedColor: '#818CF8'
          })
        } else {
          uni.setTabBarStyle({
            backgroundColor: '#FFFFFF',
            borderStyle: 'white',
            color: '#9CA3AF',
            selectedColor: '#6366F1'
          })
        }
      }
    }
  }

  return { mode, init, setMode, isDark, applyTheme }
})
