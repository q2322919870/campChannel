import { createRouter, createWebHashHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'

const routes: RouteRecordRaw[] = [
  { path: '/', redirect: '/home' },
  { path: '/login', name: 'Login', component: () => import('../pages/LoginPage.vue') },
  { path: '/register', name: 'Register', component: () => import('../pages/RegisterPage.vue') },
  { path: '/home', name: 'Home', component: () => import('../pages/HomePage.vue'), meta: { requiresAuth: true } },
  { path: '/channel/:id', name: 'Channel', component: () => import('../pages/ChannelPage.vue'), meta: { requiresAuth: true } },
  { path: '/channels/search', name: 'ChannelSearch', component: () => import('../pages/ChannelSearchPage.vue'), meta: { requiresAuth: true } },
  { path: '/post/create', name: 'CreatePost', component: () => import('../pages/CreatePostPage.vue'), meta: { requiresAuth: true } },
  { path: '/post/:id', name: 'PostDetail', component: () => import('../pages/PostDetailPage.vue'), meta: { requiresAuth: true } },
  { path: '/chat', name: 'Chat', component: () => import('../pages/ChatPage.vue'), meta: { requiresAuth: true } },
  { path: '/friends', name: 'Friends', component: () => import('../pages/FriendPage.vue'), meta: { requiresAuth: true } },
  { path: '/notifications', name: 'Notifications', component: () => import('../pages/NotificationPage.vue'), meta: { requiresAuth: true } },
  { path: '/profile', name: 'Profile', component: () => import('../pages/ProfilePage.vue'), meta: { requiresAuth: true } },
  { path: '/settings', name: 'Settings', component: () => import('../pages/SettingsPage.vue'), meta: { requiresAuth: true } },
  { path: '/admin', name: 'Admin', component: () => import('../pages/AdminPage.vue'), meta: { requiresAuth: true, requiresAdmin: true } },
  { path: '/devices', name: 'Devices', redirect: '/device-management' },
  { path: '/device-management', name: 'DeviceManagement', component: () => import('../pages/DeviceManagementPage.vue'), meta: { requiresAuth: true } },
  { path: '/liked-posts', name: 'LikedPosts', component: () => import('../pages/LikedPostsPage.vue'), meta: { requiresAuth: true } },
  { path: '/channels/applications', name: 'ChannelApplications', component: () => import('../pages/ChannelApplicationsPage.vue'), meta: { requiresAuth: true } },
  { path: '/tree-hole', name: 'TreeHole', component: () => import('../pages/TreeHolePage.vue'), meta: { requiresAuth: true } },
  { path: '/announcements', name: 'Announcements', component: () => import('../pages/AnnouncementPage.vue'), meta: { requiresAuth: true } },
  { path: '/favourites', name: 'Favourites', component: () => import('../pages/FavouritesPage.vue'), meta: { requiresAuth: true } },
  { path: '/channel/:id/group-chat', name: 'GroupChat', component: () => import('../pages/GroupChatPage.vue'), meta: { requiresAuth: true } },
  { path: '/search', name: 'Search', component: () => import('../pages/SearchPage.vue'), meta: { requiresAuth: true } },
  { path: '/hot-posts', name: 'HotPosts', component: () => import('../pages/HotPostsPage.vue'), meta: { requiresAuth: true } },
  { path: '/drafts', name: 'Drafts', component: () => import('../pages/DraftsPage.vue'), meta: { requiresAuth: true } },
  { path: '/user/:id', name: 'UserProfile', component: () => import('../pages/UserProfilePage.vue'), meta: { requiresAuth: true } },
  { path: '/follow-list', name: 'FollowList', component: () => import('../pages/FollowListPage.vue'), meta: { requiresAuth: true } },
  { path: '/following-feed', name: 'FollowingFeed', component: () => import('../pages/FollowingFeedPage.vue'), meta: { requiresAuth: true } },
]

const router = createRouter({
  history: createWebHashHistory(),
  routes,
})

// Expose router globally for transition managers
;(window as any).__VUE_ROUTER__ = router

// Authentication guard (hybrid transitions handled by HybridTransitionManager)
router.beforeEach((to, _from, next) => {
  const token = localStorage.getItem('token')
  if (to.meta.requiresAuth && !token) {
    next('/login')
  } else if (to.path === '/login' && token) {
    next('/home')
  } else {
    next()
  }
})

export default router
