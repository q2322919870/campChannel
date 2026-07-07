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
  build: {
    // 代码分割配置，优化首屏加载速度
    rollupOptions: {
      output: {
        manualChunks: {
          'vue-vendor': ['vue', 'vue-router', 'pinia'],
          'stomp-vendor': ['@stomp/stompjs', 'sockjs-client'],
        },
        chunkFileNames: 'assets/js/[name]-[hash].js',
        entryFileNames: 'assets/js/[name]-[hash].js',
        assetFileNames: 'assets/[ext]/[name]-[hash].[ext]',
      },
    },
    // 提高块大小警告阈值（大型 SPA 必然有较大块）
    chunkSizeWarningLimit: 1000,
    // 启用 CSS 代码分割
    cssCodeSplit: true,
    // 启用 minify
    minify: 'esbuild',
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