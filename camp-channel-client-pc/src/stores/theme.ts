import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { setCursorTheme } from '../utils/cursorRenderer'

export interface Theme {
  name: string
  primary: string
  primaryLight: string
  accent: string
  bg: string
  card: string
  text: string
  textSecondary: string
  border: string
  gradientStart: string
  gradientEnd: string
  glowColor: string
  style: 'glass' | 'material'
  borderRadius: string
  cardRadius: string
  buttonRadius: string
  shadow: string
  cardShadow: string
}

const themes: Theme[] = [
  {
    name: 'Material Design',
    primary: '#6200EE',
    primaryLight: '#9D46FF',
    accent: '#03DAC6',
    bg: '#121212',
    card: '#1E1E1E',
    text: '#E1E1E1',
    textSecondary: 'rgba(225, 225, 225, 0.6)',
    border: 'rgba(255, 255, 255, 0.08)',
    gradientStart: '#6200EE',
    gradientEnd: '#03DAC6',
    glowColor: '#9D46FF',
    style: 'material',
    borderRadius: '4px',
    cardRadius: '8px',
    buttonRadius: '4px',
    shadow: '0 2px 4px rgba(0,0,0,0.3)',
    cardShadow: '0 4px 8px rgba(0,0,0,0.4)',
  },
  {
    name: '雾蓝樱粉',
    primary: '#7C9FCB',
    primaryLight: '#A8C4E8',
    accent: '#F2B5D4',
    bg: '#0F1923',
    card: 'rgba(124, 159, 203, 0.08)',
    text: '#E8EFF7',
    textSecondary: 'rgba(232, 239, 247, 0.6)',
    border: 'rgba(124, 159, 203, 0.15)',
    gradientStart: '#6B8DBD',
    gradientEnd: '#E8A8C8',
    glowColor: '#A8C4E8',
    style: 'glass',
    borderRadius: '12px',
    cardRadius: '20px',
    buttonRadius: '12px',
    shadow: '0 4px 12px rgba(0,0,0,0.2)',
    cardShadow: '0 8px 32px rgba(0,0,0,0.3)',
  },
  {
    name: '湖蓝淡粉',
    primary: '#4A9BD9',
    primaryLight: '#7BB8E8',
    accent: '#F5C6D0',
    bg: '#0E1A24',
    card: 'rgba(74, 155, 217, 0.08)',
    text: '#E5F0FA',
    textSecondary: 'rgba(229, 240, 250, 0.6)',
    border: 'rgba(74, 155, 217, 0.15)',
    gradientStart: '#3B8AC8',
    gradientEnd: '#F0B0C0',
    glowColor: '#7BB8E8',
    style: 'glass',
    borderRadius: '12px',
    cardRadius: '20px',
    buttonRadius: '12px',
    shadow: '0 4px 12px rgba(0,0,0,0.2)',
    cardShadow: '0 8px 32px rgba(0,0,0,0.3)',
  },
  {
    name: '鼠尾草淡黄',
    primary: '#9CAF88',
    primaryLight: '#BCCDAA',
    accent: '#F5E6B8',
    bg: '#141A10',
    card: 'rgba(156, 175, 136, 0.08)',
    text: '#EDF2E8',
    textSecondary: 'rgba(237, 242, 232, 0.6)',
    border: 'rgba(156, 175, 136, 0.15)',
    gradientStart: '#8A9E78',
    gradientEnd: '#E8D8A0',
    glowColor: '#BCCDAA',
    style: 'glass',
    borderRadius: '12px',
    cardRadius: '20px',
    buttonRadius: '12px',
    shadow: '0 4px 12px rgba(0,0,0,0.2)',
    cardShadow: '0 8px 32px rgba(0,0,0,0.3)',
  },
  {
    name: '薄荷孔雀绿',
    primary: '#7EC8AE',
    primaryLight: '#A3DCC8',
    accent: '#2E8B57',
    bg: '#0F1D17',
    card: 'rgba(126, 200, 174, 0.08)',
    text: '#E5F5EF',
    textSecondary: 'rgba(229, 245, 239, 0.6)',
    border: 'rgba(126, 200, 174, 0.15)',
    gradientStart: '#6BB89E',
    gradientEnd: '#3A8F5F',
    glowColor: '#A3DCC8',
    style: 'glass',
    borderRadius: '12px',
    cardRadius: '20px',
    buttonRadius: '12px',
    shadow: '0 4px 12px rgba(0,0,0,0.2)',
    cardShadow: '0 8px 32px rgba(0,0,0,0.3)',
  },
  {
    name: '玫红雪白',
    primary: '#E84855',
    primaryLight: '#F06A75',
    accent: '#F8F9FA',
    bg: '#1C0F0F',
    card: 'rgba(232, 72, 85, 0.08)',
    text: '#F5E8E8',
    textSecondary: 'rgba(245, 232, 232, 0.6)',
    border: 'rgba(232, 72, 85, 0.15)',
    gradientStart: '#D83845',
    gradientEnd: '#E8E8F0',
    glowColor: '#F06A75',
    style: 'glass',
    borderRadius: '12px',
    cardRadius: '20px',
    buttonRadius: '12px',
    shadow: '0 4px 12px rgba(0,0,0,0.2)',
    cardShadow: '0 8px 32px rgba(0,0,0,0.3)',
  },
  {
    name: '浅蓝薄荷',
    primary: '#A0D2DB',
    primaryLight: '#C0E4EA',
    accent: '#B8E6D0',
    bg: '#0E181B',
    card: 'rgba(160, 210, 219, 0.08)',
    text: '#EAF4F6',
    textSecondary: 'rgba(234, 244, 246, 0.6)',
    border: 'rgba(160, 210, 219, 0.15)',
    gradientStart: '#90C2CB',
    gradientEnd: '#A0D8C0',
    glowColor: '#C0E4EA',
    style: 'glass',
    borderRadius: '12px',
    cardRadius: '20px',
    buttonRadius: '12px',
    shadow: '0 4px 12px rgba(0,0,0,0.2)',
    cardShadow: '0 8px 32px rgba(0,0,0,0.3)',
  },
  {
    name: '夜紫橙金',
    primary: '#6B4E9B',
    primaryLight: '#8E6DB8',
    accent: '#F4A460',
    bg: '#15101F',
    card: 'rgba(107, 78, 155, 0.08)',
    text: '#EAE3F2',
    textSecondary: 'rgba(234, 227, 242, 0.6)',
    border: 'rgba(107, 78, 155, 0.15)',
    gradientStart: '#5B3E8B',
    gradientEnd: '#E89450',
    glowColor: '#8E6DB8',
    style: 'glass',
    borderRadius: '12px',
    cardRadius: '20px',
    buttonRadius: '12px',
    shadow: '0 4px 12px rgba(0,0,0,0.2)',
    cardShadow: '0 8px 32px rgba(0,0,0,0.3)',
  },
  {
    name: '深蓝柔粉',
    primary: '#2C3E6B',
    primaryLight: '#4A5F8F',
    accent: '#E8B4C8',
    bg: '#0C111F',
    card: 'rgba(44, 62, 107, 0.08)',
    text: '#E2E8F2',
    textSecondary: 'rgba(226, 232, 242, 0.6)',
    border: 'rgba(44, 62, 107, 0.15)',
    gradientStart: '#1C2E5B',
    gradientEnd: '#D8A0B8',
    glowColor: '#4A5F8F',
    style: 'glass',
    borderRadius: '12px',
    cardRadius: '20px',
    buttonRadius: '12px',
    shadow: '0 4px 12px rgba(0,0,0,0.2)',
    cardShadow: '0 8px 32px rgba(0,0,0,0.3)',
  },
  {
    name: '青绿奶杏',
    primary: '#3B7A6B',
    primaryLight: '#5A9E8E',
    accent: '#F0E2C5',
    bg: '#0D1814',
    card: 'rgba(59, 122, 107, 0.08)',
    text: '#E5F0EC',
    textSecondary: 'rgba(229, 240, 236, 0.6)',
    border: 'rgba(59, 122, 107, 0.15)',
    gradientStart: '#2B6A5B',
    gradientEnd: '#E0D0B0',
    glowColor: '#5A9E8E',
    style: 'glass',
    borderRadius: '12px',
    cardRadius: '20px',
    buttonRadius: '12px',
    shadow: '0 4px 12px rgba(0,0,0,0.2)',
    cardShadow: '0 8px 32px rgba(0,0,0,0.3)',
  },
  {
    name: '薄荷橙金',
    primary: '#6BCB9E',
    primaryLight: '#92DCB8',
    accent: '#F4A460',
    bg: '#0F1E17',
    card: 'rgba(107, 203, 158, 0.08)',
    text: '#E7F5EE',
    textSecondary: 'rgba(231, 245, 238, 0.6)',
    border: 'rgba(107, 203, 158, 0.15)',
    gradientStart: '#5BBA8E',
    gradientEnd: '#E89450',
    glowColor: '#92DCB8',
    style: 'glass',
    borderRadius: '12px',
    cardRadius: '20px',
    buttonRadius: '12px',
    shadow: '0 4px 12px rgba(0,0,0,0.2)',
    cardShadow: '0 8px 32px rgba(0,0,0,0.3)',
  },
  {
    name: '荧光水绿',
    primary: '#39FF14',
    primaryLight: '#7AFF5C',
    accent: '#00CED1',
    bg: '#0A1A0A',
    card: 'rgba(57, 255, 20, 0.06)',
    text: '#D9FFD9',
    textSecondary: 'rgba(217, 255, 217, 0.6)',
    border: 'rgba(57, 255, 20, 0.12)',
    gradientStart: '#28E808',
    gradientEnd: '#00A8B0',
    glowColor: '#7AFF5C',
    style: 'glass',
    borderRadius: '12px',
    cardRadius: '20px',
    buttonRadius: '12px',
    shadow: '0 4px 12px rgba(0,0,0,0.2)',
    cardShadow: '0 8px 32px rgba(0,0,0,0.3)',
  },
  {
    name: '珊瑚玫瑰雾',
    primary: '#FF7F7F',
    primaryLight: '#FFAAAA',
    accent: '#E8C6D0',
    bg: '#1A0F0F',
    card: 'rgba(255, 127, 127, 0.08)',
    text: '#F5E8E8',
    textSecondary: 'rgba(245, 232, 232, 0.6)',
    border: 'rgba(255, 127, 127, 0.15)',
    gradientStart: '#F06F6F',
    gradientEnd: '#D8B0C0',
    glowColor: '#FFAAAA',
    style: 'glass',
    borderRadius: '12px',
    cardRadius: '20px',
    buttonRadius: '12px',
    shadow: '0 4px 12px rgba(0,0,0,0.2)',
    cardShadow: '0 8px 32px rgba(0,0,0,0.3)',
  },
  {
    name: '天蓝奶黄',
    primary: '#87CEEB',
    primaryLight: '#ADE0F2',
    accent: '#FFF5C2',
    bg: '#0E1A24',
    card: 'rgba(135, 206, 235, 0.08)',
    text: '#E5F2FA',
    textSecondary: 'rgba(229, 242, 250, 0.6)',
    border: 'rgba(135, 206, 235, 0.15)',
    gradientStart: '#77BEDB',
    gradientEnd: '#F0E8A0',
    glowColor: '#ADE0F2',
    style: 'glass',
    borderRadius: '12px',
    cardRadius: '20px',
    buttonRadius: '12px',
    shadow: '0 4px 12px rgba(0,0,0,0.2)',
    cardShadow: '0 8px 32px rgba(0,0,0,0.3)',
  },
  {
    name: '雾青浅绿',
    primary: '#8FBC8F',
    primaryLight: '#B0D8B0',
    accent: '#C8F0C8',
    bg: '#0F1A0F',
    card: 'rgba(143, 188, 143, 0.08)',
    text: '#E8F2E8',
    textSecondary: 'rgba(232, 242, 232, 0.6)',
    border: 'rgba(143, 188, 143, 0.15)',
    gradientStart: '#7FAC7F',
    gradientEnd: '#B0E0B0',
    glowColor: '#B0D8B0',
    style: 'glass',
    borderRadius: '12px',
    cardRadius: '20px',
    buttonRadius: '12px',
    shadow: '0 4px 12px rgba(0,0,0,0.2)',
    cardShadow: '0 8px 32px rgba(0,0,0,0.3)',
  },
  {
    name: '深绿薄荷',
    primary: '#2E7D32',
    primaryLight: '#4CAF50',
    accent: '#A5D6A7',
    bg: '#0A180A',
    card: 'rgba(46, 125, 50, 0.08)',
    text: '#E0F0E0',
    textSecondary: 'rgba(224, 240, 224, 0.6)',
    border: 'rgba(46, 125, 50, 0.15)',
    gradientStart: '#1E6D22',
    gradientEnd: '#80C080',
    glowColor: '#4CAF50',
    style: 'glass',
    borderRadius: '12px',
    cardRadius: '20px',
    buttonRadius: '12px',
    shadow: '0 4px 12px rgba(0,0,0,0.2)',
    cardShadow: '0 8px 32px rgba(0,0,0,0.3)',
  },
  {
    name: '电光蓝紫',
    primary: '#4B6CC2',
    primaryLight: '#738ED6',
    accent: '#9B59B6',
    bg: '#0E1120',
    card: 'rgba(75, 108, 194, 0.08)',
    text: '#E0E6F5',
    textSecondary: 'rgba(224, 230, 245, 0.6)',
    border: 'rgba(75, 108, 194, 0.15)',
    gradientStart: '#3B5CB2',
    gradientEnd: '#8B49A6',
    glowColor: '#738ED6',
    style: 'glass',
    borderRadius: '12px',
    cardRadius: '20px',
    buttonRadius: '12px',
    shadow: '0 4px 12px rgba(0,0,0,0.2)',
    cardShadow: '0 8px 32px rgba(0,0,0,0.3)',
  },
  {
    name: '绿松冰蓝',
    primary: '#40E0D0',
    primaryLight: '#72ECE0',
    accent: '#AEE2FF',
    bg: '#0C1C1A',
    card: 'rgba(64, 224, 208, 0.08)',
    text: '#E0F5F2',
    textSecondary: 'rgba(224, 245, 242, 0.6)',
    border: 'rgba(64, 224, 208, 0.15)',
    gradientStart: '#30D0C0',
    gradientEnd: '#90CCF0',
    glowColor: '#72ECE0',
    style: 'glass',
    borderRadius: '12px',
    cardRadius: '20px',
    buttonRadius: '12px',
    shadow: '0 4px 12px rgba(0,0,0,0.2)',
    cardShadow: '0 8px 32px rgba(0,0,0,0.3)',
  },
]

