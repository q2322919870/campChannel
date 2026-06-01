<template>
  <div class="tree-hole-page">
    <div class="page-header">
      <h2>🌙 树洞告白墙</h2>
      <p class="subtitle">匿名倾诉，让心事随风</p>
    </div>

    <!-- Compose area -->
    <div class="compose-card glass-card">
      <textarea
        v-model="newContent"
        placeholder="写下你的匿名告白..."
        rows="3"
        maxlength="500"
      ></textarea>
      <div class="compose-actions">
        <span class="char-count">{{ newContent.length }}/500</span>
        <button class="btn-primary" :disabled="!newContent.trim() || isPosting" @click="submitConfession">
          {{ isPosting ? '发布中...' : '匿名发布' }}
        </button>
      </div>
    </div>

    <!-- Posts list with mist reveal -->
    <div v-if="loading" class="loading-state">
      <div class="spinner"></div>
    </div>
    <div v-else-if="posts.length === 0" class="empty-state">
      <p>还没有匿名告白，成为第一个吧 ✨</p>
    </div>
    <div v-else class="posts-grid">
      <div
        v-for="(post, index) in posts"
        :key="post.id"
        class="confession-card"
        :ref="el => cardRefs[index] = el as HTMLElement"
      >
        <!-- Mist canvas overlay -->
        <canvas
          class="mist-canvas"
          :ref="el => canvasRefs[index] = el as HTMLCanvasElement"
          @mousedown="(e) => startReveal(e, index)"
          @mousemove="(e) => doReveal(e, index)"
          @mouseup="() => endReveal(index)"
          @mouseleave="() => endReveal(index)"
          @touchstart="(e) => startRevealTouch(e, index)"
          @touchmove="(e) => doRevealTouch(e, index)"
          @touchend="() => endReveal(index)"
        ></canvas>
        <div class="card-content">
          <div class="card-header">
            <span class="anonymous-badge">匿名</span>
            <span v-if="post.likeCount > 0" class="like-count">❤️ {{ post.likeCount }}</span>
          </div>
          <p class="card-text">{{ post.content }}</p>
          <span class="card-time">{{ formatTime(post.createTime) }}</span>
        </div>
        <div v-if="!revealed[index] && !isDrawing[index]" class="reveal-hint">
          <div class="hint-content">
            <div class="hint-icon">🖱️</div>
            <div class="hint-main">拖动鼠标，揭开迷雾</div>
            <div class="hint-sub">在屏幕上滑动来解密内容</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import { api } from '../api/client'

interface Post {
  id: number
  content: string
  createTime: string
  likeCount: number
  isAnonymous: boolean
  isRevealed?: boolean  // 从服务器返回的解开状态
}

const posts = ref<Post[]>([])
const loading = ref(true)
const newContent = ref('')
const isPosting = ref(false)
const cardRefs = ref<Record<number, HTMLElement>>({})
const canvasRefs = ref<Record<number, HTMLCanvasElement>>({})
const revealed = ref<Record<number, boolean>>({})
const revealPaths = ref<Record<number, { x: number; y: number }[]>>({})
const isDrawing = ref<Record<number, boolean>>({})
const fogCanvases = ref<Record<number, HTMLCanvasElement>>({}) // Offscreen canvases for fog layer

onMounted(async () => {
  await fetchPosts()
  await nextTick()
  initAllCanvases()
  
  // Add global event listeners to handle mouseup outside canvas
  window.addEventListener('mouseup', handleGlobalMouseUp)
  window.addEventListener('mouseleave', handleGlobalMouseUp)
})

onUnmounted(() => {
  window.removeEventListener('mouseup', handleGlobalMouseUp)
  window.removeEventListener('mouseleave', handleGlobalMouseUp)
})

function handleGlobalMouseUp() {
  // Clear all drawing states
  for (const key in isDrawing.value) {
    isDrawing.value[Number(key)] = false
  }
}

async function fetchPosts() {
  loading.value = true
  try {
    const res = await api.get('/posts/tree-hole', {
      params: { page: 1, size: 50 }
    })
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      posts.value = res.data.data
    }
  } catch (e) {
    console.error('Failed to fetch tree hole posts:', e)
  } finally {
    loading.value = false
  }
}

