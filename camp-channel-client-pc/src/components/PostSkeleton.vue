<template>
  <div class="post-skeleton" v-for="n in count" :key="n">
    <div class="skeleton-header">
      <div class="skeleton-avatar"></div>
      <div class="skeleton-meta">
        <div class="skeleton-line w-40"></div>
        <div class="skeleton-line short w-20"></div>
      </div>
    </div>
    <div class="skeleton-content">
      <div class="skeleton-line"></div>
      <div class="skeleton-line"></div>
      <div class="skeleton-line short"></div>
    </div>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  count?: number
}>()
</script>

<style scoped>
.post-skeleton {
  padding: 16px;
  background: var(--card-bg, #fff);
  border-radius: 12px;
  margin-bottom: 12px;
  border: 1px solid var(--border-color, rgba(0, 0, 0, 0.06));
}
.skeleton-header {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 16px;
}
.skeleton-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
}
.skeleton-meta {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.skeleton-line {
  height: 12px;
  border-radius: 6px;
  background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
}
.skeleton-line.short {
  width: 60%;
}
.skeleton-line.w-40 {
  width: 40%;
}
.skeleton-line.w-20 {
  width: 20%;
}
.skeleton-content {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
@keyframes shimmer {
  0% { background-position: -200% 0; }
  100% { background-position: 200% 0; }
}
@media (prefers-color-scheme: dark) {
  .post-skeleton {
    background: var(--card-bg, #1a2744);
    border-color: var(--border-color, rgba(255, 255, 255, 0.08));
  }
  .skeleton-avatar,
  .skeleton-line {
    background: linear-gradient(90deg, #2a3a5a 25%, #3a4a6a 50%, #2a3a5a 75%);
    background-size: 200% 100%;
  }
}
</style>
