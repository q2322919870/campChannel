<template>
  <view class="chat-detail-container">
    <scroll-view scroll-y class="messages-list" :scroll-top="scrollTop" :scroll-into-view="scrollIntoView">
      <view
        v-for="(msg, idx) in messages"
        :key="msg.id || idx"
        :id="'msg-' + (msg.id || idx)"
        class="message-item"
        :class="{ 'message-self': msg.isSelf }"
      >
        <!-- Other's message: avatar left, body right -->
        <template v-if="!msg.isSelf">
          <view class="msg-avatar-wrapper">
            <image v-if="contactAvatar" :src="contactAvatar" mode="aspectFill" class="msg-avatar-img" />
            <view v-else class="msg-avatar" :style="{ background: contactColor }">
              <text>{{ contactName?.charAt(0) || '?' }}</text>
            </view>
          </view>
          <view class="msg-body">
            <view class="msg-bubble" :class="{ 'msg-bubble-media': msg.type === 2 || msg.type === 3 }" @longpress="canRecall(msg) && recallMessage(msg)">
              <template v-if="msg.status === 'RECALLED'">
                <text class="msg-text msg-recalled">已撤回一条消息</text>
              </template>
              <template v-else-if="msg.type === 2">
                <image :src="msg.content" mode="widthFix" class="msg-image" @tap="previewImage(msg.content)" />
              </template>
              <template v-else-if="msg.type === 3">
                <video :src="msg.content" class="msg-video" controls :show-center-play-btn="true" :show-play-btn="true" :enable-progress-gesture="false" object-fit="cover" poster="" />
              </template>
              <template v-else>
                <text class="msg-text">{{ msg.content }}</text>
              </template>
            </view>
            <view class="msg-meta">
              <text class="msg-time">{{ msg.createdAt }}</text>
            </view>
          </view>
        </template>
        <!-- Self message: body left, avatar right -->
        <template v-else>
          <view class="msg-body">
            <view class="msg-bubble bubble-self" :class="{ 'msg-bubble-media': msg.type === 2 || msg.type === 3 }" @longpress="canRecall(msg) && recallMessage(msg)">
              <template v-if="msg.status === 'RECALLED'">
                <text class="msg-text msg-recalled">已撤回一条消息</text>
              </template>
              <template v-else-if="msg.type === 2">
                <image :src="msg.content" mode="widthFix" class="msg-image" @tap="previewImage(msg.content)" />
              </template>
              <template v-else-if="msg.type === 3">
                <video :src="msg.content" class="msg-video" controls :show-center-play-btn="true" :show-play-btn="true" :enable-progress-gesture="false" object-fit="cover" poster="" />
              </template>
              <template v-else>
                <text class="msg-text">{{ msg.content }}</text>
              </template>
            </view>
            <view class="msg-meta">
              <text class="msg-time">{{ msg.createdAt }}</text>
              <text v-if="msg.status === 'SENDING'" class="msg-sending">发送中...</text>
              <text v-if="msg.status === 'FAILED'" class="msg-failed">发送失败</text>
              <text v-if="msg.status === 'SENT'" class="msg-read">✓</text>
              <text v-if="msg.status === 'READ'" class="msg-read">✓✓</text>
            </view>
          </view>
          <view class="msg-avatar-wrapper">
            <image v-if="myAvatar" :src="myAvatar" mode="aspectFill" class="msg-avatar-img" />
            <view v-else class="msg-avatar self-avatar-bg">
              <text>{{ myName?.charAt(0) || '?' }}</text>
            </view>
          </view>
        </template>
      </view>
    </scroll-view>

    <view class="chat-input-bar">
      <input
        v-model="inputText"
        type="text"
        placeholder="输入消息..."
        class="chat-input"
        placeholder-class="ph"
        @confirm="sendMessage"
      />
      <view class="btn-media" @tap="showMediaMenu">
        <text>➕</text>
      </view>
      <button class="btn-send" @tap="sendMessage">发送</button>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import { useAuthStore } from '../../stores/auth'
import request, { processImageUrl, BASE_URL } from '../../utils/request'
import wsManager from '../../utils/websocket'

const authStore = useAuthStore()

const friendId = ref(0)
const contactName = ref('')
const contactAvatar = ref('')
const contactColor = ref('var(--primary)')
const myName = ref('')
const myAvatar = ref('')
const inputText = ref('')
const scrollTop = ref(0)
const scrollIntoView = ref('')

interface Message {
  id: number
  content: string
  type: number
  createdAt: string
  isSelf: boolean
  status: string
}

const messages = ref<Message[]>([])
let pollTimer: any = null