async function submitConfession() {
  const content = newContent.value.trim()
  if (!content || isPosting.value) return
  isPosting.value = true
  try {
    const res = await api.post('/posts', {
      content,
      isAnonymous: true,
      channelId: null  // Tree hole posts don't belong to a channel
    })
    if (res.data.code === 200) {
      newContent.value = ''
      await fetchPosts()
      await nextTick()
      initAllCanvases()
    }
  } catch (e) {
    console.error('Failed to submit:', e)
  } finally {
    isPosting.value = false
  }
}

function initAllCanvases() {
  for (let i = 0; i < posts.value.length; i++) {
    initCanvas(i)
  }
}

function initCanvas(index: number) {
  const canvas = canvasRefs.value[index]
  if (!canvas) return
  const card = cardRefs.value[index]
  if (!card) return

  // Force reflow to ensure accurate dimensions
  card.offsetHeight
  
  // Set canvas internal resolution to match CSS display size
  const rect = card.getBoundingClientRect()
  canvas.width = rect.width
  canvas.height = rect.height
  
  // Set CSS size explicitly to match
  canvas.style.width = rect.width + 'px'
  canvas.style.height = rect.height + 'px'
  
  console.log(`Canvas ${index} initialized: ${canvas.width}x${canvas.height}, rect: ${rect.width}x${rect.height}`)

  // 检查服务器返回的解开状态
  const post = posts.value[index]
  if (post && post.isRevealed) {
    // 已解开，不初始化迷雾
    console.log(`Post ${post.id} already revealed, skipping fog`)
    revealed.value[index] = true
    revealPaths.value[index] = []
    isDrawing.value[index] = false
    return
  }

  // Initialize state first
  revealPaths.value[index] = []
  revealed.value[index] = false
  isDrawing.value[index] = false
  
  // Don't create fogCanvas here - let drawMist create and initialize it
  delete fogCanvases.value[index]
  
  // Now draw the mist (this will create fogCanvas and populate it with fog)
  drawMist(canvas, index)
}

function drawMist(canvas: HTMLCanvasElement, index: number) {
  const ctx = canvas.getContext('2d')
  if (!ctx) return
  const w = canvas.width
  const h = canvas.height
  const points = revealPaths.value[index] || []

  // Get or create offscreen fog canvas
  let fogCanvas = fogCanvases.value[index]
  if (!fogCanvas) {
    fogCanvas = document.createElement('canvas')
    fogCanvas.width = w
    fogCanvas.height = h
    fogCanvases.value[index] = fogCanvas
    
    // Initialize fog canvas with the fog layer
    const fogCtx = fogCanvas.getContext('2d')
    if (fogCtx) {
      // Base fog - completely opaque to hide content
      const gradient = fogCtx.createLinearGradient(0, 0, w, h)
      gradient.addColorStop(0, 'rgba(26, 26, 46, 1.0)')
      gradient.addColorStop(0.5, 'rgba(44, 44, 84, 1.0)')
      gradient.addColorStop(1, 'rgba(26, 26, 46, 1.0)')
      fogCtx.fillStyle = gradient
      fogCtx.fillRect(0, 0, w, h)

      // Mist swirls
      const time = performance.now() / 1000
      for (let i = 0; i < 5; i++) {
        const cx = (w * (i + 1)) / 6 + Math.sin(time * 0.3 + i) * 20
        const cy = h / 2 + Math.cos(time * 0.25 + i * 1.5) * 15
        const r = 40 + i * 10
        const grd = fogCtx.createRadialGradient(cx, cy, 0, cx, cy, r)
        grd.addColorStop(0, 'rgba(108, 99, 255, 0.12)')
        grd.addColorStop(1, 'transparent')
        fogCtx.fillStyle = grd
        fogCtx.fillRect(0, 0, w, h)
      }
    }
  }

  // Clear main canvas
  ctx.clearRect(0, 0, w, h)

  // Draw the fog layer from offscreen canvas
  ctx.drawImage(fogCanvas, 0, 0)

  // If there are new points, clear them on both canvases
  if (points.length > 0) {
    console.log(`Drawing ${points.length} clear points on card ${index}`)
    
    // Clear on fog canvas (persistent)
    const fogCtx = fogCanvas.getContext('2d')
    if (fogCtx) {
      fogCtx.globalCompositeOperation = 'destination-out'
      // Only draw the latest point (the one just added)
      const lastPoint = points[points.length - 1]
      fogCtx.beginPath()
      fogCtx.arc(lastPoint.x, lastPoint.y, 35, 0, Math.PI * 2)
      fogCtx.fill()
      fogCtx.globalCompositeOperation = 'source-over'
    }
    
    // Clear on main canvas
    ctx.globalCompositeOperation = 'destination-out'
    ctx.beginPath()
    ctx.arc(points[points.length - 1].x, points[points.length - 1].y, 35, 0, Math.PI * 2)
    ctx.fill()
    ctx.globalCompositeOperation = 'source-over'
  }
}

