<template>
  <div ref="containerRef" class="post-3d-gallery" @wheel.prevent>
    <div v-if="loading" class="gallery-loading">加载3D画廊...</div>
    <div v-else-if="!items.length" class="gallery-empty">
      <span>暂无画作，点击右下角 🖼️ 添加</span>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch, nextTick } from 'vue'
import { useThemeStore } from '@/stores/theme'
import { Post3DGallery, type Gallery3DItem } from '@/canvas/Post3DGallery'
import { api } from '@/api/client'

const props = withDefaults(defineProps<{ autoLoad?: boolean; channelId?: number }>(), { autoLoad: true, channelId: 0 })
const emit = defineEmits<{ 'item-click': [item: Gallery3DItem] }>()

const themeStore = useThemeStore()
const containerRef = ref<HTMLDivElement>()
const loading = ref(true)
const items = ref<Gallery3DItem[]>([])
let gallery: Post3DGallery | null = null

async function loadItems() {
  loading.value = true
  try {
    const params: any = { page: 1, size: 20 }
    if (props.channelId && props.channelId > 0) params.channelId = props.channelId
    const res = await api.get('/gallery', { params })
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      items.value = res.data.data.map((g: any) => ({
        id: g.id,
        imageUrl: g.imageUrl || '',
        videoUrl: g.videoUrl || '',
        mediaType: g.mediaType || 1,
        title: g.title || '',
        username: g.username || '',
        userId: g.userId,
      }))
      if (items.value.length > 0) {
        await nextTick()
        initGallery(items.value)
      }
    }
  } catch {}
  loading.value = false
}

function initGallery(data: Gallery3DItem[]) {
  if (!containerRef.value || containerRef.value.clientHeight === 0) return
  try {
    gallery?.destroy()
    gallery = new Post3DGallery(containerRef.value, data, {
      primary: themeStore.currentTheme.primary,
      accent: themeStore.currentTheme.accent,
    })
    gallery.onSelect((item) => {
      emit('item-click', item)
    })
    gallery.start()
  } catch (err) {
    console.warn('3D gallery init failed', err)
  }
}

watch(() => themeStore.themeIndex, () => {
  if (gallery && items.value.length > 0) gallery.updateColors(themeStore.currentTheme.primary, themeStore.currentTheme.accent)
})

watch(() => props.channelId, () => {
  if (props.autoLoad) loadItems()
})

// Listen for gallery refresh events
function handleGalleryRefresh() {
  console.log('Gallery refresh triggered')
  loadItems()
}

onMounted(() => { 
  if (props.autoLoad) loadItems()
  // Listen for custom refresh event
  window.addEventListener('gallery-refresh', handleGalleryRefresh)
})

onUnmounted(() => { 
  gallery?.destroy()
  // Clean up event listener
  window.removeEventListener('gallery-refresh', handleGalleryRefresh)
})
</script>

<style scoped>
.post-3d-gallery { width: 100%; height: 360px; position: relative; overflow: hidden; border-radius: 20px; background: transparent; }
.gallery-loading, .gallery-empty { display: flex; align-items: center; justify-content: center; height: 100%; color: var(--on-surface-variant); font-size: 14px; }
</style>
