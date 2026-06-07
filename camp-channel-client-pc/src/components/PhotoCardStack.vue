<template>
  <div class="photo-stack-wrap">
    <div v-if="loading" class="stack-state">加载画作...</div>
    <div v-else-if="!items.length" class="stack-state">
      <span>暂无画作，点击右下角添加</span>
    </div>
    <div v-else class="photo-stack-scene">
      <div
        class="photo-stack"
        @pointerup="onPointerUp"
        @pointercancel="onPointerUp"
        @pointerleave="onPointerUp"
      >
        <div
          v-for="{ item, stackIndex } in visibleStack"
          :key="`${item.id}-${stackIndex}`"
          class="stack-card"
          :class="{
            top: stackIndex === 0,
            dragging: stackIndex === 0 && isDragging,
            exiting: stackIndex === 0 && isExiting,
          }"
          :style="cardStyle(stackIndex)"
          @pointerdown="stackIndex === 0 ? onPointerDown($event) : undefined"
          @pointermove="stackIndex === 0 ? onPointerMove($event) : undefined"
          @click="onCardClick(stackIndex)"
        >
          <div class="stack-card-inner">
            <img :src="item.imageUrl" :alt="item.title || '画作'" draggable="false" />
            <div v-if="item.isVideo" class="video-badge">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>
            </div>
          </div>
          <div v-if="stackIndex === 0" class="stack-card-footer">
            <span class="stack-title">{{ item.title || '无标题' }}</span>
            <span class="stack-author">@{{ item.username || '匿名' }}</span>
          </div>
        </div>
      </div>
      <div class="stack-meta">
        <span class="stack-count">{{ items.length }} 幅</span>
        <span class="stack-hint">拖拽切换 · 点击查看</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { api } from '@/api/client'

export interface StackGalleryItem {
  id: number
  imageUrl: string
  videoUrl?: string
  mediaType?: number
  title?: string
  username?: string
  userId?: number
  isVideo?: boolean
}

const props = withDefaults(defineProps<{ autoLoad?: boolean; channelId?: number }>(), {
  autoLoad: true,
  channelId: 0,
})
const emit = defineEmits<{ 'item-click': [item: StackGalleryItem] }>()

const loading = ref(true)
const items = ref<StackGalleryItem[]>([])
const stackOrder = ref<number[]>([])
const dragX = ref(0)
const dragY = ref(0)
const isDragging = ref(false)
const isExiting = ref(false)
const dragMoved = ref(false)

const MAX_VISIBLE = 5
let startX = 0
let startY = 0
let activePointerId: number | null = null

const visibleStack = computed(() =>
  stackOrder.value.slice(0, MAX_VISIBLE).map((dataIndex, stackIndex) => ({
    item: items.value[dataIndex],
    stackIndex,
    dataIndex,
  })).filter((entry) => entry.item),
)

function cardStyle(stackIndex: number) {
  if (stackIndex === 0 && (isDragging.value || isExiting.value)) {
    const rot = dragX.value * 0.06
    return {
      transform: `translate(${dragX.value}px, ${dragY.value}px) rotate(${rot}deg)`,
      zIndex: 100,
    }
  }
  const rotations = [0, -7, 6, -4, 3]
  const rot = rotations[stackIndex] ?? 0
  const y = stackIndex * 12
  const x = stackIndex % 2 === 0 ? stackIndex * 6 : -stackIndex * 6
  const scale = 1 - stackIndex * 0.045
  return {
    transform: `translate(${x}px, ${y}px) rotate(${rot}deg) scale(${scale})`,
    zIndex: 50 - stackIndex,
    opacity: stackIndex > 3 ? 0.55 : 1,
  }
}

function onPointerDown(e: PointerEvent) {
  if (isExiting.value || stackOrder.value.length === 0) return
  isDragging.value = true
  dragMoved.value = false
  startX = e.clientX - dragX.value
  startY = e.clientY - dragY.value
  activePointerId = e.pointerId
  ;(e.currentTarget as HTMLElement).setPointerCapture(e.pointerId)
}

function onPointerMove(e: PointerEvent) {
  if (!isDragging.value || activePointerId !== e.pointerId) return
  dragX.value = e.clientX - startX
  dragY.value = (e.clientY - startY) * 0.45
  if (Math.abs(dragX.value) > 4 || Math.abs(dragY.value) > 4) {
    dragMoved.value = true
  }
}

function onPointerUp() {
  if (!isDragging.value) return
  isDragging.value = false
  activePointerId = null

  const threshold = 90
  if (Math.abs(dragX.value) > threshold || Math.abs(dragY.value) > threshold) {
    cycleTopCard()
  } else {
    dragX.value = 0
    dragY.value = 0
  }
}

