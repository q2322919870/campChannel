<template>
  <div class="follow-list-page">
    <div class="page-header">
      <h1>{{ username }} 的关注</h1>
    </div>

    <div class="tabs">
      <button
        class="tab"
        :class="{ active: activeTab === 'followers' }"
        @click="activeTab = 'followers'"
      >
        粉丝 ({{ followers.length }})
      </button>
      <button
        class="tab"
        :class="{ active: activeTab === 'following' }"
        @click="activeTab = 'following'"
      >
        关注 ({{ following.length }})
      </button>
    </div>

    <div class="content">
      <div v-if="isLoading" class="loading">
        <div class="spinner"></div>
      </div>

      <template v-else>
        <!-- Followers Tab -->
        <div v-if="activeTab === 'followers'" class="user-list">
          <div v-if="followers.length === 0" class="empty-state">
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
              <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
              <circle cx="9" cy="7" r="4"/>
              <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
              <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
            </svg>
            <p>暂无粉丝</p>
          </div>
          <div v-else class="users">
            <div v-for="user in followers" :key="user.id" class="user-card">
              <div class="user-info" @click="viewProfile(user.id)">
                <div class="avatar" :style="{ background: `linear-gradient(135deg, var(--primary), var(--secondary))` }">
                  <img v-if="user.avatar" :src="user.avatar" />
                  <span v-else>{{ (user.username || '?').charAt(0) }}</span>
                </div>
                <div class="user-details">
                  <h3>{{ user.username }}</h3>
                </div>
              </div>
              <button
                v-if="user.id !== currentUserId"
                class="follow-btn"
                :class="{ following: user.isFollowing }"
                @click="toggleFollow(user.id, 'followers')"
              >
                {{ user.isFollowing ? '已关注' : '关注' }}
              </button>
            </div>
          </div>
        </div>

        <!-- Following Tab -->
        <div v-if="activeTab === 'following'" class="user-list">
          <div v-if="following.length === 0" class="empty-state">
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
              <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
              <circle cx="8.5" cy="7" r="4"/>
              <line x1="20" y1="8" x2="20" y2="14"/>
              <line x1="23" y1="11" x2="17" y2="11"/>
            </svg>
            <p>暂无关注</p>
          </div>
          <div v-else class="users">
            <div v-for="user in following" :key="user.id" class="user-card">
              <div class="user-info" @click="viewProfile(user.id)">
                <div class="avatar" :style="{ background: `linear-gradient(135deg, var(--primary), var(--secondary))` }">
                  <img v-if="user.avatar" :src="user.avatar" />
                  <span v-else>{{ (user.username || '?').charAt(0) }}</span>
                </div>
                <div class="user-details">
                  <h3>{{ user.username }}</h3>
                </div>
              </div>
              <button
                v-if="user.id !== currentUserId"
                class="follow-btn following"
                @click="toggleFollow(user.id, 'following')"
              >
                已关注
              </button>
            </div>
          </div>
        </div>
      </template>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api } from '../api/client'
import { useAuthStore } from '../stores/auth'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const currentUserId = computed(() => authStore.user?.id || 0)

const userId = computed(() => Number(route.query.userId) || 0)
const username = computed(() => (route.query.username as string) || '用户')
const activeTab = ref('followers')

const followers = ref<any[]>([])
const following = ref<any[]>([])
const isLoading = ref(true)

async function fetchFollowers() {
  try {
    const res = await api.get(`/follow/${userId.value}/followers`)
    if (res.data.code === 200) {
      followers.value = (res.data.data || []).map((u: any) => ({
        id: u.id,
        username: u.username,
        avatar: u.avatar,
        isFollowing: u.isFollowing || false,
      }))
    }
  } catch {}
}

async function fetchFollowing() {
  try {
    const res = await api.get(`/follow/${userId.value}/following`)
    if (res.data.code === 200) {
      following.value = (res.data.data || []).map((u: any) => ({
        id: u.id,
        username: u.username,
        avatar: u.avatar,
        isFollowing: true,
      }))
    }
  } catch {}
}

async function toggleFollow(targetId: number, list: string) {
  try {
    const res = await api.post(`/follow/${targetId}/toggle`)
    if (res.data.code === 200) {
      const followed = res.data.data
      if (list === 'followers') {
        const user = followers.value.find(u => u.id === targetId)
        if (user) user.isFollowing = followed
      } else {
        if (!followed) {
          following.value = following.value.filter(u => u.id !== targetId)
        }
      }
    }
  } catch (e: any) { alert(e.response?.data?.message || '操作失败') }
}

function viewProfile(id: number) {
  router.push({ path: `/user/${id}` })
}

onMounted(async () => {
  await Promise.all([fetchFollowers(), fetchFollowing()])
  isLoading.value = false
})
</script>

<style scoped>
.follow-list-page {
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
}

.page-header {
  margin-bottom: 20px;
}

.page-header h1 {
  font-size: 24px;
  font-weight: 700;
}

.tabs {
  display: flex;
  gap: 8px;
  margin-bottom: 20px;
  border-bottom: 1px solid var(--outline-variant);
}

.tab {
  padding: 12px 24px;
  border: none;
  background: none;
  font-size: 15px;
  font-weight: 500;
  color: var(--on-surface-variant);
  cursor: pointer;
  position: relative;
  transition: color 0.2s;
}

.tab.active {
  color: var(--primary);
}

.tab.active::after {
  content: '';
  position: absolute;
  bottom: -1px;
  left: 0;
  right: 0;
  height: 2px;
  background: var(--primary);
  border-radius: 2px;
}

.content {
  background: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: 20px;
  padding: 24px;
}

.loading {
  display: flex;
  justify-content: center;
  padding: 40px;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 3px solid var(--outline-variant);
  border-top-color: var(--primary);
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.empty-state {
  text-align: center;
  padding: 40px;
  color: var(--on-surface-variant);
}

.empty-state svg {
  margin-bottom: 12px;
  opacity: 0.3;
}

.users {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.user-card {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px;
  border-radius: 12px;
  transition: background 0.2s;
}

.user-card:hover {
  background: var(--surface-variant);
}

.user-info {
  display: flex;
  align-items: center;
  gap: 12px;
  cursor: pointer;
  flex: 1;
}

.avatar {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  font-weight: 600;
  color: #fff;
  overflow: hidden;
  flex-shrink: 0;
}

.avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.user-details h3 {
  font-size: 15px;
  font-weight: 600;
  margin: 0;
}

.follow-btn {
  padding: 8px 20px;
  border-radius: 20px;
  border: 1px solid var(--primary);
  background: none;
  color: var(--primary);
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.follow-btn:hover {
  background: var(--surface-tint);
}

.follow-btn.following {
  background: var(--surface-tint);
  border-color: var(--outline-variant);
  color: var(--on-surface-variant);
}
</style>
