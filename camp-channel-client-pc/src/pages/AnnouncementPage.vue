<template>
  <div class="announcement-page">
    <div class="page-header">
      <h2>📢 校园公告</h2>
      <p class="subtitle">刮刮乐 / 盲盒公告中心</p>
    </div>

    <div v-if="loading" class="loading-state">
      <div class="spinner"></div>
    </div>
    <div v-else-if="announcements.length === 0" class="empty-state">
      <p>暂无活跃公告</p>
    </div>
    <div v-else class="announcement-list">
      <div
        v-for="announcement in announcements"
        :key="announcement.id"
        class="announcement-item"
      >
        <!-- Scratch card type -->
        <div v-if="announcement.type === 'scratch'" class="scratch-card-wrapper">
          <div class="scratch-label">🎫 刮刮乐</div>
          <div class="scratch-container" :ref="el => setScratchRef(el as HTMLElement, announcement.id)">
            <!-- Content underneath -->
            <div class="scratch-content">
              <h3>{{ announcement.title }}</h3>
              <p>{{ announcement.content }}</p>
            </div>
            <!-- Scratch canvas -->
            <canvas
              class="scratch-canvas"
              :ref="el => setCanvasRef(el as HTMLCanvasElement, announcement.id)"
              @mousedown="(e) => startScratch(e, announcement.id)"
              @mousemove="(e) => doScratch(e, announcement.id)"
              @mouseup="() => endScratch(announcement.id)"
              @mouseleave="() => endScratch(announcement.id)"
            ></canvas>
          </div>
        </div>

        <!-- Blind box type -->
        <div v-else class="blindbox-wrapper">
          <div class="blindbox-label">🎁 盲盒</div>
          <BlindBox
            :title="announcement.title"
            :content="announcement.content"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, nextTick } from 'vue'
import { api } from '../api/client'
import BlindBox from '../components/BlindBox.vue'

interface Announcement {
  id: number
  title: string
  content: string
  type: string
  coverImage: string | null
  createdAt: string
}

const announcements = ref<Announcement[]>([])
const loading = ref(true)
const containerRefs = ref<Record<number, HTMLElement>>({})
const canvasRefs = ref<Record<number, HTMLCanvasElement>>({})
const scratchPaths = ref<Record<number, { x: number; y: number }[]>>({})
const isDrawing = ref<Record<number, boolean>>({})

onMounted(async () => {
  await fetchAnnouncements()
  await nextTick()
  initAllCanvases()
})

async function fetchAnnouncements() {
  loading.value = true
  try {
    const res = await api.get('/announcements')
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      announcements.value = res.data.data
    }
  } catch (e) {
    console.error('Failed to fetch announcements:', e)
  } finally {
    loading.value = false
  }
}

function setScratchRef(el: HTMLElement | null, id: number) {
  if (el) containerRefs.value[id] = el
}

function setCanvasRef(el: HTMLCanvasElement | null, id: number) {
  if (el) canvasRefs.value[id] = el
}

function initAllCanvases() {
  for (const ann of announcements.value) {
    if (ann.type === 'scratch') {
      initScratchCanvas(ann.id)
    }
  }
}

function initScratchCanvas(id: number) {
  const canvas = canvasRefs.value[id]
  const container = containerRefs.value[id]
  if (!canvas || !container) return

  canvas.width = container.clientWidth
  canvas.height = container.clientHeight

  const ctx = canvas.getContext('2d')
  if (!ctx) return

  // Metallic gradient cover
  const gradient = ctx.createLinearGradient(0, 0, canvas.width, canvas.height)
  gradient.addColorStop(0, '#8d8d8d')
  gradient.addColorStop(0.35, '#c0c0c0')
  gradient.addColorStop(0.65, '#8d8d8d')
  gradient.addColorStop(1, '#b0b0b0')
  ctx.fillStyle = gradient
  ctx.fillRect(0, 0, canvas.width, canvas.height)

  // Diagonal shimmer lines
  ctx.strokeStyle = 'rgba(255, 255, 255, 0.12)'
  ctx.lineWidth = 1
  for (let offset = -canvas.height; offset < canvas.width + canvas.height; offset += 8) {
    ctx.beginPath()
    ctx.moveTo(offset, 0)
    ctx.lineTo(offset + canvas.height, canvas.height)
    ctx.stroke()
  }

  // Center text
  ctx.fillStyle = 'rgba(255, 255, 255, 0.4)'
  ctx.font = '14px sans-serif'
  ctx.textAlign = 'center'
  ctx.fillText('刮开查看', canvas.width / 2, canvas.height / 2)

  scratchPaths.value[id] = []
  isDrawing.value[id] = false
}