function getCanvasPos(e: MouseEvent, canvas: HTMLCanvasElement) {
  const rect = canvas.getBoundingClientRect()
  // Calculate position relative to canvas, accounting for any CSS scaling
  const scaleX = canvas.width / rect.width
  const scaleY = canvas.height / rect.height
  const x = (e.clientX - rect.left) * scaleX
  const y = (e.clientY - rect.top) * scaleY
  
  console.log(`Mouse at client: ${e.clientX},${e.clientY}, rect: ${rect.left},${rect.top}, canvas: ${x.toFixed(1)},${y.toFixed(1)}`)
  
  return { x, y }
}

function startReveal(e: MouseEvent, index: number) {
  e.preventDefault()
  e.stopPropagation()
  isDrawing.value[index] = true
  const canvas = canvasRefs.value[index]
  if (!canvas) return
  const pos = getCanvasPos(e, canvas)
  if (!revealPaths.value[index]) revealPaths.value[index] = []
  revealPaths.value[index].push(pos)
  console.log(`Start drawing at card ${index}, pos: ${pos.x.toFixed(1)},${pos.y.toFixed(1)}, canvas size: ${canvas.width}x${canvas.height}`)
  drawMist(canvas, index)
}

function doReveal(e: MouseEvent, index: number) {
  if (!isDrawing.value[index]) return
  e.preventDefault()
  e.stopPropagation()
  const canvas = canvasRefs.value[index]
  if (!canvas) return
  const pos = getCanvasPos(e, canvas)
  revealPaths.value[index].push(pos)
  drawMist(canvas, index)
  checkReveal(index, canvas)
}

function startRevealTouch(e: TouchEvent, index: number) {
  e.preventDefault()
  isDrawing.value[index] = true
  const canvas = canvasRefs.value[index]
  if (!canvas) return
  const touch = e.touches[0]
  const pos = getCanvasPosFromTouch(touch, canvas)
  if (!revealPaths.value[index]) revealPaths.value[index] = []
  revealPaths.value[index].push(pos)
  drawMist(canvas, index)
}

function doRevealTouch(e: TouchEvent, index: number) {
  if (!isDrawing.value[index]) return
  e.preventDefault()
  const canvas = canvasRefs.value[index]
  if (!canvas) return
  const touch = e.touches[0]
  const pos = getCanvasPosFromTouch(touch, canvas)
  revealPaths.value[index].push(pos)
  drawMist(canvas, index)
  checkReveal(index, canvas)
}

function getCanvasPosFromTouch(touch: Touch, canvas: HTMLCanvasElement) {
  const rect = canvas.getBoundingClientRect()
  const x = (touch.clientX - rect.left) * (canvas.width / rect.width)
  const y = (touch.clientY - rect.top) * (canvas.height / rect.height)
  return { x, y }
}

function endReveal(index: number) {
  isDrawing.value[index] = false
}

function checkReveal(index: number, canvas: HTMLCanvasElement) {
  const points = revealPaths.value[index] || []
  const totalArea = canvas.width * canvas.height
  const revealedArea = points.length * Math.PI * 35 * 35  // Match brush radius
  const revealedRatio = revealedArea / totalArea
  
  console.log(`[CheckReveal] Card ${index}: ratio=${(revealedRatio * 100).toFixed(1)}%, threshold=85%`)
  
  // If 85% or more is revealed, trigger full reveal with animation
  // Higher threshold makes it more challenging and fun
  if (revealedRatio > 0.85) {
    console.log(`[CheckReveal] Threshold reached, revealing card ${index}`)
    revealed.value[index] = true
    
    // 保存到服务器，实现跨平台同步
    const post = posts.value[index]
    if (post && post.id) {
      api.post(`/posts/${post.id}/reveal`).catch(e => {
        console.error('Failed to save reveal state:', e)
      })
    }
    
    // Add fade-out animation to canvas
    const canvasEl = canvasRefs.value[index]
    if (canvasEl) {
      canvasEl.style.transition = 'opacity 0.6s ease-in-out'
      canvasEl.style.opacity = '0'
      
      // Remove canvas after animation
      setTimeout(() => {
        if (canvasEl) {
          canvasEl.style.display = 'none'
        }
      }, 600)
    }
  }
}

