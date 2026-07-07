<template>
  <div class="chat-page">
    <div class="chat-sidebar">
      <div class="chat-search">
        <input v-model="searchQuery" placeholder="搜索会话..." />
      </div>
      <div class="conversation-list">
        <div
          v-for="(conv, i) in filteredConversations"
          :key="conv.id"
          class="conversation-item"
          :class="{ active: activeChat === conv.id }"
          @click="selectConversation(conv)"
        >
          <div class="conv-avatar-wrap">
            <img v-if="conv.avatar" :src="conv.avatar" class="conv-avatar-img" />
            <div v-else class="conv-avatar">{{ (conv.name || '?').charAt(0) }}</div>
            <span class="online-dot" :class="{ online: conv.online }"></span>
          </div>
          <div class="conv-info">
            <div class="conv-name">{{ conv.name }}</div>
            <div class="conv-last-msg">{{ conv.lastMsg || '' }}</div>
          </div>
          <div class="conv-right">
            <span class="conv-time">{{ conv.time || '' }}</span>
            <span v-if="conv.unread > 0" class="conv-badge">{{ conv.unread }}</span>
          </div>
        </div>
      </div>
    </div>
    <div class="chat-main">
      <template v-if="selectedConv">
        <div class="chat-header">{{ selectedConv.name }}</div>
        <div class="chat-messages" ref="messagesRef">
          <div v-for="msg in visibleMessages" :key="msg.id" class="message-item" :class="{ self: msg.isSelf }">
            <!-- Image message -->
            <div v-if="msg.type === 2" class="message-media" @click="previewImage(msg.content)">
              <img :src="resolveUrl(msg.content)" class="msg-image" loading="lazy" />
            </div>
            <!-- Video message -->
            <div v-else-if="msg.type === 3" class="message-media video-msg">
              <video :src="resolveUrl(msg.content)" class="msg-video" controls preload="metadata" />
            </div>
            <!-- Text message -->
            <div v-else class="message-bubble">{{ msg.content }}</div>
            <div class="message-meta">
              <span v-if="msg.isSelf" class="message-status">
                <template v-if="msg.status === 3 || msg.isRead">
                  <span class="status-read" title="已读">&#10003;&#10003;</span>
                </template>
                <template v-else-if="msg.status === 2">
                  <span class="status-delivered" title="已送达">&#10003;&#10003;</span>
                </template>
                <template v-else>
                  <span class="status-sent" title="已发送">&#10003;</span>
                </template>
              </span>
              <span class="message-time">{{ msg.createTime || '' }}</span>
            </div>
            <button v-if="msg.isSelf && canRecall(msg)" class="recall-btn" @click="recallMessage(msg.id)">撤回</button>
          </div>
        </div>
        <div class="chat-input-bar">
          <label class="attach-btn" title="发送图片">
            <input type="file" accept="image/*" @change="handleImageUpload" hidden />
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="3" y="3" width="18" height="18" rx="2" ry="2"/>
              <circle cx="8.5" cy="8.5" r="1.5"/>
              <polyline points="21 15 16 10 5 21"/>
            </svg>
          </label>
          <label class="attach-btn" title="发送视频">
            <input type="file" accept="video/*" @change="handleVideoUpload" hidden />
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <polygon points="23 7 16 12 23 17 23 7"/>
              <rect x="1" y="5" width="15" height="14" rx="2" ry="2"/>
            </svg>
          </label>
          <input v-model="chatInput" placeholder="输入消息..." @keyup.enter="sendMessage" :disabled="isUploading" />
          <span v-if="isUploading" class="uploading-indicator">⬆️</span>
          <button @click="sendMessage" :disabled="isUploading">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
          </button>
        </div>
      </template>
      <div v-else class="no-chat">
        <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1" opacity="0.3"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
        <p>选择一个会话开始聊天</p>
      </div>
    </div>
    <!-- Image Preview Overlay -->
    <div v-if="showPreview" class="image-preview-overlay" @click="showPreview = false">
      <button class="preview-close" @click="showPreview = false">&times;</button>
      <img :src="imagePreviewUrl" class="preview-image" @click.stop />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, nextTick, triggerRef } from 'vue'
