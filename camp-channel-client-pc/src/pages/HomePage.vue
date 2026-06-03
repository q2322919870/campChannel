<template>
  <div class="home-page">
    <div class="home-header">
      <div class="header-row">
        <h1 class="page-title">首页</h1>
        <div class="header-actions">
          <button class="hot-btn" @click="router.push('/hot-posts')" title="热门帖子">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M12 2c.5 2.5 2 4.5 2 7a4 4 0 1 1-8 0c0-2.5 1.5-4.5 2-7"></path>
            </svg>
          </button>
          <button class="search-btn" @click="router.push('/search')">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="11" cy="11" r="8"></circle>
              <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
            </svg>
          </button>
        </div>
      </div>
      <div v-if="channelTabs.length > 0" class="channel-tabs">
        <span
          class="channel-tab"
          :class="{ active: currentTab === 'following' }"
          @click="switchChannel('following')"
        >
          👥 关注
        </span>
        <span
          v-for="tab in channelTabs"
          :key="tab.id"
          class="channel-tab"
          :class="{ active: currentTab === tab.id }"
          @click="switchChannel(tab.id)"
        >
          {{ tab.name }}
          <span v-if="tab.unread" class="tab-badge">{{ tab.unread }}</span>
        </span>
      </div>
    </div>

    <div class="gallery-section" v-if="showGallery">
      <Post3DViewer @item-click="onGalleryItemClick" :channelId="currentChannelId" />
    </div>

    <div class="posts-grid">
      <ShaderPostCard v-for="post in posts" :key="post.id" :mood="(channelTabs.length && post.id % 3 === 0) ? 'glitch' : 'glass'" :intensity="0.2">
        <div class="post-card" @click="viewPost(post.id)" :class="{ pinned: post.isPinned }">
        <div v-if="post.isPinned" class="pin-badge">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor"><path d="M16 12V4h1V2H7v2h1v8l-2 2v2h5.2v6h1.6v-6H18v-2l-2-2z"/></svg>
          置顶
        </div>
        <div class="post-header">
          <div class="post-avatar" @click.stop="showUserCard(post.userId || post.id)">
          <img v-if="post.avatar" :src="post.avatar" class="post-avatar-img" />
          <span v-else>{{ post.author ? post.author.charAt(0) : '?' }}</span>
        </div>
          <div class="post-meta">
            <span class="post-author">{{ post.author || '未知用户' }}</span>
            <span v-if="post.userChannelRole" class="role-badge" :class="'role-' + post.userChannelRole">{{ roleLabel(post.userChannelRole) }}</span>
            <span class="post-time">{{ post.time || '' }}</span>
          </div>
          <span class="post-channel">{{ post.channelName || '' }}</span>
        </div>
        <h3 class="post-title">{{ post.title }}</h3>
        <p class="post-content">{{ post.content }}</p>
        <div v-if="post.images && post.images.length" class="post-images">
          <template v-for="(img, i) in post.images.slice(0, 3)" :key="'img-' + i">
            <img :src="img" @click.stop />
          </template>
        </div>
        <div v-if="post.videoUrls && post.videoUrls.length" class="post-videos">
          <video v-for="(vid, i) in post.videoUrls.slice(0, 1)" :key="'vid-' + i" :src="vid" class="post-video" controls @click.stop />
        </div>
        <div class="post-actions">
          <button class="action-btn" :class="{ liked: post.isLiked }" @click.stop="toggleLike(post, $event)">
            <svg width="16" height="16" viewBox="0 0 24 24" :fill="post.isLiked ? 'currentColor' : 'none'" stroke="currentColor" stroke-width="2"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>
            {{ post.likeCount || 0 }}
          </button>
          <button class="action-btn" @click.stop="viewPost(post.id)">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
            {{ post.commentCount || 0 }}
          </button>
          <button class="action-btn" @click.stop="goToGroupChat(post.channelId)" title="频道群聊">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/><line x1="8" y1="9" x2="16" y2="9"/><line x1="8" y1="13" x2="13" y2="13"/></svg>
          </button>
          <button class="action-btn" @click.stop="sharePost(post)">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><line x1="8.59" y1="13.51" x2="15.42" y2="17.49"/><line x1="15.41" y1="6.51" x2="8.59" y2="10.49"/></svg>
          </button>
        </div>
      </div>
      </ShaderPostCard>
    </div>

    <div v-if="loading" class="loading-spinner">加载中...</div>
    <div v-if="!loading && posts.length === 0" class="empty-state">暂无帖子</div>

    <!-- FAB 菜单 -->
    <div class="fab-container" @mouseenter="fabOpen = true" @mouseleave="delayedClose">
      <div class="fab-menu" :class="{ open: fabOpen }">
        <button class="fab-item post" @click="$router.push('/post/create')" title="发布帖子">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
          <span>发帖</span>
        </button>
        <button class="fab-item gallery" @click="showAddGallery = true" title="添加画作">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><path d="M21 15l-5-5L5 21"/></svg>
          <span>画作</span>
        </button>
        <button class="fab-item refresh" :class="{ spinning: refreshing }" @click="refreshPosts" title="刷新">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="23 4 23 10 17 10"/><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/></svg>
          <span>刷新</span>
        </button>
      </div>
      <button class="fab-main">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
      </button>
    </div>

    <UserCard :visible="showCard" :user-id="cardUserId" @close="showCard = false" />
    <AddGalleryDialog :visible="showAddGallery" @close="showAddGallery = false" @added="onGalleryAdded" />
    <GalleryPreview :visible="showPreview" :item="previewItem" @close="showPreview = false" @deleted="onGalleryDeleted" />

    <!-- 悬浮功能页面 -->
    <div v-if="showFloatingPage" class="floating-page-overlay" @click.self="showFloatingPage = false">
      <div class="floating-page-card">
        <component :is="floatingComponent" v-bind="floatingProps" @close="showFloatingPage = false" />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, inject } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '../api/client'
