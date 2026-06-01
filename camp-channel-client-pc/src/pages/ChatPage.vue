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
          <div v-for="msg in messages" :key="msg.id" class="message-item" :class="{ self: msg.isSelf }">
            <div class="message-bubble">{{ msg.content }}</div>
            <div class="message-meta">
              <span v-if="msg.isSelf" class="message-status">
                <span v-if="msg.status === 5 || msg.status === 2" class="status-recalled">已撤回</span>
                <template v-else>
                  <span v-if="msg.status === 3 || msg.isRead" class="status-read" title="已读">&#10003;&#10003;</span>
                  <span v-else-if="msg.status === 2" class="status-delivered" title="已送达">&#10003;&#10003;</span>
                  <span v-else class="status-sent" title="已发送">&#10003;</span>
                </template>
              </span>
              <span class="message-time">{{ msg.createTime || '' }}</span>
            </div>
            <button v-if="msg.isSelf && msg.status !== 2" class="recall-btn" @click="recallMessage(msg.id)">撤回</button>
          </div>
        </div>
        <div class="chat-input-bar">
          <input v-model="chatInput" placeholder="输入消息..." @keyup.enter="sendMessage" />
          <button @click="sendMessage">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
          </button>
        </div>
      </template>
      <div v-else class="no-chat">
        <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1" opacity="0.3"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
        <p>选择一个会话开始聊天</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, nextTick } from 'vue'
import { useRoute } from 'vue-router'
import { api } from '../api/client'
import { useAuthStore } from '../stores/auth'

const route = useRoute()
const authStore = useAuthStore()
const myId = computed(() => authStore.user?.id || 0)

const searchQuery = ref('')
const activeChat = ref<number | null>(null)
const chatInput = ref('')
const selectedConv = ref<any>(null)
const conversations = ref<any[]>([])
const messages = ref<any[]>([])
const messagesRef = ref<HTMLDivElement>()

const filteredConversations = computed(() =>
  conversations.value.filter(c => (c.name || '').includes(searchQuery.value))
)

let stompClient: any = null

async function connectWebSocket() {
  try {
    if ((window as any).__stompClient) {
      stompClient = (window as any).__stompClient
      stompClient.subscribe('/user/queue/messages', (msg: any) => {
        handleIncomingMessage(JSON.parse(msg.body))
      })
      // Subscribe to read receipt notifications
      stompClient.subscribe('/user/queue/read-receipts', (msg: any) => {
        handleReadReceipt(JSON.parse(msg.body))
      })
      // Subscribe to online status updates
      stompClient.subscribe('/user/queue/online-status', (msg: any) => {
        const data = JSON.parse(msg.body)
        handleOnlineStatus(data.userId, data.online)
      })
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
        stompClient.subscribe('/user/queue/messages', (msg: any) => {
          console.log('Received message:', msg.body)
          handleIncomingMessage(JSON.parse(msg.body))
        })
        // Subscribe to read receipt notifications
        stompClient.subscribe('/user/queue/read-receipts', (msg: any) => {
          console.log('Read receipt:', msg.body)
          handleReadReceipt(JSON.parse(msg.body))
        })
        // Subscribe to online status updates
        stompClient.subscribe('/user/queue/online-status', (msg: any) => {
          const data = JSON.parse(msg.body)
          console.log('Online status update:', data)
          handleOnlineStatus(data.userId, data.online)
        })
      },
    })
    stompClient.activate()
  } catch (e) {
    console.warn('WebSocket connection failed', e)
  }
}

function handleIncomingMessage(data: any) {
  const isFromOther = data.senderId !== myId.value
  const convId = isFromOther ? data.senderId : data.receiverId

  // Update or add conversation
  let conv = conversations.value.find(c => c.id === convId)
  if (conv) {
    conv.lastMsg = data.content
    conv.time = formatTime(data.createTime)
    if (isFromOther && activeChat.value !== convId) {
      conv.unread = (conv.unread || 0) + 1
    }
    // Move to top
    const idx = conversations.value.indexOf(conv)
    conversations.value.splice(idx, 1)
    conversations.value.unshift(conv)
  } else {
    // New conversation
    conversations.value.unshift({
      id: convId,
      name: data.username || '用户' + convId,
      avatar: data.avatar || '',
      lastMsg: data.content,
      time: formatTime(data.createTime),
      unread: isFromOther && activeChat.value !== convId ? 1 : 0,
      online: false,
      senderId: data.senderId,
    })
    fetchOnlineStatus()
  }

  // If currently chatting with this person, add message
  if (activeChat.value === convId) {
    messages.value.push({
      id: data.id,
      content: data.content,
      createTime: formatTime(data.createTime),
      isSelf: !isFromOther,
      isRead: data.isRead || false,
      status: data.status || 1,
    })
    scrollToBottom()
    // Mark as read
    markAllAsRead(convId)
  }
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
        createTime: formatTime(m.createTime) || '',
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
        createTime: formatTime(msg.createTime) || '刚刚',
        isSelf: true,
        isRead: false,
        status: msg.status || 1,
      })
      scrollToBottom()
      // Update conversation preview
      const conv = conversations.value.find(c => c.id === selectedConv.value.id)
      if (conv) {
        conv.lastMsg = content
        conv.time = '刚刚'
        // Move to top
        const idx = conversations.value.indexOf(conv)
        conversations.value.splice(idx, 1)
        conversations.value.unshift(conv)
      }
    }
  } catch (e) {}
}