import { useRoute } from 'vue-router'
import { api } from '../api/client'
import { useAuthStore } from '../stores/auth'

const route = useRoute()
const authStore = useAuthStore()
const myId = computed(() => authStore.user?.id || 0)

const searchQuery = ref('')
const activeChat = ref<number | null>(null)
const chatInput = ref('')
const isUploading = ref(false)
const selectedConv = ref<any>(null)
const conversations = ref<any[]>([])
const messages = ref<any[]>([])
const messagesRef = ref<HTMLDivElement>()
const conversationVersion = ref(0) // Force re-render counter

const filteredConversations = computed(() => {
  // Access version to force re-computation
  conversationVersion.value
  // Return new object references to force Vue to re-render
  return conversations.value.map(c => ({ ...c })).filter(c => (c.name || '').includes(searchQuery.value))
})

// Filter out recalled messages (status 5 = recalled)
const visibleMessages = computed(() =>
  messages.value.filter(m => m.status !== 5)
)

let stompClient: any = null
const wsSubscriptions: any[] = []

async function connectWebSocket() {
  try {
    if ((window as any).__stompClient) {
      stompClient = (window as any).__stompClient
      
      // Unsubscribe any previous subscriptions to avoid duplicate messages and stale closures
      wsSubscriptions.forEach(sub => { try { sub.unsubscribe() } catch(e){} })
      wsSubscriptions.length = 0

      wsSubscriptions.push(stompClient.subscribe('/user/queue/messages', (msg: any) => {
        handleIncomingMessage(JSON.parse(msg.body))
      }))
      // Subscribe to read receipt notifications
      wsSubscriptions.push(stompClient.subscribe('/user/queue/read-receipts', (msg: any) => {
        handleReadReceipt(JSON.parse(msg.body))
      }))
      // Subscribe to online status updates
      wsSubscriptions.push(stompClient.subscribe('/user/queue/online-status', (msg: any) => {
        const data = JSON.parse(msg.body)
        handleOnlineStatus(data.userId, data.online)
      }))
      return
    }
    const token = localStorage.getItem('token')
    const SockJS = (await import('sockjs-client')).default
    const { Client } = await import('@stomp/stompjs')
    stompClient = new Client({
      webSocketFactory: () => new SockJS('/ws/chat'),
      connectHeaders: token ? { Authorization: `Bearer ${token}` } : {},
      onConnect: () => {
        console.log('STOMP connected, subscribing...')
        
        wsSubscriptions.forEach(sub => { try { sub.unsubscribe() } catch(e){} })
        wsSubscriptions.length = 0

        wsSubscriptions.push(stompClient.subscribe('/user/queue/messages', (msg: any) => {
          console.log('Received message:', msg.body)
          handleIncomingMessage(JSON.parse(msg.body))
        }))
        // Subscribe to read receipt notifications
        wsSubscriptions.push(stompClient.subscribe('/user/queue/read-receipts', (msg: any) => {
          console.log('Read receipt:', msg.body)
          handleReadReceipt(JSON.parse(msg.body))
        }))
        // Subscribe to online status updates
        wsSubscriptions.push(stompClient.subscribe('/user/queue/online-status', (msg: any) => {
          const data = JSON.parse(msg.body)
          console.log('Online status update:', data)
          handleOnlineStatus(data.userId, data.online)
        }))
      },
    })
    stompClient.activate()
    ;(window as any).__stompClient = stompClient
  } catch (e) {
    console.warn('WebSocket connection failed', e)
  }
}

function resolveUrl(url: string): string {
  if (!url) return ''
  if (url.startsWith('http://') || url.startsWith('https://')) return url
  return '/api' + url
}

function getMsgPreview(data: any): string {
  if (data.type === 2) return '[图片]'
  if (data.type === 3) return '[视频]'
  return data.content || ''
}