import UserCard from '../components/UserCard.vue'
import Post3DViewer from '../components/Post3DViewer.vue'
import ShaderPostCard from '../components/ShaderPostCard.vue'
import AddGalleryDialog from '../components/AddGalleryDialog.vue'
import GalleryPreview from '../components/GalleryPreview.vue'

const router = useRouter()
const posts = ref<any[]>([])
const cardUserId = ref(0)
const showCard = ref(false)
const showGallery = ref(true)
const showAddGallery = ref(false)
const refreshing = ref(false)
const fabOpen = ref(false)
let fabTimer: any = null

function delayedClose() {
  fabTimer = setTimeout(() => { fabOpen.value = false }, 500)
}

const showFloatingPage = ref(false)
const floatingComponent = ref<any>(null)
const floatingProps = ref<any>({})

function openFloating(comp: any, props?: any) {
  fabOpen.value = false
  showFloatingPage.value = true
  floatingComponent.value = comp
  floatingProps.value = props || {}
}

const previewItem = ref<any>({})
const showPreview = ref(false)

// Reference to Post3DViewer component for manual refresh
const post3dViewerRef = ref<any>(null)

function onGalleryAdded() { 
  showPreview.value = false
  // Trigger gallery reload by changing channelId temporarily
  const currentId = currentChannelId.value
  // Force reload by toggling the autoLoad prop
  setTimeout(() => {
    // The watcher on channelId will trigger reload
    window.dispatchEvent(new CustomEvent('gallery-refresh'))
  }, 500)
}
function onGalleryDeleted() { 
  showPreview.value = false
  // Also refresh gallery after deletion
  setTimeout(() => {
    window.dispatchEvent(new CustomEvent('gallery-refresh'))
  }, 500)
}

function onGalleryItemClick(item: any) {
  previewItem.value = item
  showPreview.value = true
}

function showUserCard(userId: number) {
  cardUserId.value = userId
  showCard.value = true
}
const loading = ref(false)
const triggerBurst = inject<(x: number, y: number, color?: string) => void>('particleBurst', () => {})
const currentTab = ref('all')
const currentChannelId = computed(() => Number(currentTab.value) || 0)

interface ChannelTab { id: string; name: string; unread: number }
const channelTabs = ref<ChannelTab[]>([])

const pendingAppCount = ref(0)

let stompClient: any = null

async function fetchChannels() {
  try {
    const res = await api.get('/channels/my')
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      const sorted = [...res.data.data].sort((a: any, b: any) => {
        if (a.channelCode === 'CH-PUBLIC-001') return -1
        if (b.channelCode === 'CH-PUBLIC-001') return 1
        return (a.id || 0) - (b.id || 0)
      })
      const tabs: ChannelTab[] = []
      sorted.forEach((ch: any) => {
        const label = ch.channelCode === 'CH-PUBLIC-001' ? '\u{1F3AF} \u516C\u5171' : ch.name
        tabs.push({ id: String(ch.id), name: label, unread: 0 })
      })
      channelTabs.value = tabs
    }
  } catch (e) {}
}

