<template>
  <span class="search-highlight-wrapper">
    <template v-for="(part, index) in highlightedParts" :key="index">
      <mark v-if="part.highlight" class="search-highlight">{{ part.text }}</mark>
      <span v-else>{{ part.text }}</span>
    </template>
  </span>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  text: string
  keyword: string
}>()

const highlightedParts = computed(() => {
  if (!props.keyword || !props.text) {
    return [{ text: props.text || '', highlight: false }]
  }
  try {
    const escaped = props.keyword.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
    const regex = new RegExp(`(${escaped})`, 'gi')
    const parts = props.text.split(regex)
    return parts
      .filter(part => part.length > 0)
      .map(part => ({
        text: part,
        highlight: part.toLowerCase() === props.keyword.toLowerCase(),
      }))
  } catch {
    return [{ text: props.text, highlight: false }]
  }
})
</script>

<style scoped>
.search-highlight-wrapper {
  display: inline;
}
.search-highlight {
  background-color: rgba(255, 213, 79, 0.5);
  color: inherit;
  padding: 0 2px;
  border-radius: 2px;
  font-weight: 600;
}
</style>
