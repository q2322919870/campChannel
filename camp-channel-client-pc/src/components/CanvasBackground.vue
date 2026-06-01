<template>
  <div class="gradient-bg">
    <div class="gradient-circle circle-1"></div>
    <div class="gradient-circle circle-2"></div>
    <div class="gradient-circle circle-3"></div>
  </div>
</template>

<script setup lang="ts">
</script>

<style scoped>
.gradient-bg {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  z-index: 0;
  pointer-events: none;
  overflow: hidden;
}

.gradient-circle {
  position: absolute;
  border-radius: 50%;
  filter: blur(80px);
  opacity: 0.15;
  animation: float 20s ease-in-out infinite;
}

.circle-1 {
  width: 500px;
  height: 500px;
  top: -100px;
  left: -100px;
  background: var(--primary, #7C9FCB);
  animation-delay: 0s;
}

.circle-2 {
  width: 400px;
  height: 400px;
  bottom: -50px;
  right: -50px;
  background: var(--accent, #F2B5D4);
  animation-delay: -7s;
}

.circle-3 {
  width: 350px;
  height: 350px;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  background: var(--primary, #7C9FCB);
  opacity: 0.08;
  animation-delay: -14s;
}

@keyframes float {
  0%, 100% { transform: translate(0, 0) scale(1); }
  25% { transform: translate(50px, -30px) scale(1.1); }
  50% { transform: translate(-20px, 40px) scale(0.95); }
  75% { transform: translate(30px, 20px) scale(1.05); }
}
</style>