function formatTime(time: string): string {
  if (!time) return ''
  return time.substring(0, 16).replace('T', ' ')
}
</script>

<style scoped>
.tree-hole-page {
  padding: 24px 32px;
  max-width: 800px;
  margin: 0 auto;
  min-height: 100vh;
}

.page-header h2 {
  color: var(--text-primary);
  margin: 0 0 4px;
}
.subtitle {
  color: var(--text-secondary);
  font-size: 13px;
  margin: 0 0 20px;
}

.compose-card {
  margin-bottom: 24px;
}
.compose-card textarea {
  width: 100%;
  background: transparent;
  border: none;
  color: var(--text-primary);
  font-size: 14px;
  resize: none;
  outline: none;
  font-family: inherit;
}
.compose-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 8px;
}
.char-count {
  color: var(--text-secondary);
  font-size: 12px;
}
.btn-primary {
  padding: 6px 18px;
  border: none;
  border-radius: 8px;
  background: var(--primary);
  color: #fff;
  cursor: pointer;
  font-size: 13px;
  transition: opacity 0.2s;
}
.btn-primary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.loading-state, .empty-state {
  text-align: center;
  padding: 60px 0;
  color: var(--text-secondary);
}
.spinner {
  width: 32px;
  height: 32px;
  border: 3px solid var(--border);
  border-top-color: var(--primary);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
  margin: 0 auto;
}
@keyframes spin { to { transform: rotate(360deg); } }

.posts-grid {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.confession-card {
  position: relative;
  border-radius: 14px;
  overflow: hidden;
  background: var(--card-bg);
  border: 1px solid var(--border);
  min-height: 100px;
}

.mist-canvas {
  position: absolute;
  inset: 0;
  z-index: 10;  /* Higher than hint */
  cursor: crosshair;
  width: 100%;
  height: 100%;
  touch-action: none;  /* Prevent default touch behavior */
}

.card-content {
  padding: 18px 20px;
  position: relative;
  z-index: 1;
}
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}
.anonymous-badge {
  background: var(--primary);
  color: #fff;
  padding: 2px 10px;
  border-radius: 12px;
  font-size: 11px;
}
.like-count {
  font-size: 12px;
  color: var(--text-secondary);
}
.card-text {
  color: var(--text-primary);
  font-size: 14px;
  line-height: 1.7;
  margin: 0 0 8px;
}
.card-time {
  font-size: 11px;
  color: var(--text-secondary);
}
.reveal-hint {
  position: absolute;
  inset: 0;
  z-index: 15;  /* Higher than canvas so users can see it */
  display: flex;
  align-items: center;
  justify-content: center;
  pointer-events: none;
  transition: opacity 0.3s ease;
}

.hint-content {
  text-align: center;
  animation: hintPulse 2s ease-in-out infinite;
}

.hint-icon {
  font-size: 48px;
  margin-bottom: 12px;
  filter: drop-shadow(0 2px 8px rgba(108, 99, 255, 0.3));
}

.hint-main {
  color: rgba(255, 255, 255, 0.95);
  font-size: 16px;
  font-weight: 600;
  letter-spacing: 0.5px;
  margin-bottom: 6px;
  text-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
}

.hint-sub {
  color: rgba(255, 255, 255, 0.6);
  font-size: 13px;
  text-shadow: 0 1px 4px rgba(0, 0, 0, 0.3);
}

@keyframes hintPulse {
  0%, 100% {
    opacity: 0.8;
    transform: scale(1);
  }
  50% {
    opacity: 1;
    transform: scale(1.02);
  }
}

@media (max-width: 768px) {
  .tree-hole-page {
    padding: 16px 12px;
  }

  .page-header h2 {
    font-size: 20px;
  }

  .subtitle {
    font-size: 12px;
  }

  .compose-card {
    padding: 12px;
  }

  .compose-card textarea {
    font-size: 14px;
  }

  .btn-primary {
    padding: 8px 20px;
    font-size: 14px;
  }

  .card-content {
    padding: 14px 16px;
  }

  .card-text {
    font-size: 13px;
    line-height: 1.6;
  }

  .hint-icon {
    font-size: 36px;
  }

  .hint-main {
    font-size: 14px;
  }

  .hint-sub {
    font-size: 12px;
  }
}
</style>
