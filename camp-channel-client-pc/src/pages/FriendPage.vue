<template>
  <div class="friend-page">
    <div class="friend-sidebar">
      <div class="sidebar-header">
        <h3>好友列表</h3>
        <span class="friend-count">{{ friends.length }} 人</span>
      </div>
      <div class="search-actions">
        <button class="action-btn small" @click="showSearch = !showSearch">搜索用户</button>
        <button class="action-btn small" @click="fetchPendingRequests(); showSearch = false">好友申请({{ pendingRequests.length }})</button>
      </div>
      <div v-if="showSearch" class="search-users">
        <input v-model="searchKeyword" placeholder="搜索用户名/邮箱..." @keyup.enter="searchUsers" />
        <button @click="searchUsers">搜索</button>
        <div v-for="u in searchResults" :key="u.id" class="search-result-item">
          <span>{{ u.username }}</span>
          <span>{{ u.email }}</span>
          <button @click="sendFriendRequest(u.id)">加好友</button>
        </div>
      </div>
      <div v-if="pendingRequests.length > 0 && !showSearch" class="pending-section">
        <h4>待处理申请</h4>
        <div v-for="r in pendingRequests" :key="r.id" class="pending-item">
          <div class="pending-avatar">{{ (r.username || '?').charAt(0) }}</div>
          <span class="pending-name">{{ r.username || '用户 #' + r.userId }}</span>
          <button class="approve-btn" @click="approveRequest(r.id)">同意</button>
          <button class="reject-btn" @click="rejectRequest(r.id)">拒绝</button>
        </div>
      </div>
      <div class="search-box">
        <input v-model="searchQuery" placeholder="搜索好友..." />
      </div>
      <div class="friend-list">
        <div
          v-for="(friend, i) in filteredFriends"
          :key="friend.id"
          class="friend-item"
          :class="{ active: selectedIndex === i }"
          @click="selectedIndex = i"
        >
          <div class="friend-avatar-wrap">
            <img v-if="friend.avatar" :src="friend.avatar" class="friend-avatar-img" />
            <div v-else class="friend-avatar">{{ (friend.name || '?').charAt(0) }}</div>
            <span class="online-dot" :class="{ online: friend.online }"></span>
          </div>
          <div class="friend-info">
            <div class="friend-name">{{ friend.name }}</div>
            <div class="friend-email">{{ friend.email }}</div>
          </div>
        </div>
      </div>
    </div>
    <div class="friend-main" v-if="selectedFriend">
      <div class="profile-header">
        <div class="profile-avatar">{{ (selectedFriend.name || '?').charAt(0) }}</div>
        <h2>{{ selectedFriend.name }}</h2>
        <p>{{ selectedFriend.email }}</p>
        <div class="profile-actions">
          <button class="action-btn primary" @click="$router.push('/chat?friendId=' + selectedFriend.id)">发消息</button>
        </div>
      </div>
    </div>
    <div v-else class="friend-empty">
      <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1" opacity="0.3"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
      <p>选择一个好友查看详情</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { api } from '../api/client'
import { useAuthStore } from '../stores/auth'

const authStore = useAuthStore()
const searchQuery = ref('')
const selectedIndex = ref(-1)
const friends = ref<any[]>([])
let onlineTimer: any = null

const filteredFriends = computed(() =>
  friends.value.filter(f => (f.name || '').includes(searchQuery.value))
)
const selectedFriend = computed(() =>
  selectedIndex.value >= 0 ? filteredFriends.value[selectedIndex.value] : null
)

const searchKeyword = ref('')
const searchResults = ref<any[]>([])
const showSearch = ref(false)
const pendingRequests = ref<any[]>([])

async function searchUsers() {
  if (!searchKeyword.value.trim()) return
  try {
    const res = await api.get('/friends/search', { params: { keyword: searchKeyword.value } })
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      searchResults.value = res.data.data.filter((u: any) => u.id !== (authStore.user?.id || 0))
    }
  } catch (e) {}
}

