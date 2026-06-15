<template>
  <view class="group-chat-page">
    <view class="chat-header">
      <text class="header-title">{{ channelName || '频道群聊' }}</text>
      <text class="header-sub">{{ memberCount }}位成员</text>
    </view>

    <scroll-view
      scroll-y
      class="messages-list"
      :scroll-top="scrollTop"
      :scroll-into-view="scrollIntoView"
    >
      <view v-if="loadingMore" class="loading-more">
        <text>加载更多...</text>
      </view>

      <view
        v-for="(msg, idx) in messages"
        :key="msg.id || idx"
        :id="'msg-' + (msg.id || idx)"
        class="message-item"
        :class="{ 'message-self': msg.isSelf, 'message-recalled': msg.status === 2 }"
      >
        <template v-if="!msg.isSelf">
          <view class="msg-avatar-wrapper">
            <image v-if="msg.avatar" :src="msg.avatar" mode="aspectFill" class="msg-avatar-img" />
            <view v-else class="msg-avatar-placeholder">
              <text>{{ (msg.username || '?').charAt(0) }}</text>
            </view>
          </view>
          <view class="msg-body">
            <text class="msg-sender">{{ msg.username || '未知' }}</text>
            <view class="msg-bubble" @longpress="handleLongPress(msg)">
              <text v-if="msg.status === 2" class="msg-text recalled-text">消息已撤回</text>
              <template v-else>
                <text v-if="msg.content" class="msg-text">{{ msg.content }}</text>
                <image v-if="msg.mediaUrl && msg.msgType === 2" :src="msg.mediaUrl" mode="widthFix" class="msg-image" @tap="previewImage(msg.mediaUrl)" />
                <view v-if="msg.mediaUrl && msg.msgType === 3" class="msg-video" @tap="previewVideo(msg.mediaUrl)">
                  <text class="video-icon">▶</text>
                  <text class="video-label">视频消息</text>
                </view>
              </template>
            </view>
            <text class="msg-time">{{ msg.time }}</text>
          </view>
        </template>

        <template v-else>
          <view class="msg-body msg-body-self">
            <view class="msg-bubble bubble-self" @longpress="handleLongPress(msg)">
              <text v-if="msg.status === 2" class="msg-text recalled-text">消息已撤回</text>
              <template v-else>
                <text v-if="msg.content" class="msg-text">{{ msg.content }}</text>
                <image v-if="msg.mediaUrl && msg.msgType === 2" :src="msg.mediaUrl" mode="widthFix" class="msg-image" @tap="previewImage(msg.mediaUrl)" />
                <view v-if="msg.mediaUrl && msg.msgType === 3" class="msg-video" @tap="previewVideo(msg.mediaUrl)">
                  <text class="video-icon">▶</text>
                  <text class="video-label">视频消息</text>
                </view>
              </template>
            </view>
            <text class="msg-time msg-time-self">{{ msg.time }}</text>
          </view>
          <view class="msg-avatar-wrapper">
            <image v-if="myAvatar" :src="myAvatar" mode="aspectFill" class="msg-avatar-img" />
            <view v-else class="msg-avatar-placeholder">
              <text>{{ (myName || '?').charAt(0) }}</text>
            </view>
          </view>
        </template>
      </view>

      <view v-if="!loading && messages.length === 0" class="empty-state">
        <text class="empty-icon">💬</text>
        <text class="empty-text">暂无群聊消息，快来聊天吧</text>
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
      <view class="btn-image" @tap="chooseImage">
        <text>📷</text>
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

const channelId = ref(0)
const channelName = ref('')
const memberCount = ref(0)
const myName = ref('')
const myAvatar = ref('')
const inputText = ref('')
const scrollTop = ref(0)
const scrollIntoView = ref('')
const loading = ref(false)
const loadingMore = ref(false)

interface GroupMsg {
  id: number
  content: string
  mediaUrl: string
  msgType: number
  status: number
  username: string
  avatar: string
  senderId: number
  time: string
  isSelf: boolean
}

const messages = ref<GroupMsg[]>([])
const page = ref(1)
const hasMore = ref(true)

let unsubscribeGroupMsg: (() => void) | null = null

onMounted(async () => {
  if (!authStore.token) {
    uni.reLaunch({ url: '/pages/login/login' })
    return
  }
  myName.value = authStore.userInfo?.username || ''
  myAvatar.value = processImageUrl(authStore.userInfo?.avatar || '')

  if (!myAvatar.value && authStore.token) {
    request<any>('/users/me').then((res: any) => {
      if (res?.code === 200 && res.data?.avatar) {
        myAvatar.value = processImageUrl(res.data.avatar)
      }
    }).catch(() => {})
  }

  const pages = getCurrentPages()
  const p = pages[pages.length - 1] as any
  const opts = p?.options || {}
  channelId.value = parseInt(opts.channelId || '0')
  channelName.value = decodeURIComponent(opts.channelName || '频道群聊')

  if (channelId.value) {
    await loadMessages()
    scrollToBottom()
    connectWebSocket()
  }
})

