<template>
  <div class="group-chat-page">
    <div class="chat-header">
      <h2>{{ channelName }}</h2>
      <div class="header-actions">
        <span class="member-count">{{ memberCount }} 位成员</span>
        <button v-if="isAdmin" class="action-btn secondary" @click="showMembers = !showMembers">
          {{ showMembers ? '关闭' : '成员管理' }}
        </button>
      </div>
    </div>

    <div v-if="showMembers && isAdmin" class="members-panel">
      <div v-for="m in members" :key="m.userId" class="member-item">
        <span class="member-avatar">{{ (m.username || '?').charAt(0) }}</span>
        <span class="member-name">{{ m.username || '用户' }}</span>
        <span class="member-role" :data-role="m.role">{{ m.role === 'owner' ? '频道主' : m.role === 'admin' ? '管理员' : '成员' }}</span>
        <span v-if="m.isMuted" class="member-muted">已禁言</span>
        <button
          v-if="m.userId !== authStore.user?.id && m.role !== 'owner'"
          class="mute-btn"
          :class="{ muted: m.isMuted }"
          @click="toggleMute(m)"
        >
          {{ m.isMuted ? '取消禁言' : '禁言' }}
        </button>
      </div>
    </div>

    <div class="chat-messages" ref="messagesRef">
      <div v-for="msg in messages" :key="msg.id" class="message-item" :class="{ self: msg.isSelf }" @contextmenu.prevent="showContextMenu($event, msg)">
        <div class="message-avatar">
          <img v-if="msg.avatar" :src="msg.avatar" />
          <span v-else>{{ (msg.username || '?').charAt(0) }}</span>
        </div>
        <div class="message-content">
          <div class="message-author" v-if="!msg.isSelf">{{ msg.username }}</div>
          <div v-if="msg.status === 2" class="message-recalled">
            {{ msg.isSelf ? '你撤回了一条消息' : `${msg.username} 撤回了一条消息` }}
          </div>
          <div v-else>
            <div class="message-bubble">{{ msg.content }}</div>
            <div class="message-meta">
              <span v-if="msg.isSelf" class="message-status">
                <span v-if="msg.status === 5 || msg.status === 2" class="status-recalled">已撤回</span>
                <template v-else>
                  <span v-if="msg.isRead" class="status-read" title="已读">&#10003;&#10003;</span>
                  <span v-else class="status-sent" title="已发送">&#10003;</span>
                </template>
              </span>
              <span class="message-time">{{ msg.createTime }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div v-if="contextMenu.visible" class="context-menu" :style="{ top: contextMenu.y + 'px', left: contextMenu.x + 'px' }">
      <div class="context-menu-item" @click="recallMessage">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="1 4 1 10 7 10"></polyline>
          <path d="M3.51 15a9 9 0 1 0 2.13-9.36L1 10"></path>
        </svg>
        撤回消息
      </div>
    </div>

    <div class="chat-input-bar">
      <input v-model="chatInput" placeholder="输入消息..." @keyup.enter="sendMessage" />
      <button @click="sendMessage">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <line x1="22" y1="2" x2="11" y2="13"></line>
          <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
        </svg>
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import { useRoute } from 'vue-router'
import { Client } from '@stomp/stompjs'
import SockJS from 'sockjs-client/dist/sockjs'
import { api } from '../api/client'
import { useAuthStore } from '../stores/auth'

const route = useRoute()
const authStore = useAuthStore()

const channelName = ref('群聊')
const memberCount = ref(0)
const messages = ref<any[]>([])
const chatInput = ref('')
const messagesRef = ref<HTMLElement>()
const members = ref<any[]>([])
const isAdmin = ref(false)
const showMembers = ref(false)

let stompClient: Client | null = null
let contextMenuTarget: any = null

const contextMenu = ref({
  visible: false,
  x: 0,
  y: 0,
})

function showContextMenu(event: MouseEvent, msg: any) {
  if (msg.status === 2) return
  contextMenuTarget = msg
  contextMenu.value = {
    visible: true,
    x: event.clientX,
    y: event.clientY,
  }
}

function hideContextMenu() {
  contextMenu.value.visible = false
  contextMenuTarget = null
}

async function recallMessage() {
  if (!contextMenuTarget) return
  try {
    await api.delete(`/group-messages/${contextMenuTarget.id}`)
    hideContextMenu()
  } catch (e: any) {
    const errorMsg = e.response?.data?.message || '撤回失败'
    alert(errorMsg)
    hideContextMenu()
  }
}

async function fetchMembers() {
  try {
    const channelId = route.params.id
    const res = await api.get(`/channels/${channelId}/members`)
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      members.value = res.data.data.map((m: any) => ({
        ...m,
        isMuted: m.isMuted === 1 || m.isMuted === true,
      }))
      memberCount.value = members.value.length
      const currentUser = authStore.user
      if (currentUser) {
        const me = members.value.find((m: any) => m.userId === currentUser.id)
        isAdmin.value = me && (me.role === 'owner' || me.role === 'admin')
      }
    }
  } catch (e) {
    console.error('Failed to fetch members:', e)
  }
}