async function sendFriendRequest(friendId: number) {
  try {
    await api.post('/friends/request', { friendId })
    alert('好友申请已发送')
    searchResults.value = searchResults.value.filter(u => u.id !== friendId)
  } catch (e: any) {
    alert(e.response?.data?.message || '发送失败')
  }
}

async function fetchPendingRequests() {
  try {
    const res = await api.get('/friends/requests/pending')
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      pendingRequests.value = await Promise.all(res.data.data.map(async (r: any) => {
        try {
          const uRes = await api.get(`/users/${r.userId}`)
          if (uRes.data.code === 200) {
            r.username = uRes.data.data.username || '用户'
            r.avatar = uRes.data.data.avatar || ''
          }
        } catch {}
        return r
      }))
    }
  } catch (e) {}
}

async function approveRequest(requestId: number) {
  try {
    await api.post(`/friends/requests/${requestId}/approve`)
    pendingRequests.value = pendingRequests.value.filter(r => r.id !== requestId)
    fetchFriends()
  } catch (e) {}
}

async function rejectRequest(requestId: number) {
  try {
    await api.post(`/friends/requests/${requestId}/reject`)
    pendingRequests.value = pendingRequests.value.filter(r => r.id !== requestId)
  } catch (e) {}
}

async function fetchFriends() {
  try {
    const res = await api.get('/friends/list')
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      friends.value = res.data.data.map((u: any) => ({
        id: u.id,
        name: u.username || '用户',
        email: u.email || '',
        avatar: u.avatar || '',
        online: false,
      }))
      fetchOnlineStatus()
    }
  } catch (e) {}
}

async function fetchOnlineStatus() {
  if (friends.value.length === 0) return
  const ids = friends.value.map(f => f.id).join(',')
  try {
    const res = await api.get('/chat/online/batch', { params: { userIds: ids } })
    if (res.data.code === 200 && res.data.data) {
      for (const f of friends.value) {
        if (res.data.data[f.id] !== undefined) {
          f.online = res.data.data[f.id]
        }
      }
    }
  } catch {}
}

onMounted(() => {
  fetchFriends()
  fetchPendingRequests()
  onlineTimer = setInterval(fetchOnlineStatus, 30000)
})

onUnmounted(() => {
  if (onlineTimer) clearInterval(onlineTimer)
})
</script>