let unsubscribeMessage: (() => void) | null = null
let unsubscribeRead: (() => void) | null = null

onMounted(async () => {
  if (!authStore.token) {
    uni.reLaunch({ url: '/pages/login/login' })
    return
  }
  myName.value = authStore.userInfo?.username || ''
  myAvatar.value = processImageUrl(authStore.userInfo?.avatar || '')

  // If avatar not in store yet (existing session before login fix), fetch from backend
  if (!myAvatar.value && authStore.token) {
    request<any>('/users/me').then((res: any) => {
      if (res?.code === 200 && res.data?.avatar) {
        myAvatar.value = processImageUrl(res.data.avatar)
      }
    }).catch(() => {})
  }

  const pages = getCurrentPages()
  const page = pages[pages.length - 1] as any
  const opts = page?.options || {}
  friendId.value = parseInt(opts.friendId || opts.id || '0')
  contactName.value = opts.name || ''
  contactAvatar.value = processImageUrl(opts.avatar || '')

  if (friendId.value) {
    await loadHistory()
    scrollToBottom()
    connectWebSocket()
    startPolling()
    // Mark conversation as read using correct endpoint
    request<any>({
      url: `/chat/read-all/${friendId.value}`,
      method: 'POST',
    }).catch(() => {})
  }
})

onUnmounted(() => {
  // Unsubscribe from WebSocket events
  if (unsubscribeMessage) unsubscribeMessage()
  if (unsubscribeRead) unsubscribeRead()
  if (pollTimer) clearInterval(pollTimer)
})

async function loadHistory() {
  try {
    // Backend uses page starting from 1, size default 20
    const res = await request<any>(`/chat/history/${friendId.value}?page=1&size=50`)
    if (res?.code === 200) {
      const list = res.data || []
      messages.value = list.map((m: any) => {
        // type: 1=text, 2=image, 3=video
        const msgType = m.type || 1
        let content = m.content || ''
        // For image/video messages, content holds the URL
        if ((msgType === 2 || msgType === 3) && content) {
          content = processImageUrl(content)
        }
        return {
          id: m.id,
          content,
          type: msgType,
          createdAt: formatTime(m.createTime || m.createdAt),
          isSelf: m.senderId === authStore.userInfo?.userId,
          status: m.status === 2 || m.status === 5 ? 'RECALLED' : 'SENT',
        }
      })
    }
  } catch (_) {
    uni.showToast({ title: '加载聊天记录失败', icon: 'none' })
  }
}

function formatTime(t: string): string {
  if (!t) return ''
  const d = new Date(t)
  const now = new Date()
  const diff = now.getTime() - d.getTime()
  if (diff < 60000) return '刚刚'
  if (diff < 3600000) return `${Math.floor(diff / 60000)}分钟前`
  if (diff < 86400000) {
    return `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`
  }
  return `${d.getMonth() + 1}/${d.getDate()}`
}

async function sendMessage() {
  if (!inputText.value.trim()) return
  const text = inputText.value.trim()
  inputText.value = ''

  const tempId = Date.now()
  messages.value.push({
    id: tempId,
    content: text,
    type: 1,
    createdAt: '发送中...',
    isSelf: true,
    status: 'SENDING',
  })
  scrollToBottom()

  try {
    const res = await request<any>({
      url: '/chat/messages/send',
      method: 'POST',
      data: {
        receiverId: friendId.value,
        content: text,
        type: 1,
      },
    })
    if (res?.code === 200) {
      const idx = messages.value.findIndex((m) => m.id === tempId)
      if (idx !== -1) {
        messages.value[idx].id = res.data?.id || tempId
        messages.value[idx].createdAt = formatTime(new Date().toISOString())
        messages.value[idx].status = 'SENT'
        messages.value[idx].type = 1
      }
    }
  } catch (_) {
    const idx = messages.value.findIndex((m) => m.id === tempId)
    if (idx !== -1) {
      messages.value[idx].status = 'FAILED'
    }
    uni.showToast({ title: '发送失败', icon: 'none' })
  }
  scrollToBottom()
}

function recallMessage(msg: Message) {
  if (msg.status === 'RECALLED') return
  // Check 2-minute limit
  if (!canRecall(msg)) {
    uni.showToast({ title: '已超过2分钟，无法撤回', icon: 'none' })
    return
  }
  uni.showModal({
    title: '撤回消息',
    content: '确定要撤回此消息吗？',
    success: async (res) => {
      if (res.confirm) {
        try {
          const r = await request<any>({
            url: `/chat/messages/${msg.id}/recall`,
            method: 'POST',
          })
          if (r?.code === 200) {
            msg.status = 'RECALLED'
            msg.content = '已撤回一条消息'
          }
        } catch (_) {}
      }
    },
  })
}