export const useThemeStore = defineStore('theme', () => {
  const savedIndex = parseInt(localStorage.getItem('themeIndex') || '0')
  const themeIndex = ref(savedIndex >= 0 && savedIndex < themes.length ? savedIndex : 0)

  const currentTheme = computed(() => themes[themeIndex.value])
  const themeList = computed(() => themes)

  function setTheme(index: number) {
    if (index >= 0 && index < themes.length) {
      themeIndex.value = index
      localStorage.setItem('themeIndex', String(index))
      applyTheme()
      // Update cursor effects
      setCursorTheme(index)
    }
  }

  function applyTheme() {
    const t = currentTheme.value
    const root = document.documentElement
    root.style.setProperty('--primary', t.primary)
    root.style.setProperty('--primary-light', t.primaryLight)
    root.style.setProperty('--accent', t.accent)
    root.style.setProperty('--bg', t.bg)
    root.style.setProperty('--card', t.card)
    root.style.setProperty('--text', t.text)
    root.style.setProperty('--text-secondary', t.textSecondary)
    root.style.setProperty('--border', t.border)
    root.style.setProperty('--radius', t.borderRadius)
    root.style.setProperty('--card-radius', t.cardRadius)
    root.style.setProperty('--button-radius', t.buttonRadius)
    root.style.setProperty('--shadow', t.shadow)
    root.style.setProperty('--card-shadow', t.cardShadow)
    root.style.setProperty('--theme-style', t.style)
    // Initialize cursor effects on first theme application
    setCursorTheme(themeIndex.value)
  }

  return { themeIndex, currentTheme, themeList, setTheme, applyTheme }
})
