<template>
  <div class="channel-search-page">
    <div class="search-header">
      <div class="page-header">
        <h1 class="page-title">发现频道</h1>
        <button class="create-channel-btn" @click="showCreateForm = !showCreateForm">+ 创建频道</button>
      </div>
      <div class="search-box">
        <input v-model="keyword" placeholder="搜索频道编号或名称..." @input="search" />
        <button class="search-btn" @click="search">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
        </button>
      </div>
    </div>

    <div v-if="showCreateForm" class="create-channel-form">
      <h3>创建新频道</h3>
      <input v-model="newName" placeholder="频道名称" />
      <input v-model="newDesc" placeholder="频道简介（选填）" />
      <button @click="createChannel">创建</button>
    </div>

    <div v-if="loading" class="loading-state">搜索中...</div>
    <div v-else-if="channels.length === 0" class="empty-state">暂无结果，试试搜索其他关键词</div>
    <div v-else class="channel-list">
      <div v-for="ch in channels" :key="ch.id" class="channel-card">
        <div class="channel-avatar">{{ (ch.name || '?').charAt(0) }}</div>
        <div class="channel-info">
          <div class="channel-name">{{ ch.name }}</div>
          <div class="channel-code">编号: {{ ch.channelCode || '--' }}</div>
          <p class="channel-desc">{{ ch.description || '暂无简介' }}</p>
        </div>
        <button
          class="join-btn"
          :class="{ pending: ch.joinStatus === 'pending', joined: ch.joinStatus === 'joined' }"
          :disabled="ch.joinStatus === 'pending' || ch.joinStatus === 'joined'"
          @click="applyJoin(ch)"
        >
          {{ ch.joinStatus === 'joined' ? '已加入' : ch.joinStatus === 'pending' ? '待审核' : '申请加入' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { api } from '../api/client'

const keyword = ref('')
const channels = ref<any[]>([])
const loading = ref(false)
const showCreateForm = ref(false)
const newName = ref('')
const newDesc = ref('')

async function search() {
  loading.value = true
  try {
    const res = await api.get('/channels/search', { params: { keyword: keyword.value } })
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      channels.value = res.data.data.map((ch: any) => ({
        ...ch,
        joinStatus: 'none',
      }))
      const myRes = await api.get('/channels/my')
      if (myRes.data.code === 200 && Array.isArray(myRes.data.data)) {
        const myIds = new Set(myRes.data.data.map((m: any) => m.id))
        channels.value.forEach(ch => {
          if (myIds.has(ch.id)) ch.joinStatus = 'joined'
        })
        // 过滤掉公共频道（公共频道不需要申请加入）
        channels.value = channels.value.filter(ch => ch.channelCode !== 'CH-PUBLIC-001')
      }
    }
  } catch (e) {
    channels.value = []
  } finally {
    loading.value = false
  }
}

async function applyJoin(ch: any) {
  try {
    const res = await api.post(`/channels/${ch.id}/join`)
    if (res.data.code === 200) {
      ch.joinStatus = 'pending'
    }
  } catch (e: any) {
    alert(e.response?.data?.message || '申请失败')
  }
}

async function createChannel() {
  if (!newName.value.trim()) { alert('请输入频道名称'); return }
  try {
    const res = await api.post('/channels', {
      name: newName.value,
      description: newDesc.value,
    })
    if (res.data.code === 200) {
      alert('频道创建成功！频道编号：' + (res.data.data?.channelCode || ''))
      newName.value = ''
      newDesc.value = ''
      showCreateForm.value = false
      search()
    } else {
      alert(res.data.message || '创建失败')
    }
  } catch (e: any) {
    alert(e.response?.data?.message || '创建失败')
  }
}

onMounted(() => { search() })
</script>

<style scoped>
.channel-search-page { max-width: 720px; margin: 0 auto; }
.search-header { margin-bottom: 24px; }
.page-title { font-size: 28px; font-weight: 700; margin-bottom: 16px; }
.page-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
.create-channel-btn { padding: 10px 20px; border: none; border-radius: 10px; background: linear-gradient(135deg, var(--primary), var(--accent)); color: #fff; font-size: 13px; font-weight: 600; cursor: pointer; white-space: nowrap; }
.create-channel-form { padding: 16px; background: var(--card); border: 1px solid var(--border); border-radius: 16px; margin-bottom: 16px; display: flex; flex-direction: column; gap: 8px; }
.create-channel-form h3 { font-size: 14px; margin-bottom: 4px; }
.create-channel-form input { padding: 10px 14px; border: 1px solid var(--border); border-radius: 10px; background: rgba(255,255,255,0.03); color: var(--text); font-size: 13px; outline: none; }
.create-channel-form input:focus { border-color: var(--primary); }
.create-channel-form button { padding: 10px; border: none; border-radius: 10px; background: linear-gradient(135deg, var(--primary), var(--accent)); color: #fff; font-weight: 600; cursor: pointer; }
.search-box { display: flex; gap: 8px; }
.search-box input {
  flex: 1; padding: 14px 18px; border: 1px solid var(--border); border-radius: 14px;
  background: rgba(255,255,255,0.03); color: var(--text); font-size: 15px; outline: none;
}
.search-box input:focus { border-color: var(--primary); }
.search-btn {
  width: 48px; height: 48px; border-radius: 14px; border: 1px solid var(--border);
  background: var(--card); color: var(--text); cursor: pointer; display: flex;
  align-items: center; justify-content: center; transition: all 0.2s;
}
.search-btn:hover { border-color: var(--primary); color: var(--primary); }
.loading-state, .empty-state { text-align: center; padding: 60px 20px; color: var(--text-secondary); font-size: 15px; }
.channel-list { display: flex; flex-direction: column; gap: 12px; }
.channel-card {
  display: flex; align-items: center; gap: 16px; padding: 20px;
  background: var(--card); border: 1px solid var(--border); border-radius: 18px;
  transition: all 0.2s;
}
.channel-card:hover { border-color: var(--primary); }
.channel-avatar {
  width: 52px; height: 52px; border-radius: 14px;
  background: linear-gradient(135deg, var(--primary), var(--accent));
  display: flex; align-items: center; justify-content: center;
  font-size: 22px; font-weight: 700; color: #fff; flex-shrink: 0;
}
.channel-info { flex: 1; min-width: 0; }
.channel-name { font-size: 16px; font-weight: 600; margin-bottom: 2px; }
.channel-code { font-size: 12px; color: var(--text-secondary); margin-bottom: 4px; }
.channel-desc { font-size: 13px; color: var(--text-secondary); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.join-btn {
  padding: 10px 20px; border-radius: 10px; border: 1px solid var(--primary);
  background: rgba(124,159,203,0.1); color: var(--primary); font-size: 13px;
  font-weight: 600; cursor: pointer; transition: all 0.2s; white-space: nowrap; flex-shrink: 0;
}
.join-btn:hover { background: rgba(124,159,203,0.2); }
.join-btn.joined { border-color: #4ade80; background: rgba(74,222,128,0.1); color: #4ade80; cursor: default; }
.join-btn.pending { border-color: #f0ad4e; background: rgba(240,173,78,0.1); color: #f0ad4e; cursor: default; }
</style>