function canRecall(msg: Message): boolean {
  // Messages can only be recalled within 2 minutes
  if (msg.status === 'RECALLED' || msg.status === 'SENDING') return false
  const now = Date.now()
  const msgTime = new Date(msg.createdAt).getTime()
  if (isNaN(msgTime)) return true // can't determine, allow
  return (now - msgTime) < 120000 // 2 minutes
}

function showMediaMenu() {
  uni.showActionSheet({
    itemList: ['图片', '拍摄', '视频'],
    success: (res) => {
      if (res.tapIndex === 0) chooseImage()
      else if (res.tapIndex === 1) chooseCamera()
      else if (res.tapIndex === 2) chooseVideo()
    },
  })
}

async function chooseImage() {
  try {
    const res = await uni.chooseImage({
      count: 1,
      sizeType: ['compressed'],
      sourceType: ['album'],
    })
    if (res.tempFilePaths?.length) {
      await uploadAndSendMedia(res.tempFilePaths[0], '/upload/image', 2)
    }
  } catch (_) {}
}

async function chooseCamera() {
  try {
    const res = await uni.chooseImage({
      count: 1,
      sourceType: ['camera'],
    })
    if (res.tempFilePaths?.length) {
      await uploadAndSendMedia(res.tempFilePaths[0], '/upload/image', 2)
    }
  } catch (_) {}
}

async function chooseVideo() {
  try {
    const res = await uni.chooseVideo({
      sourceType: ['album', 'camera'],
      maxDuration: 60,
      compressed: true,
    })
    if (res.tempFilePath) {
      await uploadAndSendMedia(res.tempFilePath, '/upload/video', 3)
    }
  } catch (_) {}
}

async function uploadAndSendMedia(filePath: string, endpoint: string, type: number) {
  const tempId = Date.now()
  const placeholder = type === 2 ? '[图片]' : '[视频]'
  messages.value.push({
    id: tempId,
    content: placeholder,
    type,
    createdAt: '发送中...',
    isSelf: true,
    status: 'SENDING',
  })
  scrollToBottom()

  try {
    uni.showLoading({ title: '上传中...' })
    const uploadRes = await new Promise<any>((resolve, reject) => {
      uni.uploadFile({
        url: `${BASE_URL}${endpoint}`,
        filePath,
        name: 'file',
        header: { Authorization: `Bearer ${authStore.token}` },
        success: (r) => resolve(JSON.parse(r.data)),
        fail: reject,
      })
    })
    uni.hideLoading()

    if (uploadRes.code === 200 && uploadRes.data?.url) {
      const url = processImageUrl(uploadRes.data.url)
      const sendRes = await request<any>({
        url: '/chat/messages/send',
        method: 'POST',
        data: {
          receiverId: friendId.value,
          content: uploadRes.data.url,
          type,
        },
      })
      if (sendRes?.code === 200) {
        const idx = messages.value.findIndex((m) => m.id === tempId)
        if (idx !== -1) {
          messages.value[idx].id = sendRes.data?.id || tempId
          messages.value[idx].content = url
          messages.value[idx].createdAt = formatTime(new Date().toISOString())
          messages.value[idx].status = 'SENT'
        }
      }
    } else {
      throw new Error('upload failed')
    }
  } catch (_) {
    uni.hideLoading()
    const idx = messages.value.findIndex((m) => m.id === tempId)
    if (idx !== -1) {
      messages.value[idx].status = 'FAILED'
    }
    uni.showToast({ title: type === 2 ? '发送图片失败' : '发送视频失败', icon: 'none' })
  }
  scrollToBottom()
}

function previewImage(url: string) {
  if (url) uni.previewImage({ urls: [url] })
}

function connectWebSocket() {
  wsManager.connect().then(() => {
    console.log('[ChatDetail] WebSocket connected')
    
    // Subscribe to new message events for this conversation
    unsubscribeMessage = wsManager.on('new_message', (data) => {
      if (data.senderId === friendId.value || data.senderId === authStore.userInfo?.userId) {
        console.log('[ChatDetail] New message in this conversation')
        if (data.senderId !== authStore.userInfo?.userId) {
          const msgType = data.type || 1
          let content = data.content || ''
          if ((msgType === 2 || msgType === 3) && content) {
            content = processImageUrl(content)
          }
          messages.value.push({
            id: data.messageId || Date.now(),
            content,
            type: msgType,
            createdAt: formatTime(new Date().toISOString()),
            isSelf: false,
            status: 'SENT',
          })
          scrollToBottom()
        }
      }
    })
    
    // Subscribe to message read events
    unsubscribeRead = wsManager.on('message_read', (data) => {
      // Backend sends friendId=the user who marked as read
      // So if friendId matches our conversation partner, mark our sent messages as read
      if (data.friendId === friendId.value || data.userId === friendId.value) {
        console.log('[ChatDetail] Messages read by friend')
        messages.value.forEach((m) => {
          if (m.isSelf && m.status === 'SENT') {
            m.status = 'READ'
          }
        })
      }
    })
  }).catch((err) => {
    console.error('[ChatDetail] WebSocket connection failed:', err)
  })
}

