<template>
  <div class="drafts-page">
    <div class="drafts-header">
      <h1 class="page-title">我的草稿</h1>
      <button class="btn-back" @click="$router.back()">返回</button>
    </div>

    <div v-if="loading" class="loading-state">
      <div class="spinner"></div>
      <p>加载中...</p>
    </div>

    <div v-else-if="drafts.length === 0" class="empty-state">
      <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" opacity="0.3">
        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
        <polyline points="14 2 14 8 20 8"/>
      </svg>
      <p>暂无草稿</p>
    </div>

    <div v-else class="draft-list">
      <div v-for="draft in drafts" :key="draft.id" class="draft-card">
        <div class="draft-meta">
          <span class="channel-tag">{{ draft.channelName || '未选择频道' }}</span>
          <span v-if="draft.topic" class="topic-tag">{{ draft.topic }}</span>
          <span class="time-tag">{{ formatTime(draft.updateTime) }}</span>
        </div>
        <div class="draft-content">{{ draft.content || '(空内容)' }}</div>
        <div class="draft-actions">
          <button class="btn-delete" @click="confirmDelete(draft.id)">删除</button>
          <button class="btn-publish" @click="publishDraft(draft.id)" :disabled="publishingId === draft.id">
            {{ publishingId === draft.id ? '发布中...' : '发布' }}
          </button>
        </div>
      </div>
    </div>

    <teleport to="body">
      <div v-if="showDeleteConfirm" class="confirm-overlay" @click.self="showDeleteConfirm = false">
        <div class="confirm-card" @click.stop>
          <h3>删除草稿</h3>
          <p>确定要删除这个草稿吗？此操作不可恢复。</p>
          <div class="confirm-actions">
            <button class="btn-cancel" @click="showDeleteConfirm = false">取消</button>
            <button class="btn-confirm-delete" @click="deleteDraft">删除</button>
          </div>
        </div>
      </div>
    </teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '../api/client'

const router = useRouter()
const drafts = ref<any[]>([])
const loading = ref(true)
const publishingId = ref<number | null>(null)
const showDeleteConfirm = ref(false)
const deleteDraftId = ref<number | null>(null)

async function fetchDrafts() {
  loading.value = true
  try {
    const res = await api.get('/drafts')
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      drafts.value = res.data.data
    }
  } catch (e) { console.error(e) }
  loading.value = false
}

function formatTime(t: string): string {
  if (!t) return ''
  return t.substring(0, 16).replace('T', ' ')
}

function confirmDelete(id: number) {
  deleteDraftId.value = id
  showDeleteConfirm.value = true
}

async function deleteDraft() {
  if (!deleteDraftId.value) return
  try {
    await api.delete(`/drafts/${deleteDraftId.value}`)
    drafts.value = drafts.value.filter(d => d.id !== deleteDraftId.value)
  } catch (e) { alert('删除失败') }
  showDeleteConfirm.value = false
  deleteDraftId.value = null
}

async function publishDraft(id: number) {
  publishingId.value = id
  try {
    const res = await api.post(`/drafts/${id}/publish`)
    if (res.data.code === 200) {
      alert('帖子已发布')
      router.push('/home')
    } else {
      alert(res.data.message || '发布失败')
    }
  } catch (e: any) {
    alert(e.response?.data?.message || '发布失败')
  }
  publishingId.value = null
}

onMounted(() => { fetchDrafts() })
</script>

<style scoped>
.drafts-page { max-width: 640px; margin: 0 auto; padding: 32px 0; }
.drafts-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 24px; }
.page-title { font-size: 24px; font-weight: 700; }
.btn-back { padding: 8px 20px; border: 1px solid var(--outline-variant); border-radius: 10px; background: var(--surface); color: var(--on-surface-variant); font-size: 14px; cursor: pointer; }
.loading-state, .empty-state { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 80px 0; color: var(--on-surface-variant); }
.spinner { width: 32px; height: 32px; border: 3px solid var(--outline-variant); border-top-color: var(--primary); border-radius: 50%; animation: spin 0.8s linear infinite; margin-bottom: 12px; }
@keyframes spin { to { transform: rotate(360deg); } }
.draft-list { display: flex; flex-direction: column; gap: 12px; }
.draft-card { padding: 20px; background: var(--surface); border: 1px solid var(--outline-variant); border-radius: 16px; }
.draft-meta { display: flex; align-items: center; gap: 8px; margin-bottom: 12px; flex-wrap: wrap; }
.channel-tag { font-size: 12px; font-weight: 600; color: var(--primary); }
.topic-tag { font-size: 11px; padding: 2px 8px; background: rgba(var(--primary-rgb, 103,80,164), 0.1); border-radius: 8px; color: var(--primary); }
.time-tag { font-size: 11px; color: var(--on-surface-variant); margin-left: auto; }
.draft-content { font-size: 14px; line-height: 1.6; color: var(--on-surface); display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; margin-bottom: 16px; }
.draft-actions { display: flex; justify-content: flex-end; gap: 8px; }
.btn-delete { padding: 8px 16px; border: 1px solid rgba(255,107,107,0.3); border-radius: 10px; background: transparent; color: #ff6b6b; font-size: 13px; cursor: pointer; }
.btn-delete:hover { background: rgba(255,107,107,0.05); }
.btn-publish { padding: 8px 20px; border: none; border-radius: 10px; background: linear-gradient(135deg, var(--primary), var(--secondary)); color: #fff; font-size: 13px; font-weight: 600; cursor: pointer; }
.btn-publish:disabled { opacity: 0.5; cursor: not-allowed; }
.confirm-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.6); display: flex; align-items: center; justify-content: center; z-index: 3000; }
.confirm-card { background: var(--surface); border-radius: 16px; padding: 24px; max-width: 360px; width: 90%; }
.confirm-card h3 { margin-bottom: 8px; }
.confirm-card p { font-size: 14px; color: var(--on-surface-variant); margin-bottom: 20px; }
.confirm-actions { display: flex; justify-content: flex-end; gap: 8px; }
.btn-cancel { padding: 8px 20px; border: 1px solid var(--outline-variant); border-radius: 10px; background: var(--surface); color: var(--on-surface-variant); cursor: pointer; }
.btn-confirm-delete { padding: 8px 20px; border: none; border-radius: 10px; background: #ff6b6b; color: #fff; font-weight: 600; cursor: pointer; }
</style>
