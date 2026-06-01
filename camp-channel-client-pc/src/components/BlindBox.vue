<template>
  <div class="blind-box" @click="flip">
    <div class="blind-box-inner" :class="{ flipped: isFlipped }">
      <!-- Front (mystery) -->
      <div class="blind-box-front">
        <div class="mystery-icon">🎁</div>
        <p class="mystery-title">盲盒公告</p>
        <p class="mystery-hint">点击翻转揭晓</p>
      </div>
      <!-- Back (content) -->
      <div class="blind-box-back">
        <div class="reveal-icon">🎉</div>
        <h3 class="reveal-title">{{ title }}</h3>
        <p class="reveal-content">{{ content }}</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'

defineProps<{
  title: string
  content: string
}>()

const emit = defineEmits<{
  (e: 'revealed'): void
}>()

const isFlipped = ref(false)

function flip() {
  if (isFlipped.value) return
  isFlipped.value = true
  setTimeout(() => emit('revealed'), 800)
}
</script>

<style scoped>
.blind-box {
  perspective: 1000px;
  cursor: pointer;
  width: 100%;
  max-width: 400px;
  height: 200px;
}

.blind-box-inner {
  position: relative;
  width: 100%;
  height: 100%;
  transition: transform 0.8s cubic-bezier(0.4, 0, 0.2, 1);
  transform-style: preserve-3d;
}

.blind-box-inner.flipped {
  transform: rotateY(180deg);
}

.blind-box-front,
.blind-box-back {
  position: absolute;
  inset: 0;
  backface-visibility: hidden;
  border-radius: 16px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.blind-box-front {
  background: linear-gradient(135deg, var(--primary), var(--accent, #6c63ff));
  color: #fff;
}

.mystery-icon {
  font-size: 40px;
  margin-bottom: 12px;
}
.mystery-title {
  font-size: 16px;
  font-weight: bold;
  margin: 0 0 6px;
}
.mystery-hint {
  font-size: 12px;
  opacity: 0.7;
  margin: 0;
}

.blind-box-back {
  background: var(--card-bg);
  border: 1px solid var(--outline-variant);
  transform: rotateY(180deg);
  color: var(--text-primary);
}

.reveal-icon {
  font-size: 28px;
  margin-bottom: 8px;
}
.reveal-title {
  font-size: 16px;
  font-weight: bold;
  margin: 0 0 8px;
}
.reveal-content {
  font-size: 13px;
  color: var(--on-surface-variant);
  text-align: center;
  margin: 0;
  line-height: 1.6;
}
</style>
