<template>
  <div class="channel-page">
    <div class="channel-header">
      <div class="channel-info">
        <div class="channel-avatar">{{ (channel.name || '?').charAt(0) }}</div>
        <div>
          <h1 class="channel-title">{{ channel.name || '' }}</h1>
          <p class="channel-desc">{{ channel.description || '' }}</p>
          <div class="channel-meta">
            <span>编号: {{ channel.channelCode || '' }}</span>
            <span>帖子: {{ channel.postCount || 0 }}</span>
          </div>
        </div>
      </div>
      <div class="channel-actions">
        <button class="action-btn secondary" @click="showMembers = !showMembers">成员</button>
        <button class="action-btn secondary" @click="$router.push({ name: 'GroupChat', params: { id: route.params.id }, query: { name: channel.name || '群聊' } })">群聊</button>
        <button v-if="isChannelOwnerOrAdmin" class="action-btn secondary" @click="showApps = !showApps; if(showApps) fetchPendingApps()">
          申请 ({{ pendingApps.length }})
        </button>
        <button class="join-btn" :class="{ joined: isJoined }" @click="toggleJoin">{{ isJoined ? '已加入' : '加入' }}</button>
      </div>
    </div>

    <div v-if="showMembers" class="members-panel">
      <h3>频道成员</h3>
      <div v-for="m in members" :key="m.id" class="member-item">
        <div class="member-avatar-wrap">
          <img v-if="m.avatar" :src="m.avatar" class="member-avatar-img" />
          <span v-else class="member-avatar">{{ (m.username || '?').charAt(0) }}</span>
        </div>
        <span class="member-name">{{ m.username || '用户' }}</span>
        <span class="member-role" :data-role="m.role">{{ m.role === 'owner' ? '频道主' : m.role === 'admin' ? '管理员' : '成员' }}</span>
      </div>
    </div>

    <div v-if="showApps && pendingApps.length > 0" class="applications-panel">
      <h3>待审核申请 ({{ pendingApps.length }})</h3>
      <div v-for="app in pendingApps" :key="app.id" class="app-item">
        <span>用户 #{{ app.userId }}</span>
        <div class="app-actions">
          <button class="action-btn approve" @click="approveApp(app.id, true)">同意</button>
          <button class="action-btn reject" @click="approveApp(app.id, false)">拒绝</button>
        </div>
      </div>
    </div>

    <div class="posts-list">
      <div v-for="post in posts" :key="post.id" class="post-item" :class="{ pinned: post.isPinned }" @click="$router.push('/post/' + post.id)">
        <div v-if="post.isPinned" class="pin-badge">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor">
            <path d="M16 12V4h1V2H7v2h1v8l-2 2v2h5.2v6h1.6v-6H18v-2l-2-2z"/>
          </svg>
          置顶
        </div>
        <div class="post-avatar">{{ (post.author || '?').charAt(0) }}</div>
        <div class="post-body">
          <div class="post-meta">
            <span class="post-author">{{ post.author || '' }}</span>
            <span class="post-time">{{ post.time || '' }}</span>
          </div>
          <h3 class="post-title">{{ post.title }}</h3>
          <p class="post-excerpt">{{ post.content }}</p>
          <div class="post-stats">
            <span>❤️ {{ post.likeCount || 0 }}</span>
            <span>💬 {{ post.commentCount || 0 }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { api } from '../api/client'
import { useAuthStore } from '../stores/auth'

const route = useRoute()
const authStore = useAuthStore()
const channel = ref<any>({})
const posts = ref<any[]>([])
const members = ref<any[]>([])
const showMembers = ref(false)
const isJoined = ref(true)
const pendingApps = ref<any[]>([])
const showApps = ref(false)
const isChannelOwnerOrAdmin = ref(false)

async function fetchChannel() {
  try {
    const id = route.params.id
    const res = await api.get(`/posts/channel/${id}`, { params: { page: 1, size: 20 } })
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      posts.value = res.data.data.map((p: any) => ({
        id: p.id, title: p.topic || '帖子', content: p.content || '',
        author: p.username || '用户', time: p.createTime || '',
        likeCount: p.likeCount || 0, commentCount: p.commentCount || 0,
        isPinned: p.isPinned === 1,
      }))
    }
  } catch (e) {}
}

async function fetchMembers() {
  try {
    const id = route.params.id
    const res = await api.get(`/channels/${id}/members`)
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      members.value = res.data.data
      const currentUser = authStore.user
      if (currentUser) {
        isChannelOwnerOrAdmin.value = members.value.some(
          (m: any) => m.userId === currentUser.id && (m.role === 'owner' || m.role === 'admin')
        )
      }
    }
  } catch (e) {}
}

async function toggleJoin() {
  try {
    const id = route.params.id
    if (isJoined.value) {
      await api.post(`/channels/${id}/leave`)
    } else {
      await api.post(`/channels/${id}/join`)
    }
    isJoined.value = !isJoined.value
  } catch (e) {}
}

async function fetchPendingApps() {
  try {
    const id = route.params.id
    const res = await api.get(`/channels/${id}/applications`)
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      pendingApps.value = res.data.data
    }
  } catch (e) {}
}

async function approveApp(appId: number, approved: boolean) {
  try {
    await api.post(`/channels/applications/${appId}/approve`, { approved })
    pendingApps.value = pendingApps.value.filter(a => a.id !== appId)
  } catch (e: any) {
    alert(e.response?.data?.message || '操作失败')
  }
}

