import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { fileURLToPath, URL } from 'node:url' // 👈 引入 node:url 模块

export default defineConfig({
  define: {
    global: 'globalThis',
  },
  plugins: [vue()],
  resolve: {
    alias: {
      // 👇 使用 fileURLToPath 完美替代 __dirname
      '@': fileURLToPath(new URL('./src', import.meta.url))
    },
  },
  server: {
    host: '0.0.0.0', // 👈 开启局域网访问
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
      },
      '/uploads': {
        target: 'http://localhost:8080/api',
        changeOrigin: true,
      },
      '/ws': {
        target: 'http://localhost:8080/api',
        changeOrigin: true,
        ws: true,
      },
    },
  },
})