async function toggleMute(member: any) {
  try {
    const channelId = route.params.id
    await api.post(`/channels/${channelId}/members/${member.userId}/mute`, {
      muted: !member.isMuted,
    })
    fetchMembers()
  } catch (e: any) {
    alert(e.response?.data?.message || '操作失败')
  }
}

async function fetchMessages() {
  try {
    const channelId = route.params.id
    const res = await api.get(`/group-messages/${channelId}`, {
      params: { page: 1, size: 50 }
    })
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      const myId = authStore.user?.id
      messages.value = res.data.data.map((msg: any) => ({
        ...msg,
        isSelf: msg.senderId === myId,
        createTime: formatTime(msg.createTime)
      })).reverse()
      await nextTick()
      scrollToBottom()
    }
  } catch (e) {
    console.error('Failed to fetch messages:', e)
  }
}

function connectWebSocket() {
  const channelId = route.params.id
  const token = localStorage.getItem('token')
  
  stompClient = new Client({
    webSocketFactory: () => new SockJS('/ws/chat'),
    connectHeaders: {
      Authorization: `Bearer ${token}`
    },
    onConnect: () => {
      stompClient?.subscribe(`/topic/channel/${channelId}/messages`, (msg: any) => {
        const data = JSON.parse(msg.body)
        const myId = authStore.user?.id
        messages.value.push({
          ...data,
          isSelf: data.senderId === myId,
          createTime: formatTime(data.createTime)
        })
        nextTick(() => scrollToBottom())
      })

      stompClient?.subscribe(`/topic/channel/${channelId}/recall`, (msg: any) => {
        const messageId = JSON.parse(msg.body)
        const target = messages.value.find(m => m.id === messageId)
        if (target) {
          target.status = 2
        }
      })
    },
  })

  stompClient.activate()
}

function formatTime(timeStr: string): string {
  if (!timeStr) return ''
  try {
    const date = new Date(timeStr)
    return `${date.getMonth() + 1}月${date.getDate()}日 ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`
  } catch {
    return timeStr
  }
}

function scrollToBottom() {
  if (messagesRef.value) {
    messagesRef.value.scrollTop = messagesRef.value.scrollHeight
  }
}

async function sendMessage() {
  if (!chatInput.value.trim()) return
  
  try {
    const channelId = route.params.id
    await api.post('/group-messages', {
      channelId: Number(channelId),
      content: chatInput.value,
      msgType: 1
    })
    chatInput.value = ''
  } catch (e: any) {
    const errorMsg = e.response?.data?.message || '发送失败'
    if (errorMsg.includes('禁言')) {
      alert('你已被禁言，无法发送消息')
    } else {
      alert(errorMsg)
    }
  }
}

onMounted(() => {
  channelName.value = (route.query.name as string) || '群聊'
  fetchMessages()
  connectWebSocket()
  fetchMembers()
  document.addEventListener('click', hideContextMenu)
})

onUnmounted(() => {
  stompClient?.deactivate()
  document.removeEventListener('click', hideContextMenu)
})
</script>

<style scoped>
.group-chat-page {
  max-width: 800px;
  margin: 0 auto;
  height: calc(100vh - 140px);
  display: flex;
  flex-direction: column;
  background: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: 20px;
  overflow: hidden;
}