async function fetchPosts(channelId?: number) {
  loading.value = true
  try {
    const url = channelId ? `/posts/channel/${channelId}` : '/posts/channel/1'
    console.log('[HomePage] 请求帖子列表:', url)
    const res = await api.get(url, { params: { page: 1, size: 20 } })
    console.log('[HomePage] API响应:', res.data)
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      console.log('[HomePage] 获取到帖子数量:', res.data.data.length)
      posts.value = res.data.data.map((p: any) => ({
        ...p,
        id: p.id,
        title: p.topic || '帖子',
        content: p.content || '',
        author: p.username || '用户',
        userId: p.userId || 0,
        avatar: p.avatar || '',
        time: p.createTime || '',
        channelName: p.channelName || '',
        channelId: p.channelId || 0,
        isLiked: p.isLiked || false,
        likeCount: p.likeCount || 0,
        commentCount: p.commentCount || 0,
        images: p.images ? (typeof p.images === 'string' ? JSON.parse(p.images) : p.images).map((url: string) => 
          url.startsWith('http') || url.startsWith('/') ? url : '/uploads/images/' + url
        ) : [],
        videoUrls: p.videoUrls ? (typeof p.videoUrls === 'string' ? JSON.parse(p.videoUrls) : p.videoUrls).map((url: string) => 
          url.startsWith('http') || url.startsWith('/') ? url : '/uploads/videos/' + url
        ) : [],
      }))
      console.log('[HomePage] 帖子数据已更新:', posts.value.length)
    } else {
      console.warn('[HomePage] API响应异常:', res.data)
      posts.value = []
    }
  } catch (e: any) {
    console.error('[HomePage] 获取帖子失败:', e)
    posts.value = []
  } finally {
    loading.value = false
  }
}

async function toggleLike(post: any, event?: MouseEvent) {
  try {
    const res = await api.post(`/posts/${post.id}/like`)
    if (res.data.code === 200 && res.data.data) {
      const wasLiked = post.isLiked
      post.isLiked = res.data.data.liked
      post.likeCount = res.data.data.likeCount
      if (res.data.data.liked && !wasLiked && event) {
        const style = getComputedStyle(document.documentElement)
        const color = style.getPropertyValue('--primary').trim() || '#7C9FCB'
        triggerBurst(event.clientX, event.clientY, color)
      }
    }
  } catch (e) {}
}

function sharePost(post: any) {
  if (navigator.share) {
    navigator.share({
      title: post.title || 'Camp Channel 帖子',
      text: post.content || '',
      url: window.location.origin + '/#/post/' + post.id,
    }).catch(() => {})
  } else {
    navigator.clipboard.writeText(window.location.origin + '/#/post/' + post.id).then(() => {
      alert('链接已复制到剪贴板')
    }).catch(() => {})
  }
}

async function fetchFollowingFeed() {
  loading.value = true
  try {
    const res = await api.get('/follow/feed', { params: { page: 1, size: 20 } })
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      posts.value = res.data.data.map((p: any) => ({
        ...p,
        id: p.id,
        title: p.topic || '帖子',
        content: p.content || '',
        author: p.username || '用户',
        userId: p.userId || 0,
        avatar: p.avatar || '',
        time: p.createTime || '',
        channelName: '',
        channelId: p.channelId || 0,
        isLiked: p.isLiked || false,
        likeCount: p.likeCount || 0,
        commentCount: p.commentCount || 0,
        images: p.images ? (typeof p.images === 'string' ? JSON.parse(p.images) : p.images).map((url: string) => 
          url.startsWith('http') || url.startsWith('/') ? url : '/uploads/images/' + url
        ) : [],
      }))
    }
  } catch (e) {
    posts.value = []
  } finally {
    loading.value = false
  }
}

function switchChannel(channelId: string) {
  if (channelId === 'following') {
    currentTab.value = 'following'
    fetchFollowingFeed()
  } else {
    router.push(`/channel/${channelId}`)
  }
}

function viewPost(postId: number) {
  router.push(`/post/${postId}`)
}

function goToGroupChat(channelId: number) {
  if (!channelId) return
  const tab = channelTabs.value.find(t => t.id === String(channelId))
  const name = tab?.name || '群聊'
  router.push({ name: 'GroupChat', params: { id: channelId }, query: { name } })
}

function refreshPosts() {
  refreshing.value = true
  const id = currentTab.value === 'all' ? 1 : Number(currentTab.value)
  fetchPosts(id || 1).finally(() => {
    setTimeout(() => { refreshing.value = false }, 600)
  })
}