onUnmounted(() => {
  if (unsubscribeGroupMsg) unsubscribeGroupMsg()
})

async function loadMessages() {
  if (loading.value) return
  loading.value = true
  try {
    const res = await request<any>(`/group-messages/${channelId.value}?page=${page.value}&size=50`)
    if (res?.code === 200) {
      const list = (res.data || []).map((m: any) => ({
        id: m.id,
        content: m.content || '',
        mediaUrl: m.mediaUrl ? processImageUrl(m.mediaUrl) : '',
        msgType: m.msgType || 1,
        status: m.status || 1,
        username: m.username || '未知',
        avatar: processImageUrl(m.avatar || ''),
        senderId: m.senderId || 0,
        time: formatTime(m.createTime || m.createdAt),
        isSelf: m.senderId === authStore.userInfo?.userId,
      }))
      // API returns newest first, reverse for display
      list.reverse()
      if (page.value === 1) {
        messages.value = list
      } else {
        messages.value = [...list, ...messages.value]
      }
      if (list.length < 50) hasMore.value = false
    }
  } catch (_) {
    uni.showToast({ title: '加载消息失败', icon: 'none' })
  } finally {
    loading.value = false
    loadingMore.value = false
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
  return `${d.getMonth() + 1}/${d.getDate()} ${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`
}

async function sendMessage() {
  if (!inputText.value.trim()) return
  const text = inputText.value.trim()
  inputText.value = ''

  const tempId = Date.now()
  messages.value.push({
    id: tempId,
    content: text,
    mediaUrl: '',
    msgType: 1,
    status: 1,
    username: myName.value,
    avatar: myAvatar.value,
    senderId: authStore.userInfo?.userId || 0,
    time: '刚刚',
    isSelf: true,
  })
  scrollToBottom()

  try {
    const res = await request<any>({
      url: '/group-messages',
      method: 'POST',
      data: {
        channelId: channelId.value,
        content: text,
        mediaUrl: null,
        msgType: 1,
      },
    })
    if (res?.code === 200 && res.data) {
      const idx = messages.value.findIndex(m => m.id === tempId)
      if (idx !== -1) {
        messages.value[idx].id = res.data.id || tempId
        messages.value[idx].time = formatTime(res.data.createTime || new Date().toISOString())
      }
    }
  } catch (_) {
    uni.showToast({ title: '发送失败', icon: 'none' })
  }
  scrollToBottom()
}

async function chooseImage() {
  try {
    const res = await uni.chooseImage({
      count: 1,
      sizeType: ['compressed'],
      sourceType: ['album', 'camera'],
    })
    if (res.tempFilePaths?.length) {
      uni.showLoading({ title: '上传中...' })
      const uploadRes = await new Promise((resolve, reject) => {
        uni.uploadFile({
          url: `${BASE_URL}/upload/image`,
          filePath: res.tempFilePaths[0],
          name: 'file',
          header: { Authorization: `Bearer ${authStore.token}` },
          success: (r) => resolve(JSON.parse(r.data)),
          fail: reject,
        })
      }) as any
      uni.hideLoading()

      if (uploadRes.code === 200 && uploadRes.data?.url) {
        const mediaUrl = uploadRes.data.url
        // Send as image message
        const sendRes = await request<any>({
          url: '/group-messages',
          method: 'POST',
          data: {
            channelId: channelId.value,
            content: '[图片]',
            mediaUrl: mediaUrl,
            msgType: 2,
          },
        })
        if (sendRes?.code === 200) {
          messages.value.push({
            id: sendRes.data?.id || Date.now(),
            content: '[图片]',
            mediaUrl: processImageUrl(mediaUrl),
            msgType: 2,
            status: 1,
            username: myName.value,
            avatar: myAvatar.value,
            senderId: authStore.userInfo?.userId || 0,
            time: '刚刚',
            isSelf: true,
          })
          scrollToBottom()
        }
      }
    }
  } catch (_) {
    uni.hideLoading()
    uni.showToast({ title: '发送图片失败', icon: 'none' })
  }
}

function handleLongPress(msg: GroupMsg) {
  if (msg.status === 2) return
  // Only own messages can be recalled
  if (msg.senderId !== authStore.userInfo?.userId) return
  uni.showActionSheet({
    itemList: ['撤回消息'],
    success: async (res) => {
      if (res.tapIndex === 0) {
        try {
          const r = await request<any>({
            url: `/group-messages/${msg.id}`,
            method: 'DELETE',
          })
          if (r?.code === 200) {
            msg.status = 2
            uni.showToast({ title: '已撤回', icon: 'success' })
          }
        } catch (_) {
          uni.showToast({ title: '撤回失败', icon: 'none' })
        }
      }
    },
  })
}

function previewImage(url: string) {
  if (url) uni.previewImage({ urls: [url] })
}

function previewVideo(url: string) {
  if (url) {
    uni.navigateTo({
      url: `/pages/chat/detail?videoUrl=${encodeURIComponent(url)}`,
      fail: () => {
        // Fallback: open in browser
        // #ifdef H5
        window.open(url, '_blank')
        // #endif
      }
    })
  }
}

function connectWebSocket() {
  wsManager.connect().then(() => {
    unsubscribeGroupMsg = wsManager.on('new_group_message', (data: any) => {
      if (data.channelId === channelId.value && data.senderId !== authStore.userInfo?.userId) {
        messages.value.push({
          id: data.id || Date.now(),
          content: data.content || '',
          mediaUrl: data.mediaUrl ? processImageUrl(data.mediaUrl) : '',
          msgType: data.msgType || 1,
          status: 1,
          username: data.username || '未知',
          avatar: processImageUrl(data.avatar || ''),
          senderId: data.senderId || 0,
          time: '刚刚',
          isSelf: false,
        })
        scrollToBottom()
      }
    })
  }).catch((err) => {
    console.error('[GroupChat] WebSocket failed:', err)
  })
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

<style scoped>
.group-chat-page {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  background: var(--bg);
}

.chat-header {
  background: var(--card);
  padding: 24rpx 32rpx;
  border-bottom: 1rpx solid var(--card-border);
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.header-title {
  font-size: 32rpx;
  font-weight: 700;
  color: var(--text);
}

.header-sub {
  font-size: 24rpx;
  color: var(--text-muted);
}

.messages-list {
  flex: 1;
  padding: 24rpx;
  padding-bottom: 140rpx;
}

.message-item {
  display: flex;
  align-items: flex-start;
  margin-bottom: 28rpx;
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
  margin: 0 12rpx;
}

.msg-avatar-img {
  width: 100%;
  height: 100%;
}

.msg-avatar-placeholder {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28rpx;
  color: #ffffff;
  font-weight: bold;
  background: var(--primary);
}

.msg-body {
  max-width: 65%;
}

.msg-body-self {
  text-align: right;
}

.msg-sender {
  font-size: 22rpx;
  color: var(--text-muted);
  margin-bottom: 4rpx;
  display: block;
}

.msg-bubble {
  background: var(--card);
  border-radius: 20rpx;
  padding: 18rpx 24rpx;
  border: 1rpx solid var(--card-border);
}

.bubble-self {
  background: linear-gradient(135deg, var(--primary), var(--accent));
  border: none;
}

.bubble-self .msg-text {
  color: #ffffff;
}

.msg-text {
  font-size: 28rpx;
  color: var(--text);
  line-height: 1.5;
}

.recalled-text {
  color: var(--text-muted);
  font-style: italic;
  font-size: 24rpx;
}

.msg-image {
  max-width: 400rpx;
  border-radius: 12rpx;
  margin-top: 8rpx;
}

.msg-video {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  width: 300rpx;
  height: 200rpx;
  background: rgba(0, 0, 0, 0.3);
  border-radius: 12rpx;
  margin-top: 8rpx;
}

.video-icon {
  font-size: 48rpx;
  color: #ffffff;
}

.video-label {
  font-size: 22rpx;
  color: #ffffff;
  margin-top: 8rpx;
}

.msg-time {
  font-size: 20rpx;
  color: var(--text-muted);
  margin-top: 6rpx;
  display: block;
}

.msg-time-self {
  text-align: right;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 120rpx 0;
}

.empty-icon {
  font-size: 80rpx;
  margin-bottom: 16rpx;
}

.empty-text {
  font-size: 28rpx;
  color: var(--text-muted);
}

.loading-more {
  text-align: center;
  padding: 20rpx;
  color: var(--text-muted);
  font-size: 24rpx;
}

.chat-input-bar {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background: var(--card);
  padding: 16rpx 24rpx;
  padding-bottom: calc(16rpx + env(safe-area-inset-bottom));
  display: flex;
  align-items: center;
  gap: 16rpx;
  border-top: 1rpx solid var(--card-border);
}

.chat-input {
  flex: 1;
  height: 72rpx;
  background: var(--bg);
  border-radius: 36rpx;
  padding: 0 28rpx;
  font-size: 28rpx;
  color: var(--text);
  border: 1rpx solid var(--card-border);
}

.ph {
  color: var(--text-muted);
}

.btn-image {
  width: 72rpx;
  height: 72rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 40rpx;
}

.btn-send {
  height: 72rpx;
  padding: 0 32rpx;
  background: linear-gradient(135deg, var(--primary), var(--accent));
  border-radius: 36rpx;
  color: #ffffff;
  font-size: 26rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
  flex-shrink: 0;
}

.btn-send::after {
  border: none;
}
</style>
