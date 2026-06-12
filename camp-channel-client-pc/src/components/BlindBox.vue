<template>
  <div class="blind-box-container">
    <div
      v-for="item in mockItems"
      :key="item.mockId"
      class="blind-box-card"
      :class="{ revealed: revealedIds.has(item.mockId) }"
      @click="revealItem(item)"
    >
      <!-- Mystery (front) --><div class="blind-box-front">
        <div class="mystery-icon">🎁</div>
        <p class="mystery-title">{{ item.itemName }}</p><p class="mystery-hint">点击翻转揭晓</p>
      </div>
      <!-- Revealed (back) -->
      <div class="blind-box-back" v-if="revealedIds.has(item.mockId)">
        <div class="reveal-icon">{{ probabilityIcon(item.probability) }}</div>
        <h3 class="reveal-title">{{ item.itemName }} — {{ item.probability }}</h3><p class="reveal-content">已获得稀有道具，快来抽更多吧！</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
/** BlindBox types */
type Probability = 'SSR' | 'SR' | 'R' | 'N'

interface BlindBoxItem {
  mockId: string
  itemName: string
  probability: Probability
}

const revealedIds = ref<Set<string>>(new Set())

function probabilityIcon(p: Probability): string {
  const map: Record<string, string> = { SSR: '💎', SR: '✨', R: '⭐', N: '🎯' }
  return map[p] || '🎁'
}

function revealItem(item: BlindBoxItem) {
  revealedIds.value.add(item.mockId)
}

/** Static Mock data — no backend call needed for page load */
const mockItems: BlindBoxItem[] = [
  { mockId: 'b1', itemName: '🎁 神秘盲盒', probability: 'SSR' },
]
</script>

<style scoped>
.blind-box-container {
  display: flex; flex-direction: column; gap: 16px; width: 100%;
}
.blind-box-card {
  perspective: 1000px; cursor: pointer; position: relative;
  width: 100%; max-width: 400px; height: 200px; margin: 0 auto;
}
.blind-box-front,
.blind-box-back {
  position: absolute; inset: 0; backface-visibility: hidden;
  border-radius: 16px; display: flex; flex-direction: column;
  align-items: center; justify-content: center; padding: 20px;
}
.blind-box-front {
  background: linear-gradient(135deg, var(--primary, #7c9fdb), var(--accent, #6c63ff));
  color: #fff; transition: transform 0.8s cubic-bezier(0.4, 0, 0.2, 1);
  transform-style: preserve-3d;
}
.blind-box-card.revealed .blind-box-front { transform: rotateY(180deg); }
.blind-box-back {
  background: var(--card-bg, #ffffff); border: 1px solid var(--outline-variant, #e0e0e0);
  transform: rotateY(180deg); color: var(--text-primary, #222);
}
.mystery-icon { font-size: 40px; margin-bottom: 12px; }
.mystery-title { font-size: 16px; font-weight: bold; margin: 0 0 6px; }
.mystery-hint { font-size: 12px; opacity: 0.7; margin: 0; }
.reveal-icon { font-size: 28px; margin-bottom: 8px; }
.reveal-title { font-size: 16px; font-weight: bold; margin: 0 0 8px; }
.reveal-content { font-size: 13px; color: var(--on-surface-variant, #555); text-align: center; margin: 0; line-height: 1.6; }
</style>