function handleIncomingMessage(data: any) {
  console.log('[handleIncomingMessage] Received:', data)
  const isFromOther = data.senderId !== myId.value
  const convId = isFromOther ? data.senderId : data.receiverId
  const isRecalled = data.status === 5
  console.log('[handleIncomingMessage] convId:', convId, 'isRecalled:', isRecalled)
  const preview = isRecalled ? '对方撤回了一条消息' : getMsgPreview(data)

  // Always update message status if it exists (for recall notifications)
  const existing = messages.value.find(m => m.id === data.id)
  if (existing) {
    existing.status = data.status || existing.status
    existing.isRead = data.isRead !== undefined ? data.isRead : existing.isRead
    console.log('[handleIncomingMessage] Updated existing message status to:', existing.status)
  }

  // If currently chatting with this person, add new messages
  if (activeChat.value === convId) {
    if (!existing && !isRecalled) {
      messages.value.push({
        id: data.id,
        content: data.content,
        type: data.type || 1,
        createTime: formatTime(data.createTime),
        rawTime: data.createTime,
        isSelf: !isFromOther,
        isRead: data.isRead || false,
        status: data.status || 1,
      })
    }
    scrollToBottom()
    // Mark as read
    markAllAsRead(convId)
  }

  // Update conversation list - replace entire array to force Vue reactivity
  const convIdx = conversations.value.findIndex(c => c.id === convId)
  console.log('[handleIncomingMessage] convIdx:', convIdx, 'total convs:', conversations.value.length)
  
  const newConversations = [...conversations.value]
  if (convIdx >= 0) {
    // Update existing conversation
    const conv = { ...newConversations[convIdx] }
    conv.lastMsg = preview
    conv.time = formatTime(data.createTime)
    if (isFromOther && activeChat.value !== convId && !isRecalled) {
      conv.unread = (conv.unread || 0) + 1
    }
    // Remove and add to top
    newConversations.splice(convIdx, 1)
    newConversations.unshift(conv)
  } else {
    // New conversation
    newConversations.unshift({
      id: convId,
      name: data.username || '用户' + convId,
      avatar: data.avatar || '',
      lastMsg: preview,
      time: formatTime(data.createTime),
      unread: isFromOther && activeChat.value !== convId && !isRecalled ? 1 : 0,
      online: false,
      senderId: data.senderId,
    })
    fetchOnlineStatus()
  }
  
  conversations.value = newConversations
  conversationVersion.value++ // Force UI update
  triggerRef(conversations)
  console.log('[handleIncomingMessage] conversations updated, first item lastMsg:', conversations.value[0]?.lastMsg)
}

function handleOnlineStatus(userId: number, online: boolean) {
  const conv = conversations.value.find(c => c.id === userId)
  if (conv) {
    conv.online = online
  }
}

function handleReadReceipt(data: any) {
  // When the other party reads our messages, update isRead on our sent messages
  const friendId = data.friendId
  if (activeChat.value === friendId) {
    // Mark all sent messages as read in the current chat
    for (const msg of messages.value) {
      if (msg.isSelf && !msg.isRead) {
        msg.isRead = true
      }
    }
  }
}

function scrollToBottom() {
  nextTick(() => {
    if (messagesRef.value) {
      messagesRef.value.scrollTop = messagesRef.value.scrollHeight
    }
  })
}

function formatTime(timeStr: string): string {
  if (!timeStr) return ''
  const d = new Date(timeStr)
  const now = new Date()
  const diff = now.getTime() - d.getTime()
  if (diff < 60000) return '刚刚'
  if (diff < 3600000) return Math.floor(diff / 60000) + '分钟前'
  if (diff < 86400000) return Math.floor(diff / 3600000) + '小时前'
  return (d.getMonth() + 1) + '/' + d.getDate()
}

async function fetchConversations() {
  try {
    const res = await api.get('/chat/conversations/with-unread')
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      conversations.value = res.data.data.map((m: any) => ({
        id: m.id,
        name: m.username || '用户' + m.id,
        avatar: m.avatar || '',
        lastMsg: m.lastMsg || '',
        time: formatTime(m.createTime) || '',
        unread: m.unread || 0,
        online: m.online || false,
        senderId: m.senderId,
      }))
    }
  } catch (e) {}
}