function startPolling() {
  pollTimer = setInterval(() => {
    loadHistory()
  }, 30000)
}

function scrollToBottom() {
  nextTick(() => {
    const last = messages.value[messages.value.length - 1]
    if (last) {
      scrollIntoView.value = 'msg-' + last.id
    }
    scrollTop.value = 999999
  })
}
</script>

<style>
.chat-detail-container {
  min-height: 100vh;
  background: transparent;
  display: flex;
  flex-direction: column;
}

.messages-list {
  flex: 1;
  padding: 30rpx;
  padding-bottom: 140rpx;
}

.message-item {
  display: flex;
  align-items: flex-start;
  margin-bottom: 32rpx;
}

.message-self {
  justify-content: flex-end;
}

.msg-avatar-wrapper {
  flex-shrink: 0;
  width: 64rpx;
  height: 64rpx;
  border-radius: 50%;
  overflow: hidden;
  margin: 0 16rpx;
}

.msg-avatar {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28rpx;
  color: #ffffff;
  font-weight: bold;
  background: var(--primary-soft);
}

.msg-avatar-img {
  width: 100%;
  height: 100%;
}

.self-avatar-bg {
  background: var(--primary-gradient);
  color: #ffffff;
}

.msg-body {
  max-width: 65%;
}

.msg-bubble {
  background: var(--card);
  border-radius: 20rpx;
  padding: 20rpx 28rpx;
  border: 1rpx solid var(--card-border);
  box-shadow: var(--shadow-sm);
}

.bubble-self {
  background: var(--primary-gradient);
  border: none;
  box-shadow: 0 4rpx 16rpx rgba(99, 102, 241, 0.2);
}

.bubble-self .msg-text {
  color: #ffffff;
}

.msg-text {
  font-size: 28rpx;
  color: var(--text);
  line-height: 1.5;
}

.msg-bubble-media {
  padding: 8rpx !important;
  overflow: hidden;
}

.msg-image {
  max-width: 400rpx;
  border-radius: 12rpx;
  display: block;
}

.msg-video {
  width: 400rpx;
  height: 280rpx;
  border-radius: 12rpx;
  display: block;
}

.msg-meta {
  display: flex;
  align-items: center;
  gap: 8rpx;
  margin-top: 8rpx;
}

.msg-time {
  font-size: 20rpx;
  color: var(--text-muted);
}

.message-self .msg-meta {
  justify-content: flex-end;
}

.msg-recalled {
  font-size: 20rpx;
  color: var(--text-muted);
  font-style: italic;
}

.msg-read {
  font-size: 20rpx;
  color: var(--primary);
}

.msg-sending {
  font-size: 20rpx;
  color: var(--text-muted);
  font-style: italic;
}

.msg-failed {
  font-size: 20rpx;
  color: var(--danger);
}

.chat-input-bar {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background: var(--card);
  padding: 16rpx 30rpx;
  padding-bottom: calc(16rpx + env(safe-area-inset-bottom));
  padding-bottom: calc(16rpx + constant(safe-area-inset-bottom));
  display: flex;
  align-items: center;
  gap: 20rpx;
  border-top: 1rpx solid var(--card-border);
  box-shadow: 0 -4rpx 16rpx rgba(0, 0, 0, 0.04);
}

.chat-input {
  flex: 1;
  height: 72rpx;
  background: var(--bg);
  border-radius: 36rpx;
  padding: 0 30rpx;
  font-size: 28rpx;
  color: var(--text);
  border: 1rpx solid var(--card-border);
}

.ph {
  color: var(--text-muted);
}

.btn-media {
  width: 72rpx;
  height: 72rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 40rpx;
  flex-shrink: 0;
}

.btn-send {
  width: 120rpx;
  height: 72rpx;
  background: var(--primary-gradient);
  border-radius: 36rpx;
  color: #ffffff;
  font-size: 26rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
  flex-shrink: 0;
  box-shadow: 0 4rpx 12rpx rgba(99, 102, 241, 0.25);
}

.btn-send::after {
  border: none;
}
</style>