onMounted(() => {
  channel.value = { name: '频道', description: '', channelCode: 'CH-...', postCount: 0 }
  fetchChannel()
  fetchMembers()
})
</script>

<style scoped>
.channel-page { max-width: 800px; margin: 0 auto; }
.channel-header { display: flex; justify-content: space-between; align-items: flex-start; padding: 24px; background: var(--surface); border: 1px solid var(--outline-variant); border-radius: 20px; margin-bottom: 24px; }
.channel-info { display: flex; gap: 16px; }
.channel-avatar { width: 56px; height: 56px; border-radius: 16px; background: linear-gradient(135deg, var(--primary), var(--secondary)); display: flex; align-items: center; justify-content: center; font-size: 24px; font-weight: 700; color: #fff; }
.channel-title { font-size: 22px; font-weight: 700; margin-bottom: 4px; }
.channel-desc { font-size: 13px; color: var(--on-surface-variant); margin-bottom: 12px; max-width: 480px; line-height: 1.5; }
.channel-meta { display: flex; gap: 16px; font-size: 12px; color: var(--on-surface-variant); }
.channel-actions { display: flex; gap: 8px; }
.join-btn { padding: 10px 24px; border-radius: 12px; border: 1px solid var(--primary); background: rgba(124,159,203,0.1); color: var(--primary); font-size: 14px; font-weight: 600; cursor: pointer; transition: all 0.2s; }
.join-btn:hover { background: rgba(124,159,203,0.2); }
.join-btn.joined { background: rgba(74,222,128,0.15); border-color: #4ade80; color: #4ade80; }
.action-btn.secondary { padding: 10px 20px; border-radius: 10px; border: 1px solid var(--outline-variant); background: var(--surface); color: var(--on-surface); font-size: 13px; cursor: pointer; transition: all 0.2s; }
.action-btn.secondary:hover { border-color: var(--primary); }
.members-panel { padding: 16px; background: var(--surface); border: 1px solid var(--outline-variant); border-radius: 16px; margin-bottom: 16px; }
.members-panel h3 { font-size: 14px; margin-bottom: 12px; }
.member-item { display: flex; align-items: center; gap: 10px; padding: 8px 0; }
.member-avatar-wrap { width: 32px; height: 32px; border-radius: 8px; overflow: hidden; flex-shrink: 0; }
.member-avatar { width: 32px; height: 32px; border-radius: 8px; background: linear-gradient(135deg, var(--primary), var(--secondary)); display: flex; align-items: center; justify-content: center; font-size: 13px; font-weight: 700; color: #fff; }
.member-avatar-img { width: 100%; height: 100%; object-fit: cover; border-radius: 8px; }
.member-name { font-size: 13px; flex: 1; }
.member-role { font-size: 10px; padding: 2px 8px; border-radius: 6px; }
.member-role[data-role="owner"] { background: rgba(240, 173, 78, 0.2); color: #f0ad4e; }
.member-role[data-role="admin"] { background: rgba(74, 222, 128, 0.2); color: #4ade80; }
.member-role[data-role="member"] { background: rgba(255, 255, 255, 0.08); color: rgba(255, 255, 255, 0.5); }
.posts-list { display: flex; flex-direction: column; gap: 8px; }
.post-item { display: flex; gap: 12px; padding: 16px; background: var(--surface); border: 1px solid var(--outline-variant); border-radius: 14px; cursor: pointer; transition: all 0.2s; position: relative; }
.post-item:hover { border-color: var(--primary); transform: translateX(4px); }
.post-item.pinned { border-color: var(--primary); background: rgba(124, 159, 203, 0.08); }
.pin-badge { position: absolute; top: -8px; right: 12px; padding: 2px 8px; background: var(--primary); color: #fff; font-size: 10px; font-weight: 600; border-radius: 6px; display: flex; align-items: center; gap: 4px; }
.post-avatar { width: 40px; height: 40px; border-radius: 10px; background: linear-gradient(135deg, var(--primary), var(--secondary)); display: flex; align-items: center; justify-content: center; font-size: 16px; font-weight: 700; color: #fff; flex-shrink: 0; }
.post-body { flex: 1; }
.post-meta { display: flex; gap: 8px; align-items: center; margin-bottom: 4px; }
.post-author { font-size: 13px; font-weight: 600; }
.post-time { font-size: 11px; color: var(--on-surface-variant); }
.post-title { font-size: 15px; font-weight: 600; margin-bottom: 4px; }
.post-excerpt { font-size: 13px; color: var(--on-surface-variant); margin-bottom: 8px; }
.post-stats { display: flex; gap: 12px; font-size: 12px; color: var(--on-surface-variant); }
.applications-panel { padding: 16px; background: var(--surface); border: 1px solid var(--outline-variant); border-radius: 16px; margin-bottom: 16px; }
.applications-panel h3 { font-size: 14px; margin-bottom: 12px; }
.app-item { display: flex; justify-content: space-between; align-items: center; padding: 8px 0; border-bottom: 1px solid var(--outline-variant); }
.app-item:last-child { border-bottom: none; }
.app-item span { font-size: 13px; }
.app-actions { display: flex; gap: 6px; }
.app-actions button { padding: 4px 12px; border: none; border-radius: 6px; font-size: 12px; cursor: pointer; }
.app-actions button.approve { background: rgba(74,222,128,0.15); color: #4ade80; }
.app-actions button.reject { background: rgba(255,107,107,0.15); color: #ff6b6b; }
</style>