<style scoped>
.friend-page { display: flex; height: calc(100vh - 64px); gap: 0; max-width: 1000px; margin: 0 auto; }
.friend-sidebar { width: 320px; background: var(--card); border: 1px solid var(--border); border-radius: 20px 0 0 20px; display: flex; flex-direction: column; flex-shrink: 0; }
.sidebar-header { display: flex; justify-content: space-between; align-items: center; padding: 20px 16px 12px; }
.sidebar-header h3 { font-size: 16px; font-weight: 600; }
.friend-count { font-size: 12px; color: var(--text-secondary); }
.search-box { padding: 0 16px 12px; }
.search-box input { width: 100%; padding: 10px 14px; border: 1px solid var(--border); border-radius: 10px; background: rgba(255,255,255,0.03); color: var(--text); font-size: 13px; outline: none; }
.search-box input:focus { border-color: var(--primary); }
.friend-list { flex: 1; overflow-y: auto; }
.friend-item { display: flex; align-items: center; gap: 12px; padding: 12px 16px; cursor: pointer; transition: background 0.2s; }
.friend-item:hover { background: var(--card); }
.friend-item.active { background: rgba(124,159,203,0.08); }
.friend-avatar-wrap { position: relative; width: 44px; height: 44px; flex-shrink: 0; }
.friend-avatar { width: 44px; height: 44px; border-radius: 12px; background: linear-gradient(135deg, var(--primary), var(--accent)); display: flex; align-items: center; justify-content: center; font-size: 18px; font-weight: 700; color: #fff; }
.friend-avatar-img { width: 44px; height: 44px; border-radius: 12px; object-fit: cover; display: block; }
.online-dot { position: absolute; bottom: 0; right: 0; width: 10px; height: 10px; border-radius: 50%; border: 2px solid var(--card); background: #888; }
.online-dot.online { background: #4ade80; }
.friend-info { flex: 1; min-width: 0; }
.friend-name { font-size: 14px; font-weight: 600; margin-bottom: 2px; }
.friend-email { font-size: 12px; color: var(--text-secondary); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.friend-main { flex: 1; background: var(--card); border: 1px solid var(--border); border-left: none; border-radius: 0 20px 20px 0; display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 40px; }
.profile-header { text-align: center; }
.profile-avatar { width: 80px; height: 80px; border-radius: 20px; background: linear-gradient(135deg, var(--primary), var(--accent)); display: flex; align-items: center; justify-content: center; font-size: 32px; font-weight: 700; color: #fff; margin: 0 auto 16px; }
.profile-header h2 { font-size: 22px; font-weight: 700; margin-bottom: 4px; }
.profile-header p { font-size: 14px; color: var(--text-secondary); margin-bottom: 24px; }
.profile-actions { display: flex; gap: 12px; justify-content: center; }
.action-btn { padding: 10px 24px; border-radius: 10px; border: none; font-size: 14px; font-weight: 600; cursor: pointer; transition: all 0.2s; }
.action-btn.primary { background: linear-gradient(135deg, var(--primary), var(--accent)); color: #fff; }
.action-btn.small { padding: 6px 12px; font-size: 12px; background: var(--card); border: 1px solid var(--border); color: var(--text-secondary); border-radius: 8px; flex: 1; }
.action-btn.small:hover { border-color: var(--primary); color: var(--text); }
.search-actions { display: flex; gap: 8px; padding: 0 16px 12px; }
.search-users { padding: 0 16px 12px; display: flex; flex-direction: column; gap: 8px; }
.search-users input { width: 100%; padding: 8px 12px; border: 1px solid var(--border); border-radius: 8px; background: rgba(255,255,255,0.03); color: var(--text); font-size: 13px; outline: none; box-sizing: border-box; }
.search-users input:focus { border-color: var(--primary); }
.search-users > button { padding: 8px; border: none; border-radius: 8px; background: var(--primary); color: #fff; font-size: 13px; cursor: pointer; }
.search-result-item { display: flex; align-items: center; gap: 8px; padding: 8px; border: 1px solid var(--border); border-radius: 8px; font-size: 13px; }
.search-result-item span:first-child { font-weight: 600; flex: 1; }
.search-result-item span:nth-child(2) { color: var(--text-secondary); font-size: 11px; }
.search-result-item button { padding: 4px 10px; border: none; border-radius: 6px; background: var(--primary); color: #fff; font-size: 12px; cursor: pointer; }
.pending-section { padding: 0 16px 12px; }
.pending-section h4 { font-size: 13px; font-weight: 600; margin-bottom: 8px; color: var(--text-secondary); }
.pending-item { display: flex; align-items: center; gap: 8px; padding: 8px 0; border-bottom: 1px solid var(--border); }
.pending-item:last-child { border-bottom: none; }
.pending-avatar { width: 28px; height: 28px; border-radius: 8px; background: linear-gradient(135deg, var(--primary), var(--accent)); display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: 700; color: #fff; flex-shrink: 0; }
.pending-name { flex: 1; font-size: 13px; }
.approve-btn { padding: 4px 12px; border: none; border-radius: 6px; background: rgba(74,222,128,0.15); color: #4ade80; font-size: 12px; cursor: pointer; }
.reject-btn { padding: 4px 12px; border: none; border-radius: 6px; background: rgba(255,107,107,0.15); color: #ff6b6b; font-size: 12px; cursor: pointer; }
.friend-empty { flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 12px; color: var(--text-secondary); }

@media (max-width: 768px) {
.friend-page { flex-direction: column; height: calc(100vh - 68px); max-width: 100%; }
.friend-sidebar { width: 100%; border-radius: 0; max-height: 50vh; }
.friend-main { border-radius: 0; border-left: 1px solid var(--border); }
}
</style>