function roleLabel(role: string) {
  const labels: Record<string, string> = { owner: '频道主', admin: '管理员', member: '成员' }
  return labels[role] || '成员'
}

async function fetchPendingAppCount() {
  try {
    const res = await api.get('/channels/applications/pending/count')
    if (res.data.code === 200) pendingAppCount.value = res.data.data || 0
  } catch {}
}

async function connectWebSocket() {
  try {
    const token = localStorage.getItem('token')
    const SockJS = (await import('sockjs-client')).default
    const { Client } = await import('@stomp/stompjs')
    const client = new Client({
      webSocketFactory: () => new SockJS('/api/ws/chat'),
      connectHeaders: token ? { Authorization: token } : {},
      onConnect: () => {
        client.subscribe('/topic/new-post', (msg: any) => {
          try {
            const data = JSON.parse(msg.body)
            const tab = channelTabs.value.find(t => t.id === String(data.channelId))
            if (tab) tab.unread = (tab.unread || 0) + 1
          } catch {}
        })
      },
    })
    client.activate()
    stompClient = client
  } catch (e) {}
}

onMounted(async () => {
  await fetchChannels()
  if (channelTabs.value.length > 0) {
    currentTab.value = channelTabs.value[0].id
    fetchPosts(Number(channelTabs.value[0].id))
  } else {
    fetchPosts()
  }
  connectWebSocket()
  fetchPendingAppCount()
})

onUnmounted(() => {
  if (stompClient) stompClient.deactivate()
})
</script>

