import { createRouter, createWebHashHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'
import HomePage from '../pages/HomePage.vue'
import LoginPage from '../pages/LoginPage.vue'
import RegisterPage from '../pages/RegisterPage.vue'
import ChannelPage from '../pages/ChannelPage.vue'
import ChannelSearchPage from '../pages/ChannelSearchPage.vue'
import CreatePostPage from '../pages/CreatePostPage.vue'
import PostDetailPage from '../pages/PostDetailPage.vue'
import ChatPage from '../pages/ChatPage.vue'
import FriendPage from '../pages/FriendPage.vue'
import NotificationPage from '../pages/NotificationPage.vue'
import ProfilePage from '../pages/ProfilePage.vue'
import SettingsPage from '../pages/SettingsPage.vue'
import AdminPage from '../pages/AdminPage.vue'
import DeviceManagementPage from '../pages/DeviceManagementPage.vue'
import LikedPostsPage from '../pages/LikedPostsPage.vue'
import ChannelApplicationsPage from '../pages/ChannelApplicationsPage.vue'
import TreeHolePage from '../pages/TreeHolePage.vue'
import AnnouncementPage from '../pages/AnnouncementPage.vue'
import FavouritesPage from '../pages/FavouritesPage.vue'
import GroupChatPage from '../pages/GroupChatPage.vue'
import SearchPage from '../pages/SearchPage.vue'
import HotPostsPage from '../pages/HotPostsPage.vue'
import DraftsPage from '../pages/DraftsPage.vue'
import UserProfilePage from '../pages/UserProfilePage.vue'
import FollowListPage from '../pages/FollowListPage.vue'
import FollowingFeedPage from '../pages/FollowingFeedPage.vue'

const routes: RouteRecordRaw[] = [
  { path: '/', redirect: '/home' },
  { path: '/login', name: 'Login', component: LoginPage },
  { path: '/register', name: 'Register', component: RegisterPage },
  { path: '/home', name: 'Home', component: HomePage, meta: { requiresAuth: true } },
  { path: '/channel/:id', name: 'Channel', component: ChannelPage, meta: { requiresAuth: true } },
  { path: '/channels/search', name: 'ChannelSearch', component: ChannelSearchPage, meta: { requiresAuth: true } },
  { path: '/post/create', name: 'CreatePost', component: CreatePostPage, meta: { requiresAuth: true } },
  { path: '/post/:id', name: 'PostDetail', component: PostDetailPage, meta: { requiresAuth: true } },
  { path: '/chat', name: 'Chat', component: ChatPage, meta: { requiresAuth: true } },
  { path: '/friends', name: 'Friends', component: FriendPage, meta: { requiresAuth: true } },
  { path: '/notifications', name: 'Notifications', component: NotificationPage, meta: { requiresAuth: true } },
  { path: '/profile', name: 'Profile', component: ProfilePage, meta: { requiresAuth: true } },
  { path: '/settings', name: 'Settings', component: SettingsPage, meta: { requiresAuth: true } },
  { path: '/admin', name: 'Admin', component: AdminPage, meta: { requiresAuth: true, requiresAdmin: true } },
  { path: '/devices', name: 'Devices', redirect: '/device-management' },
  { path: '/device-management', name: 'DeviceManagement', component: DeviceManagementPage, meta: { requiresAuth: true } },
  { path: '/liked-posts', name: 'LikedPosts', component: LikedPostsPage, meta: { requiresAuth: true } },
  { path: '/channels/applications', name: 'ChannelApplications', component: ChannelApplicationsPage, meta: { requiresAuth: true } },
  { path: '/tree-hole', name: 'TreeHole', component: TreeHolePage, meta: { requiresAuth: true } },
  { path: '/announcements', name: 'Announcements', component: AnnouncementPage, meta: { requiresAuth: true } },
  { path: '/favourites', name: 'Favourites', component: FavouritesPage, meta: { requiresAuth: true } },
  { path: '/channel/:id/group-chat', name: 'GroupChat', component: GroupChatPage, meta: { requiresAuth: true } },
  { path: '/search', name: 'Search', component: SearchPage, meta: { requiresAuth: true } },
  { path: '/hot-posts', name: 'HotPosts', component: HotPostsPage, meta: { requiresAuth: true } },
  { path: '/drafts', name: 'Drafts', component: DraftsPage, meta: { requiresAuth: true } },
  { path: '/user/:id', name: 'UserProfile', component: UserProfilePage, meta: { requiresAuth: true } },
  { path: '/follow-list', name: 'FollowList', component: FollowListPage, meta: { requiresAuth: true } },
  { path: '/following-feed', name: 'FollowingFeed', component: FollowingFeedPage, meta: { requiresAuth: true } },
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
  const userStr = localStorage.getItem('user')
  let user: any = null
  if (userStr) {
    try { user = JSON.parse(userStr) } catch {}
  }

  if (to.meta.requiresAuth && !token) {
    next('/login')
  } else if (to.path === '/login' && token) {
    next('/home')
  } else if (to.meta.requiresAdmin && (!user || user.role !== 'sys_admin')) {
    next('/home')
  } else {
    next()
  }
})

export default router
