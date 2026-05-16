<script setup>
import Icon from 'next/icon/Icon.vue';
</script>

<template>
  <Icon v-once icon="i-lucide-sparkles" class="wl-ai-loader" />
</template>

<style scoped>
.wl-ai-loader {
  transform-origin: center center;
  animation: wl-ai-pulse 1.2s ease-in-out infinite;
  will-change: transform, opacity;
}

@keyframes wl-ai-pulse {
  0%,
  100% {
    transform: scale(1);
    opacity: 0.65;
  }
  50% {
    transform: scale(1.12);
    opacity: 1;
  }
}
</style>