async function recallMessage(messageId: number) {
  try {
    await api.post(`/chat/messages/${messageId}/recall`)
    const msg = messages.value.find(m => m.id === messageId)
    if (msg) msg.status = 2
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
})
</script>

<style scoped>
.chat-page { display: flex; height: calc(100vh - 64px); gap: 0; max-width: 1100px; margin: 0 auto; }
.chat-sidebar { width: 320px; background: var(--card); border: 1px solid var(--border); border-radius: 20px 0 0 20px; display: flex; flex-direction: column; flex-shrink: 0; }
.chat-search { padding: 16px; }
.chat-search input { width: 100%; padding: 10px 14px; border: 1px solid var(--border); border-radius: 10px; background: rgba(255,255,255,0.03); color: var(--text); font-size: 13px; outline: none; }
.chat-search input:focus { border-color: var(--primary); }
.conversation-list { flex: 1; overflow-y: auto; }
.conversation-item { display: flex; align-items: center; gap: 12px; padding: 12px 16px; cursor: pointer; transition: background 0.2s; }
.conversation-item:hover { background: var(--card); }
.conversation-item.active { background: rgba(124,159,203,0.08); }
.conv-avatar-wrap { position: relative; width: 40px; height: 40px; flex-shrink: 0; }
.conv-avatar { width: 40px; height: 40px; border-radius: 10px; background: linear-gradient(135deg, var(--primary), var(--accent)); display: flex; align-items: center; justify-content: center; font-size: 16px; font-weight: 700; color: #fff; }
.conv-avatar-img { width: 40px; height: 40px; border-radius: 10px; object-fit: cover; display: block; }
.online-dot { position: absolute; bottom: 0; right: 0; width: 10px; height: 10px; border-radius: 50%; border: 2px solid var(--card); background: #888; }
.online-dot.online { background: #4ade80; }
.conv-info { flex: 1; min-width: 0; }
.conv-name { font-size: 14px; font-weight: 600; margin-bottom: 2px; }
.conv-last-msg { font-size: 12px; color: var(--text-secondary); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.conv-right { display: flex; flex-direction: column; align-items: flex-end; gap: 4px; }
.conv-time { font-size: 11px; color: var(--text-secondary); }
.conv-badge { background: var(--primary); color: #fff; font-size: 10px; padding: 2px 6px; border-radius: 8px; min-width: 18px; text-align: center; }
.chat-main { flex: 1; background: var(--card); border: 1px solid var(--border); border-left: none; border-radius: 0 20px 20px 0; display: flex; flex-direction: column; }
.chat-header { padding: 16px 24px; font-size: 15px; font-weight: 600; border-bottom: 1px solid var(--border); }
.chat-messages { flex: 1; padding: 20px; overflow-y: auto; display: flex; flex-direction: column; gap: 12px; }
.message-item { display: flex; flex-direction: column; max-width: 70%; }
.message-item.self { align-self: flex-end; align-items: flex-end; }
.message-bubble { padding: 10px 16px; border-radius: 14px; font-size: 14px; line-height: 1.5; background: var(--card); border: 1px solid var(--border); }
.message-item.self .message-bubble { background: rgba(124,159,203,0.15); border-color: var(--primary); }
.message-meta { display: flex; align-items: center; gap: 4px; margin-top: 2px; }
.message-status { font-size: 11px; margin-right: 4px; }
.status-sent { color: var(--text-secondary); }
.status-delivered { color: var(--text-secondary); }
.status-read { color: #4a9eff; font-weight: 600; }
.status-recalled { color: #ff6b6b; font-size: 10px; }
.message-time { font-size: 10px; color: var(--text-secondary); }
.recall-btn { background: none; border: none; color: #ff6b6b; font-size: 10px; cursor: pointer; margin-top: 2px; padding: 0; align-self: flex-end; }
.chat-input-bar { display: flex; gap: 8px; padding: 16px; border-top: 1px solid var(--border); }
.chat-input-bar input { flex: 1; padding: 12px 16px; border: 1px solid var(--border); border-radius: 12px; background: rgba(255,255,255,0.03); color: var(--text); font-size: 14px; outline: none; }
.chat-input-bar input:focus { border-color: var(--primary); }
.chat-input-bar button { width: 44px; height: 44px; border-radius: 12px; border: none; background: linear-gradient(135deg, var(--primary), var(--accent)); color: #fff; cursor: pointer; display: flex; align-items: center; justify-content: center; }
.no-chat { flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 12px; color: var(--text-secondary); }

@media (max-width: 768px) {
.chat-page { flex-direction: column; height: calc(100vh - 68px); max-width: 100%; }
.chat-sidebar { width: 100%; border-radius: 0; max-height: 45vh; display: flex; flex-direction: column; }
.chat-sidebar.selected { display: none; }
.chat-main { border-radius: 0; border-left: 1px solid var(--border); }
.conversation-list { max-height: none; }
}
</style>
