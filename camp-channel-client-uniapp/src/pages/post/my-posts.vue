<template>
  <view class="page">
    <scroll-view scroll-y class="list-scroll" @scrolltolower="loadMore">
      <PostCard
        v-for="post in posts"
        :key="post.id"
        :post="post"
        @click="goDetail"
      />
      <view v-if="loading" class="loading">加载中...</view>
      <view v-if="!loading && posts.length === 0" class="empty">暂无帖子</view>
    </scroll-view>
  </view>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import PostCard from '../../components/PostCard.vue'
import request, { processImageUrl } from '../../utils/request'

interface PostItem {
  id: number
  author?: string
  avatar?: string
  userId?: number
  time?: string
  channelName?: string
  userChannelRole?: string
  title: string
  content: string
  images?: string[]
  likeCount?: number
  commentCount?: number
  isLiked?: boolean
}

const posts = ref<PostItem[]>([])
const page = ref(1)
const loading = ref(false)
const hasMore = ref(true)

onMounted(() => {
  loadPosts()
})

async function loadPosts() {
  if (loading.value || !hasMore.value) return
  loading.value = true
  try {
    const res = await request<any>(`/posts/my?page=${page.value}&size=10`)
    if (res?.code === 200) {
      const list = (res.data || []).map((p: any) => ({
        id: p.id,
        author: p.username || '未知',
        avatar: processImageUrl(p.avatar || ''),
        userId: p.userId,
        time: p.createTime || '',
        channelName: p.channelName || '',
        userChannelRole: p.userChannelRole || '',
        title: p.content ? p.content.substring(0, 50) : '',
        content: p.content || '',
        images: safeParseImages(p.images),
        likeCount: p.likeCount || 0,
        commentCount: p.commentCount || 0,
        isLiked: false,
      }))
      if (page.value === 1) {
        posts.value = list
      } else {
        posts.value = [...posts.value, ...list]
      }
      if (list.length < 10) hasMore.value = false
    }
  } catch (_) {
    uni.showToast({ title: '加载失败', icon: 'none' })
  } finally {
    loading.value = false
  }
}

function loadMore() {
  if (hasMore.value) {
    page.value++
    loadPosts()
  }
}

function safeParseImages(images: any): string[] {
  if (!images) return []
  if (Array.isArray(images)) return images.map((img: string) => processImageUrl(img))
  if (typeof images === 'string') {
    try {
      const parsed = JSON.parse(images)
      if (Array.isArray(parsed)) return parsed.map((img: string) => processImageUrl(img))
    } catch (_) {}
    return [processImageUrl(images)]
  }
  return []
}

function goDetail(postId: number) {
  uni.navigateTo({ url: `/pages/post/detail?id=${postId}` })
}
</script>

<style>
.page {
  min-height: 100vh;
  background: #0F1923;
}
.list-scroll {
  height: 100vh;
  padding: 24rpx;
}
.loading {
  text-align: center;
  padding: 30rpx;
  color: rgba(232, 239, 247, 0.5);
  font-size: 26rpx;
}
.empty {
  text-align: center;
  padding: 100rpx 0;
  color: rgba(232, 239, 247, 0.4);
  font-size: 28rpx;
}
</style>