.chat-header {
  padding: 20px;
  border-bottom: 1px solid var(--outline-variant);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

.chat-header h2 {
  font-size: 20px;
  font-weight: 700;
  margin: 0;
}

.member-count {
  font-size: 13px;
  color: var(--on-surface-variant);
}

.chat-messages {
  flex: 1;
  overflow-y: auto;
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.message-item {
  display: flex;
  gap: 12px;
  align-items: flex-start;
}

.message-item.self {
  flex-direction: row-reverse;
  align-items: flex-end;
}

.message-avatar {
  width: 36px;
  height: 36px;
  border-radius: 10px;
  background: linear-gradient(135deg, var(--primary), var(--secondary));
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  font-weight: 700;
  color: #fff;
  overflow: hidden;
  flex-shrink: 0;
}

.message-avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.message-content {
  max-width: 60%;
}

.message-author {
  font-size: 12px;
  font-weight: 600;
  color: var(--primary);
  margin-bottom: 4px;
}

.message-bubble {
  padding: 10px 16px;
  border-radius: 14px;
  font-size: 14px;
  line-height: 1.5;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid var(--outline-variant);
}

.message-item.self .message-bubble {
  background: rgba(124, 159, 203, 0.15);
  border-color: var(--primary);
}

.message-recalled {
  padding: 8px 16px;
  font-size: 13px;
  color: var(--on-surface-variant);
  font-style: italic;
}

.message-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 4px;
}

.message-item.self .message-meta {
  justify-content: flex-end;
}

.message-status {
  font-size: 11px;
  color: var(--on-surface-variant);
}

.status-read {
  color: var(--primary);
  font-weight: 600;
}

.status-sent {
  color: var(--on-surface-variant);
  opacity: 0.5;
}

.status-recalled {
  color: var(--on-surface-variant);
  font-style: italic;
}

.message-time {
  font-size: 11px;
  color: var(--on-surface-variant);
}

.chat-input-bar {
  display: flex;
  gap: 8px;
  padding: 16px;
  border-top: 1px solid var(--outline-variant);
}

.chat-input-bar input {
  flex: 1;
  padding: 12px 16px;
  border: 1px solid var(--outline-variant);
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.03);
  color: var(--on-surface);
  font-size: 14px;
  outline: none;
}

.chat-input-bar input:focus {
  border-color: var(--primary);
}

.chat-input-bar button {
  padding: 12px 20px;
  background: var(--primary);
  color: #fff;
  border: none;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s;
}

.chat-input-bar button:hover {
  opacity: 0.9;
}

.context-menu {
  position: fixed;
  z-index: 1000;
  background: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: 10px;
  padding: 4px;
  min-width: 140px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
}

.context-menu-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  border-radius: 8px;
  font-size: 13px;
  cursor: pointer;
  color: var(--on-surface);
  transition: background 0.15s;
}

.context-menu-item:hover {
  background: rgba(124, 159, 203, 0.15);
}

.members-panel {
  padding: 12px 16px;
  border-bottom: 1px solid var(--outline-variant);
  max-height: 200px;
  overflow-y: auto;
}

.member-muted {
  font-size: 10px;
  padding: 2px 6px;
  border-radius: 4px;
  background: rgba(240, 173, 78, 0.2);
  color: #f0ad4e;
  margin-left: 8px;
}

.mute-btn {
  padding: 4px 12px;
  border: 1px solid var(--outline-variant);
  border-radius: 6px;
  background: transparent;
  color: var(--on-surface);
  font-size: 12px;
  cursor: pointer;
  transition: all 0.2s;
}

.mute-btn:hover {
  border-color: var(--primary);
}

.mute-btn.muted {
  background: rgba(74, 222, 128, 0.15);
  border-color: #4ade80;
  color: #4ade80;
}

.action-btn.secondary {
  padding: 6px 14px;
  border-radius: 8px;
  border: 1px solid var(--outline-variant);
  background: var(--surface);
  color: var(--on-surface);
  font-size: 12px;
  cursor: pointer;
  transition: all 0.2s;
}

.action-btn.secondary:hover {
  border-color: var(--primary);
}
</style>
