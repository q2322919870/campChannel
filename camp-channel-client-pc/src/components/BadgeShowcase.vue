<template>
  <div class="badge-showcase glass-card" v-if="badges.length > 0 || !loading">
    <div class="badge-header">
      <span class="badge-icon-header">🏆</span>
      <span class="badge-title">{{ badges.length > 0 ? `已获徽章 (${badges.length})` : '徽章墙' }}</span>
    </div>
    <div v-if="loading" class="badge-loading">
      <div class="spinner-sm"></div>
    </div>
    <div v-else-if="badges.length === 0" class="badge-empty">
      <p>发帖和获赞可解锁成就徽章</p>
    </div>
    <div v-else class="badge-grid">
      <div
        v-for="(badge, index) in badges"
        :key="badge.id"
        class="badge-item"
        :style="{ animationDelay: `${index * 0.1}s` }"
      >
        <div class="badge-circle" :style="getBadgeStyle(index)">
          <span class="badge-emoji">{{ badge.badgeIcon || '🏆' }}</span>
        </div>
        <span class="badge-name">{{ badge.badgeName || '未知' }}</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { api } from '../api/client'

interface UserBadge {
  id: number
  badgeId: number
  badgeName: string
  badgeIcon: string
  badgeDescription: string
  earnedAt: string
}

const badges = ref<UserBadge[]>([])
const loading = ref(true)

onMounted(async () => {
  try {
    const res = await api.get('/badges/my')
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      badges.value = res.data.data
    }
  } catch (e) {
    console.error('Failed to fetch badges:', e)
  } finally {
    loading.value = false
  }
})

function getBadgeStyle(index: number) {
  const colors = [
    { bg: 'rgba(108, 99, 255, 0.15)', border: 'rgba(108, 99, 255, 0.4)', shadow: 'rgba(108, 99, 255, 0.3)' },
    { bg: 'rgba(255, 107, 107, 0.15)', border: 'rgba(255, 107, 107, 0.4)', shadow: 'rgba(255, 107, 107, 0.3)' },
    { bg: 'rgba(78, 205, 196, 0.15)', border: 'rgba(78, 205, 196, 0.4)', shadow: 'rgba(78, 205, 196, 0.3)' },
    { bg: 'rgba(255, 195, 18, 0.15)', border: 'rgba(255, 195, 18, 0.4)', shadow: 'rgba(255, 195, 18, 0.3)' },
  ]
  const c = colors[index % colors.length]
  return {
    background: c.bg,
    borderColor: c.border,
    boxShadow: `0 0 16px ${c.shadow}`,
  }
}
</script>

<style scoped>
.badge-showcase {
  padding: 18px 20px;
}

.badge-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 14px;
}
.badge-icon-header {
  font-size: 18px;
}
.badge-title {
  font-size: 15px;
  font-weight: 600;
  color: var(--text-primary);
}

.badge-loading, .badge-empty {
  text-align: center;
  padding: 16px 0;
  color: var(--text-secondary);
  font-size: 13px;
}

.spinner-sm {
  width: 20px;
  height: 20px;
  border: 2px solid var(--border);
  border-top-color: var(--primary);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
  margin: 0 auto;
}
@keyframes spin { to { transform: rotate(360deg); } }

.badge-grid {
  display: flex;
  gap: 16px;
  flex-wrap: wrap;
}

.badge-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  animation: badgeIn 0.5s ease-out both;
}

@keyframes badgeIn {
  from {
    opacity: 0;
    transform: scale(0.5);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

.badge-circle {
  width: 56px;
  height: 56px;
  border-radius: 50%;
  border: 2px solid;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: transform 0.3s, box-shadow 0.3s;
}
.badge-circle:hover {
  transform: scale(1.15);
}

.badge-emoji {
  font-size: 24px;
}

.badge-name {
  font-size: 11px;
  color: var(--text-secondary);
  max-width: 60px;
  text-align: center;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>