async function selectConversation(conv: any) {
  activeChat.value = conv.id
  selectedConv.value = conv
  conv.unread = 0
  messages.value = []
  try {
    const res = await api.get(`/chat/history/${conv.id}`, { params: { page: 1, size: 50 } })
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      messages.value = res.data.data.map((m: any) => ({
        id: m.id,
        content: m.content || '',
        type: m.type || 1,
        createTime: formatTime(m.createTime) || '',
        rawTime: m.createTime,
        isSelf: m.senderId === myId.value,
        isRead: m.isRead === 1,
        status: m.status || 1,
      })).reverse()
    }
    scrollToBottom()
  } catch (e) {}
  // Mark all as read on backend
  await markAllAsRead(conv.id)
}

async function markAllAsRead(friendId: number) {
  try {
    await api.post(`/chat/read-all/${friendId}`)
  } catch {}
}

async function sendMessage() {
  if (!chatInput.value.trim() || !selectedConv.value) return
  const content = chatInput.value
  chatInput.value = ''
  try {
    const res = await api.post('/chat/messages/send', {
      receiverId: selectedConv.value.id,
      content,
      type: 1,
    })
    if (res.data.code === 200 && res.data.data) {
      const msg = res.data.data
      messages.value.push({
        id: msg.id || Date.now(),
        content: msg.content || content,
        type: 1,
        createTime: formatTime(msg.createTime) || '刚刚',
        rawTime: msg.createTime || new Date().toISOString(),
        isSelf: true,
        isRead: false,
        status: msg.status || 1,
      })
      scrollToBottom()
      updateConvPreview(content)
    }
  } catch (e) {}
}

function updateConvPreview(content: string, type: number = 1) {
  if (!selectedConv.value) return
  const preview = type === 2 ? '[图片]' : type === 3 ? '[视频]' : content
  const conv = conversations.value.find(c => c.id === selectedConv.value.id)
  if (conv) {
    conv.lastMsg = preview
    conv.time = '刚刚'
    const idx = conversations.value.indexOf(conv)
    conversations.value.splice(idx, 1)
    conversations.value.unshift(conv)
  }
}

async function handleImageUpload(event: Event) {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  if (!file || !selectedConv.value) return
  input.value = '' // reset for re-upload
  await uploadAndSendMedia(file, '/upload/image', 2)
}

async function handleVideoUpload(event: Event) {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  if (!file || !selectedConv.value) return
  input.value = ''
  await uploadAndSendMedia(file, '/upload/video', 3)
}

async function uploadAndSendMedia(file: File, endpoint: string, type: number) {
  isUploading.value = true
  try {
    const formData = new FormData()
    formData.append('file', file)
    const uploadRes = await api.post(endpoint, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    })
    if (uploadRes.data.code === 200 && uploadRes.data.data?.url) {
      const url = uploadRes.data.data.url
      const sendRes = await api.post('/chat/messages/send', {
        receiverId: selectedConv.value.id,
        content: url,
        type,
      })
      if (sendRes.data.code === 200 && sendRes.data.data) {
        const msg = sendRes.data.data
        messages.value.push({
          id: msg.id || Date.now(),
          content: msg.content || url,
          type,
          createTime: formatTime(msg.createTime) || '刚刚',
          rawTime: msg.createTime || new Date().toISOString(),
          isSelf: true,
          isRead: false,
          status: msg.status || 1,
        })
        scrollToBottom()
        updateConvPreview(url, type)
      }
    }
  } catch (e: any) {
    window.alert(e.response?.data?.message || '上传失败')
  } finally {
    isUploading.value = false
  }
}

let imagePreviewUrl = ref('')
let showPreview = ref(false)

function previewImage(url: string) {
  imagePreviewUrl.value = resolveUrl(url)
  showPreview.value = true
}

function canRecall(msg: any): boolean {
  if (!msg.rawTime) return false
  const msgTime = new Date(msg.rawTime).getTime()
  const now = Date.now()
  return (now - msgTime) <= 2 * 60 * 1000 // 2 minutes
}