function cycleTopCard() {
  isExiting.value = true
  const dir = dragX.value >= 0 ? 1 : -1
  dragX.value = dir * 420
  dragY.value += dir > 0 ? 40 : -40

  window.setTimeout(() => {
    const first = stackOrder.value.shift()
    if (first !== undefined) stackOrder.value.push(first)
    dragX.value = 0
    dragY.value = 0
    isExiting.value = false
  }, 320)
}

function onCardClick(stackIndex: number) {
  if (stackIndex !== 0 || dragMoved.value || isExiting.value) return
  const idx = stackOrder.value[0]
  const item = items.value[idx]
  if (item) emit('item-click', item)
}

async function loadItems() {
  loading.value = true
  try {
    const params: Record<string, number> = { page: 1, size: 30 }
    if (props.channelId && props.channelId > 0) params.channelId = props.channelId
    const res = await api.get('/gallery', { params })
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      items.value = res.data.data
        .map((g: Record<string, unknown>) => {
          const mediaType = g.mediaType
          const isVideo = mediaType === 2 || mediaType === '2'
          return {
            id: g.id as number,
            imageUrl: (g.imageUrl as string) || '',
            videoUrl: (g.videoUrl as string) || '',
            mediaType: isVideo ? 2 : 1,
            title: (g.title as string) || '',
            username: (g.username as string) || '',
            userId: g.userId as number,
            isVideo,
          }
        })
        .filter((g: StackGalleryItem) => g.imageUrl)
      stackOrder.value = items.value.map((_, i) => i)
    }
  } catch {
    /* ignore */
  }
  loading.value = false
}

function handleGalleryRefresh() {
  loadItems()
}

watch(() => props.channelId, () => {
  if (props.autoLoad) loadItems()
})

onMounted(() => {
  if (props.autoLoad) loadItems()
  window.addEventListener('gallery-refresh', handleGalleryRefresh)
})

onUnmounted(() => {
  window.removeEventListener('gallery-refresh', handleGalleryRefresh)
})
</script>

<style scoped>
.photo-stack-wrap {
  width: 100%;
  min-height: 420px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.stack-state {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 320px;
  color: var(--on-surface-variant);
  font-size: 14px;
}

.photo-stack-scene {
  width: 100%;
  max-width: 520px;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 20px;
}

.photo-stack {
  position: relative;
  width: min(100%, 380px);
  height: 380px;
  perspective: 1200px;
  user-select: none;
  touch-action: none;
}

.stack-card {
  position: absolute;
  left: 50%;
  top: 0;
  width: 280px;
  margin-left: -140px;
  border-radius: 20px;
  background: var(--card-bg, rgba(255, 255, 255, 0.1));
  border: 2px solid var(--border-color, rgba(255, 255, 255, 0.25));
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  box-shadow: 0 12px 40px rgba(0, 0, 0, 0.18);
  overflow: hidden;
  transition: transform 0.35s cubic-bezier(0.34, 1.2, 0.64, 1), opacity 0.3s;
  cursor: grab;
  will-change: transform;
}

.stack-card.top {
  cursor: grab;
}

.stack-card.dragging {
  cursor: grabbing;
  transition: none;
}

.stack-card.exiting {
  transition: transform 0.32s cubic-bezier(0.4, 0, 0.2, 1), opacity 0.32s;
  opacity: 0;
}

.stack-card:not(.top) {
  pointer-events: none;
  cursor: default;
}

.stack-card-inner {
  position: relative;
  aspect-ratio: 4 / 5;
  overflow: hidden;
  background: rgba(0, 0, 0, 0.15);
}

.stack-card-inner img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
  pointer-events: none;
}

.video-badge {
  position: absolute;
  bottom: 10px;
  right: 10px;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background: rgba(0, 0, 0, 0.45);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  backdrop-filter: blur(8px);
}

.stack-card-footer {
  padding: 14px 16px;
  display: flex;
  flex-direction: column;
  gap: 4px;
  background: var(--article-bg, rgba(255, 255, 255, 0.14));
  border-top: 1px solid var(--border-color, rgba(255, 255, 255, 0.15));
}

.stack-title {
  font-size: 15px;
  font-weight: 600;
  color: var(--text, var(--on-surface));
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.stack-author {
  font-size: 12px;
  color: var(--brand, var(--primary));
}

.stack-meta {
  display: flex;
  align-items: center;
  gap: 16px;
  font-size: 13px;
  color: var(--on-surface-variant);
}

.stack-count {
  padding: 6px 14px;
  border-radius: 999px;
  background: var(--card-bg);
  border: 1px solid var(--border-color);
  font-weight: 600;
  color: var(--brand, var(--primary));
}

.stack-hint {
  opacity: 0.75;
}

@media (min-width: 1024px) {
  .photo-stack-scene {
    max-width: 560px;
  }

  .photo-stack {
    width: 400px;
    height: 400px;
  }

  .stack-card {
    width: 300px;
    margin-left: -150px;
  }
}
</style>