function getCanvasPos(e: MouseEvent, canvas: HTMLCanvasElement) {
  const rect = canvas.getBoundingClientRect()
  return { x: e.clientX - rect.left, y: e.clientY - rect.top }
}

function startScratch(e: MouseEvent, id: number) {
  isDrawing.value[id] = true
  const canvas = canvasRefs.value[id]
  if (!canvas) return
  const pos = getCanvasPos(e, canvas)
  if (!scratchPaths.value[id]) scratchPaths.value[id] = []
  scratchPaths.value[id].push(pos)
  scratch(id)
}

function doScratch(e: MouseEvent, id: number) {
  if (!isDrawing.value[id]) return
  const canvas = canvasRefs.value[id]
  if (!canvas) return
  const pos = getCanvasPos(e, canvas)
  scratchPaths.value[id].push(pos)
  scratch(id)
  checkReveal(id, canvas)
}

function endScratch(id: number) {
  isDrawing.value[id] = false
}

function scratch(id: number) {
  const canvas = canvasRefs.value[id]
  if (!canvas) return
  const ctx = canvas.getContext('2d')
  if (!ctx) return

  const points = scratchPaths.value[id] || []
  if (points.length < 2) return

  ctx.globalCompositeOperation = 'destination-out'
  ctx.strokeStyle = 'rgba(0, 0, 0, 1)'
  ctx.lineWidth = 28
  ctx.lineCap = 'round'
  ctx.lineJoin = 'round'

  const last = points[points.length - 1]
  const prev = points[points.length - 2]
  ctx.beginPath()
  ctx.moveTo(prev.x, prev.y)
  ctx.lineTo(last.x, last.y)
  ctx.stroke()

  ctx.globalCompositeOperation = 'source-over'
}

function checkReveal(id: number, canvas: HTMLCanvasElement) {
  const points = scratchPaths.value[id] || []
  const totalArea = canvas.width * canvas.height
  const scratchedArea = points.length * Math.PI * 14 * 14
  if (scratchedArea / totalArea > 0.4) {
    // Fade out the canvas
    canvas.style.transition = 'opacity 0.5s'
    canvas.style.opacity = '0'
    setTimeout(() => {
      canvas.style.display = 'none'
    }, 500)
  }
}
</script>

<style scoped>
.announcement-page {
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
  margin: 0 0 24px;
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

.announcement-list {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.scratch-card-wrapper, .blindbox-wrapper {
  position: relative;
}

.scratch-label, .blindbox-label {
  font-size: 13px;
  color: var(--text-secondary);
  margin-bottom: 8px;
  font-weight: 500;
}

.scratch-container {
  position: relative;
  width: 100%;
  height: 180px;
  border-radius: 16px;
  overflow: hidden;
}

.scratch-content {
  position: absolute;
  inset: 0;
  background: var(--card-bg);
  border: 1px solid var(--border);
  border-radius: 16px;
  padding: 20px;
  display: flex;
  flex-direction: column;
  justify-content: center;
}
.scratch-content h3 {
  color: var(--text-primary);
  margin: 0 0 8px;
  font-size: 16px;
}
.scratch-content p {
  color: var(--text-secondary);
  margin: 0;
  font-size: 14px;
  line-height: 1.6;
}

.scratch-canvas {
  position: absolute;
  inset: 0;
  z-index: 2;
  cursor: crosshair;
  border-radius: 16px;
}

@media (max-width: 768px) {
  .announcement-page {
    padding: 16px 12px;
  }

  .page-header h2 {
    font-size: 20px;
  }

  .subtitle {
    font-size: 12px;
    margin-bottom: 16px;
  }

  .scratch-container {
    height: 160px;
  }

  .scratch-content {
    padding: 14px 16px;
  }

  .scratch-content h3 {
    font-size: 15px;
  }

  .scratch-content p {
    font-size: 13px;
  }

  .scratch-label, .blindbox-label {
    font-size: 12px;
  }
}
</style>