async function recallMessage(messageId: number) {
  try {
    await api.post(`/chat/messages/${messageId}/recall`)
    const msg = messages.value.find(m => m.id === messageId)
    if (msg) {
      msg.status = 5
      // Update conversation list to show recall message
      const conv = conversations.value.find(c => c.id === msg.isSelf ? activeChat.value : msg.senderId)
      if (conv) {
        conv.lastMsg = '对方撤回了一条消息'
        conv.time = '刚刚'
        const idx = conversations.value.indexOf(conv)
        conversations.value.splice(idx, 1)
        conversations.value.unshift(conv)
      }
    }
  } catch (e: any) {
    window.alert(e.response?.data?.message || '撤回失败')
  }
}

async function fetchOnlineStatus() {
  if (conversations.value.length === 0) return
  const ids = conversations.value.map(c => c.id).join(',')
  try {
    const res = await api.get('/chat/online/batch', { params: { userIds: ids } })
    if (res.data.code === 200 && res.data.data) {
      for (const conv of conversations.value) {
        if (res.data.data[conv.id] !== undefined) {
          conv.online = res.data.data[conv.id]
        }
      }
    }
  } catch {}
}

let onlineTimer: any = null

function startConversationWith(friendId: number) {
  const existing = conversations.value.find(c => c.id === friendId)
  if (existing) {
    selectConversation(existing)
  } else {
    const conv = { id: friendId, name: '用户', avatar: '', lastMsg: '', time: '', unread: 0, online: false }
    conversations.value.push(conv)
    selectConversation(conv)
    api.get(`/users/${friendId}`).then(res => {
      if (res.data.code === 200) {
        conv.name = res.data.data.username || '用户'
        conv.avatar = res.data.data.avatar || ''
      }
    }).catch(() => {})
  }
}

onMounted(async () => {
  await fetchConversations()
  await connectWebSocket()
  fetchOnlineStatus()
  // Poll online status every 30 seconds
  onlineTimer = setInterval(fetchOnlineStatus, 30000)

  const friendId = Number(route.query.friendId)
  if (friendId) {
    startConversationWith(friendId)
  }
})

onUnmounted(() => {
  if (onlineTimer) clearInterval(onlineTimer)
  wsSubscriptions.forEach(sub => { try { sub.unsubscribe() } catch(e){} })
  wsSubscriptions.length = 0
})
</script>

