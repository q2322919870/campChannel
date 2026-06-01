import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { api } from '../api/client'
import type { User } from '../types'

export const useAuthStore = defineStore('auth', () => {
  const token = ref(localStorage.getItem('token') || '')
  const user = ref<User | null>(null)

  const isLoggedIn = computed(() => !!token.value)
  const isAdmin = computed(() => user.value?.role === 'sys_admin')
  const username = computed(() => user.value?.username || '')

  async function login(email: string, password: string) {
    const res = await api.post('/auth/login', { email, password })
    const data = res.data
    if (data.code === 200) {
      // Backend returns token with "Bearer " prefix, strip it for storage
      let rawToken = data.data.token
      if (rawToken.startsWith('Bearer ')) {
        rawToken = rawToken.substring(7)
      }
      token.value = rawToken
      user.value = {
        id: data.data.userId,
        username: data.data.username,
        email: data.data.email,
        role: data.data.role,
        avatar: data.data.avatar || '',
        status: 1,
      }
      localStorage.setItem('token', rawToken)
      localStorage.setItem('user', JSON.stringify(user.value))
      return true
    }
    throw new Error(data.message || '登录失败')
  }

  async function register(email: string, username: string, password: string, code: string, realName?: string) {
    const res = await api.post('/auth/register', { email, username, password, code, realName })
    if (res.data.code === 200) return true
    throw new Error(res.data.message || '注册失败')
  }

  function logout() {
    token.value = ''
    user.value = null
    localStorage.removeItem('token')
    localStorage.removeItem('user')
  }

  function loadFromStorage() {
    const saved = localStorage.getItem('user')
    if (saved) {
      try { user.value = JSON.parse(saved) } catch {}
    }
  }

  return { token, user, isLoggedIn, isAdmin, username, login, register, logout, loadFromStorage }
})