<style scoped>
.home-page { max-width: 800px; margin: 0 auto; }
.home-header { margin-bottom: 24px; }
.header-row { display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px; }
.page-title { font-size: 28px; font-weight: 700; margin: 0; }
.header-actions { display: flex; gap: 8px; }
.search-btn, .hot-btn { width: 40px; height: 40px; border-radius: 12px; background: var(--surface); border: 1px solid var(--outline-variant); color: var(--on-surface-variant); cursor: pointer; display: flex; align-items: center; justify-content: center; transition: all 0.2s; }
.search-btn:hover { border-color: var(--primary); color: var(--primary); background: rgba(124,159,203,0.1); }
.hot-btn:hover { border-color: #ff6b35; color: #ff6b35; background: rgba(255,107,53,0.1); }
.channel-tabs { display: flex; gap: 8px; overflow-x: auto; padding-bottom: 4px; }
.channel-tab {
  flex-shrink: 0;
  padding: 8px 16px;
  border-radius: var(--card-radius);
  background: var(--surface);
  border: 1px solid var(--outline-variant);
  color: var(--on-surface-variant);
  font-size: 13px;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  gap: 6px;
}
.channel-tab:hover { border-color: var(--primary); color: var(--on-surface); }
.channel-tab.active { background: rgba(124,159,203,0.15); border-color: var(--primary); color: var(--primary); font-weight: 600; }
.tab-badge { background: var(--primary); color: #fff; font-size: 10px; padding: 1px 6px; border-radius: 10px; }

.gallery-section { margin-bottom: 24px; }
.posts-grid { display: flex; flex-direction: column; gap: 12px; }
.post-card {
  padding: 20px;
  background: var(--surface);
  backdrop-filter: blur(16px);
  border: 1px solid var(--outline-variant);
  border-radius: 16px;
  cursor: pointer;
  transition: all 0.2s;
  position: relative;
}
.post-card.pinned {
  border-color: #f0ad4e;
  background: linear-gradient(135deg, rgba(240, 173, 78, 0.08), rgba(240, 173, 78, 0.02));
}
.pin-badge {
  position: absolute;
  top: -8px;
  right: 12px;
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 2px 10px;
  background: linear-gradient(135deg, #f0ad4e, #f7c948);
  color: #fff;
  font-size: 11px;
  font-weight: 600;
  border-radius: 10px;
  box-shadow: 0 2px 8px rgba(240, 173, 78, 0.4);
}
.post-card:hover { transform: translateY(-2px); border-color: var(--primary); }
.post-header { display: flex; align-items: center; gap: 12px; margin-bottom: 12px; }
.post-avatar {
  width: 36px; height: 36px; border-radius: 10px;
  background: linear-gradient(135deg, var(--primary), var(--secondary));
  display: flex; align-items: center; justify-content: center;
  font-size: 14px; font-weight: 700; color: #fff;
  overflow: hidden;
}
.post-avatar-img { width: 100%; height: 100%; border-radius: 10px; object-fit: cover; }
.post-meta { flex: 1; display: flex; flex-direction: column; }
.post-author { font-size: 14px; font-weight: 600; }
.post-time { font-size: 11px; color: var(--on-surface-variant); }
.post-channel { font-size: 11px; padding: 4px 10px; border-radius: 10px; background: var(--surface); color: var(--primary); }
.role-badge { font-size: 10px; padding: 1px 6px; border-radius: 4px; margin-left: 6px; font-weight: 500; }
.role-badge.role-owner { background: rgba(240, 173, 78, 0.2); color: #f0ad4e; }
.role-badge.role-admin { background: rgba(74, 222, 128, 0.2); color: #4ade80; }
.role-badge.role-member { background: rgba(255, 255, 255, 0.08); color: rgba(255, 255, 255, 0.5); }
.post-title { font-size: 16px; font-weight: 600; margin-bottom: 8px; }
.post-content { font-size: 14px; color: var(--on-surface-variant); line-height: 1.6; margin-bottom: 12px; }
.post-images { display: flex; gap: 8px; margin-bottom: 12px; }
.post-images img { width: 120px; height: 80px; border-radius: 8px; object-fit: cover; }
.post-videos { display: flex; gap: 8px; margin-bottom: 12px; }
.post-video { width: 100%; max-width: 400px; height: 225px; border-radius: 8px; object-fit: cover; background: #000; }
.post-actions { display: flex; gap: 16px; }
.action-btn { display: flex; align-items: center; gap: 6px; background: none; border: none; color: var(--on-surface-variant); font-size: 13px; cursor: pointer; padding: 6px 12px; border-radius: 8px; transition: all 0.2s; }
.action-btn:hover { background: var(--surface); color: var(--on-surface); }
.action-btn.liked { color: var(--secondary); }
.loading-spinner { text-align: center; padding: 40px; color: var(--on-surface-variant); }
.empty-state { text-align: center; padding: 60px 20px; color: var(--on-surface-variant); font-size: 15px; }
.fab-container { position: fixed; bottom: 24px; right: 24px; z-index: 100; display: flex; flex-direction: column; align-items: center; }
.fab-menu { display: flex; flex-direction: column-reverse; align-items: center; gap: 8px; margin-bottom: 8px; opacity: 0; transform: translateY(20px); pointer-events: none; transition: all 0.3s cubic-bezier(0.34,1.56,0.64,1); }
.fab-menu.open { opacity: 1; transform: translateY(0); pointer-events: auto; }
.fab-item { display: flex; align-items: center; gap: 8px; padding: 10px 18px; border-radius: 14px; border: 1px solid var(--outline-variant); background: var(--surface); backdrop-filter: blur(12px); color: var(--on-surface); cursor: pointer; font-size: 13px; white-space: nowrap; transition: all 0.2s; box-shadow: 0 4px 16px rgba(0,0,0,0.15); }
.fab-item:hover { border-color: var(--primary); transform: translateX(-4px); }
.fab-item span { font-weight: 500; }
.fab-item.refresh.spinning svg { animation: spin 0.6s ease-in-out; }
@keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
.fab-main { width: 56px; height: 56px; border-radius: 50%; background: linear-gradient(135deg, var(--primary), var(--secondary)); border: none; color: #fff; cursor: pointer; display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 20px rgba(0,0,0,0.3); transition: all 0.3s; }
.fab-main:hover { transform: scale(1.1); box-shadow: 0 6px 28px rgba(0,0,0,0.4); }
.floating-page-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; z-index: 2000; animation: fadeIn 0.2s; }
.floating-page-card { background: rgba(15,18,25,0.8); backdrop-filter: blur(20px); border: 1px solid var(--outline-variant); border-radius: var(--card-radius); box-shadow: var(--card-shadow); padding: 24px; max-width: 500px; width: 90%; max-height: 80vh; overflow-y: auto; animation: scaleIn 0.25s cubic-bezier(0.34,1.56,0.64,1); }

@media (max-width: 768px) {
.home-page { max-width: 100%; }
.page-title { font-size: 22px; margin-bottom: 16px; }
.channel-tabs { gap: 6px; }
.channel-tab { padding: 6px 12px; font-size: 12px; }
.post-card { padding: 14px; }
.post-title { font-size: 15px; }
.post-content { font-size: 13px; }
.post-images img { width: 90px; height: 60px; }
.post-actions { gap: 8px; }
.action-btn { padding: 4px 10px; font-size: 12px; }
.fab-container { bottom: 80px; right: 12px; }
.fab-main { width: 48px; height: 48px; }
}
</style>
