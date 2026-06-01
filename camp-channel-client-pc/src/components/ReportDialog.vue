<template>
  <div class="report-overlay" v-if="visible" @click.self="$emit('close')">
    <div class="report-dialog">
      <h3>举报内容</h3>
      <p class="report-desc">请选择举报原因，我们将尽快处理</p>
      <textarea v-model="reason" placeholder="请描述举报原因..." rows="4"></textarea>
      <div class="report-actions">
        <button class="btn cancel" @click="$emit('close')">取消</button>
        <button class="btn submit" @click="handleSubmit" :disabled="!reason.trim()">提交举报</button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { api } from '../api/client'

const props = defineProps<{ visible: boolean; targetType: string; targetId: number }>()
const emit = defineEmits<{ close: []; submitted: [] }>()

const reason = ref('')

async function handleSubmit() {
  if (!reason.value.trim()) return
  try {
    await api.post('/reports', { targetType: props.targetType, targetId: props.targetId, reason: reason.value })
    reason.value = ''
    emit('submitted')
    emit('close')
  } catch (e: any) {
    alert('举报失败：' + (e.response?.data?.message || e.message))
  }
}
</script>

<style scoped>
.report-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; z-index: 2000; }
.report-dialog { width: 400px; padding: 24px; background: var(--surface); backdrop-filter: blur(24px); border: 1px solid var(--outline-variant); border-radius: 20px; }
.report-dialog h3 { font-size: 18px; font-weight: 600; margin-bottom: 4px; }
.report-desc { font-size: 13px; color: var(--on-surface-variant); margin-bottom: 16px; }
textarea { width: 100%; padding: 12px; border: 1px solid var(--outline-variant); border-radius: 12px; background: rgba(255,255,255,0.03); color: var(--on-surface); font-size: 14px; resize: none; outline: none; margin-bottom: 16px; }
textarea:focus { border-color: var(--primary); }
.report-actions { display: flex; gap: 8px; justify-content: flex-end; }
.btn { padding: 10px 20px; border-radius: 10px; border: none; font-size: 14px; font-weight: 600; cursor: pointer; transition: all 0.2s; }
.btn.cancel { background: var(--surface); border: 1px solid var(--outline-variant); color: var(--on-surface-variant); }
.btn.submit { background: linear-gradient(135deg, var(--primary), var(--secondary)); color: #fff; }
.btn.submit:disabled { opacity: 0.5; cursor: not-allowed; }
</style>
