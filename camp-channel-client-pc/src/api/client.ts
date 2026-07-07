import axios from 'axios'
import type { AxiosInstance, InternalAxiosRequestConfig, AxiosResponse } from 'axios'

const api: AxiosInstance = axios.create({
  baseURL: '/api',
  timeout: 15000,
  headers: { 'Content-Type': 'application/json' },
})

// Token refresh lock to prevent concurrent refresh requests
let isRefreshing = false
let refreshSubscribers: Array<(token: string) => void> = []

function subscribeTokenRefresh(cb: (token: string) => void) {
  refreshSubscribers.push(cb)
}

function onTokenRefreshed(token: string) {
  refreshSubscribers.forEach(cb => cb(token))
  refreshSubscribers = []
}

api.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  const token = localStorage.getItem('token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

api.interceptors.response.use(
  (response: AxiosResponse) => response,
  (error) => {
    const originalRequest = error.config as InternalAxiosRequestConfig & { _retry?: boolean }
    
    if (error.response?.status === 401 && !originalRequest._retry) {
      const hadToken = localStorage.getItem('token')
      
      // If already refreshing, queue this request
      if (isRefreshing) {
        return new Promise((resolve) => {
          subscribeTokenRefresh((newToken: string) => {
            originalRequest.headers.Authorization = `Bearer ${newToken}`
            resolve(api(originalRequest))
          })
        })
      }
      
      originalRequest._retry = true
      isRefreshing = true
      
      return api.post('/auth/refresh', { refreshToken: hadToken })
        .then((res) => {
          isRefreshing = false
          let rawToken = res.data.data.token
          if (rawToken.startsWith('Bearer ')) {
            rawToken = rawToken.substring(7)
          }
          localStorage.setItem('token', rawToken)
          onTokenRefreshed(rawToken)
          originalRequest.headers.Authorization = `Bearer ${rawToken}`
          return api(originalRequest)
        })
        .catch((refreshError) => {
          isRefreshing = false
          onTokenRefreshed('')
          localStorage.removeItem('token')
          localStorage.removeItem('user')
          window.location.hash = '#/login'
          return Promise.reject(refreshError)
        })
    }
    return Promise.reject(error)
  }
)

export { api }