<style scoped>
.chat-page { display: flex; height: calc(100vh - 64px); gap: 0; max-width: 1100px; margin: 0 auto; }
.chat-sidebar { width: 320px; background: var(--surface); border: 1px solid var(--outline-variant); border-radius: 20px 0 0 20px; display: flex; flex-direction: column; flex-shrink: 0; }
.chat-search { padding: 16px; }
.chat-search input { width: 100%; padding: 10px 14px; border: 1px solid var(--outline-variant); border-radius: 10px; background: rgba(255,255,255,0.03); color: var(--on-surface); font-size: 13px; outline: none; }
.chat-search input:focus { border-color: var(--primary); }
.conversation-list { flex: 1; overflow-y: auto; }
.conversation-item { display: flex; align-items: center; gap: 12px; padding: 12px 16px; cursor: pointer; transition: background 0.2s; }
.conversation-item:hover { background: var(--surface); }
.conversation-item.active { background: rgba(124,159,203,0.08); }
.conv-avatar-wrap { position: relative; width: 40px; height: 40px; flex-shrink: 0; }
.conv-avatar { width: 40px; height: 40px; border-radius: 10px; background: linear-gradient(135deg, var(--primary), var(--secondary)); display: flex; align-items: center; justify-content: center; font-size: 16px; font-weight: 700; color: #fff; }
.conv-avatar-img { width: 40px; height: 40px; border-radius: 10px; object-fit: cover; display: block; }
.online-dot { position: absolute; bottom: 0; right: 0; width: 10px; height: 10px; border-radius: 50%; border: 2px solid var(--surface); background: #888; }
.online-dot.online { background: #4ade80; }
.conv-info { flex: 1; min-width: 0; }
.conv-name { font-size: 14px; font-weight: 600; margin-bottom: 2px; }
.conv-last-msg { font-size: 12px; color: var(--on-surface-variant); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.conv-right { display: flex; flex-direction: column; align-items: flex-end; gap: 4px; }
.conv-time { font-size: 11px; color: var(--on-surface-variant); }
.conv-badge { background: var(--primary); color: #fff; font-size: 10px; padding: 2px 6px; border-radius: 8px; min-width: 18px; text-align: center; }
.chat-main { flex: 1; background: var(--surface); border: 1px solid var(--outline-variant); border-left: none; border-radius: 0 20px 20px 0; display: flex; flex-direction: column; }
.chat-header { padding: 16px 24px; font-size: 15px; font-weight: 600; border-bottom: 1px solid var(--outline-variant); }
.chat-messages { flex: 1; padding: 20px; overflow-y: auto; display: flex; flex-direction: column; gap: 12px; }
.message-item { display: flex; flex-direction: column; max-width: 70%; }
.message-item.self { align-self: flex-end; align-items: flex-end; }
.message-bubble { padding: 10px 16px; border-radius: 14px; font-size: 14px; line-height: 1.5; background: var(--surface); border: 1px solid var(--outline-variant); }
.message-item.self .message-bubble { background: rgba(124,159,203,0.15); border-color: var(--primary); }
.message-meta { display: flex; align-items: center; gap: 4px; margin-top: 2px; }
.message-status { font-size: 11px; margin-right: 4px; }
.status-sent { color: var(--on-surface-variant); }
.status-delivered { color: var(--on-surface-variant); }
.status-read { color: #4a9eff; font-weight: 600; }
.status-recalled { color: #ff6b6b; font-size: 10px; }
.message-time { font-size: 10px; color: var(--on-surface-variant); }
.recall-btn { background: none; border: none; color: #ff6b6b; font-size: 10px; cursor: pointer; margin-top: 2px; padding: 0; align-self: flex-end; }
.message-media { max-width: 220px; cursor: pointer; border-radius: 14px; overflow: hidden; }
.msg-image { width: 100%; max-height: 200px; object-fit: cover; border-radius: 14px; display: block; transition: transform 0.2s; }
.msg-image:hover { transform: scale(1.02); }
.msg-video { width: 100%; max-height: 200px; border-radius: 14px; display: block; }
.message-recalled { padding: 8px 16px; font-size: 13px; color: var(--on-surface-variant); font-style: italic; background: var(--surface); border-radius: 14px; border: 1px solid var(--outline-variant); }
.attach-btn { width: 40px; height: 40px; border-radius: 10px; border: 1px solid var(--outline-variant); background: transparent; cursor: pointer; display: flex; align-items: center; justify-content: center; color: var(--on-surface-variant); transition: all 0.2s; flex-shrink: 0; }
.attach-btn:hover { border-color: var(--primary); color: var(--primary); }
.uploading-indicator { font-size: 16px; animation: pulse 1s infinite; }
@keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.4; } }
.image-preview-overlay { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.85); z-index: 9999; display: flex; align-items: center; justify-content: center; cursor: zoom-out; }
.preview-close { position: absolute; top: 20px; right: 24px; background: none; border: none; color: white; font-size: 36px; cursor: pointer; z-index: 10000; line-height: 1; }
.preview-image { max-width: 90vw; max-height: 90vh; object-fit: contain; border-radius: 8px; cursor: default; }
.chat-input-bar { display: flex; gap: 8px; padding: 16px; border-top: 1px solid var(--outline-variant); }
.chat-input-bar input { flex: 1; padding: 12px 16px; border: 1px solid var(--outline-variant); border-radius: 12px; background: rgba(255,255,255,0.03); color: var(--on-surface); font-size: 14px; outline: none; }
.chat-input-bar input:focus { border-color: var(--primary); }
.chat-input-bar button { width: 44px; height: 44px; border-radius: 12px; border: none; background: linear-gradient(135deg, var(--primary), var(--secondary)); color: #fff; cursor: pointer; display: flex; align-items: center; justify-content: center; }
.no-chat { flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 12px; color: var(--on-surface-variant); }

@media (max-width: 768px) {
.chat-page { flex-direction: column; height: calc(100vh - 68px); max-width: 100%; }
.chat-sidebar { width: 100%; border-radius: 0; max-height: 45vh; display: flex; flex-direction: column; }
.chat-sidebar.selected { display: none; }
.chat-main { border-radius: 0; border-left: 1px solid var(--outline-variant); }
.conversation-list { max-height: none; }
}
</style>
