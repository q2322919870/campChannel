# Camp Channel PC 端 (Vue3) 开发要点总结

> 生成日期: 2026-06-10
> 文档用途: Vue_Frontend 知识同步, 后续开发决策参考

---

## 一、项目概览

**项目名称**: Camp Channel 机电校园论坛
**产品形态**: Web PC端 + Flutter移动端 + UniApp微信小程序
**适用对象**: 广东机电职业技术学院在校学生 (@stu.gdmec.edu.cn)
**当前版本**: V3.0 (V2.0 P0/P1/P2 全部完成, V3.0 P1 全部完成)

---

## 二、PC 端技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| Vue.js | 3.x | 前端框架 (Composition API + <script setup>) |
| TypeScript | 5.4+ | 类型安全 |
| Vite | 5.4+ | 构建工具 |
| Pinia | 2.1+ | 状态管理 |
| Vue Router | 4.3+ | 路由管理 (createWebHashHistory) |
| Axios | 1.7+ | HTTP 请求封装 |
| Three.js | 0.184+ | 3D 画廊渲染 |
| @stomp/stompjs | 7.3+ | WebSocket 实时通信 (STOMP) |
| spark-md5 | 3.0+ | 文件 Hash 计算 (视频秒传) |
| Canvas/WebGL | - | 粒子系统、流体背景等视觉效果 |

**CSS**: 使用 CSS Variables + var() 系统, 无 TailwindCSS (已废弃/未使用), theme.ts 定义完整主题体系

---

## 三、项目结构 (camp-channel-client-pc)

```
camp-channel-client-pc/
├── src/
│   ├── api/
│   │   └── client.ts          # Axios 封装 (baseURL: /api, timeout: 15s)
│   ├── canvas/                # Three.js 3D + Canvas 视觉效果
│   │   ├── CanvasEngine.ts
│   │   ├── FluidBackground.ts
│   │   ├── GlassEffect.ts
│   │   ├── MoodShaderEffect.ts
│   │   ├── ParticleBurst.ts
│   │   ├── ParticleSystem.ts
│   │   ├── Post3DGallery.ts
│   │   ├── ThemeRenderer.ts
│   │   └── WeatherEffects.ts
│   ├── components/            # Vue 组件 (17个)
│   │   ├── AddGalleryDialog.vue      # 画廊上传弹窗
│   │   ├── BadgeShowcase.vue         # 徽章展示
│   │   ├── BlindBox.vue              # 盲盒
│   │   ├── CanvasBackground.vue      # Canvas 背景
│   │   ├── GalleryPreview.vue        # 画廊预览
│   │   ├── GlassCard.vue             # 玻璃态卡片
│   │   ├── MobileNav.vue             # 移动端导航 (响应式)
│   │   ├── NavSidebar.vue            # 左侧导航栏 + 用户信息 + 频道列表
│   │   ├── ParticleBurstOverlay.vue  # 粒子爆发效果
│   │   ├── PhotoCardStack.vue        # 照片卡片堆叠
│   │   ├── Post3DViewer.vue          # 3D 画廊查看器
│   │   ├── ReportDialog.vue          # 举报弹窗
│   │   ├── ShaderPostCard.vue        # 特效帖子卡片
│   │   ├── SmartVideoUploader.vue    # 视频上传组件 (Hash + 秒传)
│   │   ├── ThemeSwitcher.vue         # 主题选择器
│   │   ├── UserCard.vue              # 用户信息卡片 (关注/粉丝/TA的帖子)
│   │   └── WebGLBackground.vue       # WebGL 背景
│   ├── composables/
│   │   └── useBubbleNav.ts           # 气泡导航组合式函数
│   │   └── useVideoUploader.ts       # 视频上传逻辑 (SparkMD5)
│   ├── pages/                  # 页面视图 (27个)
│   │   ├── AdminPage.vue              # 管理后台
│   │   ├── AnnouncementPage.vue       # 公告页
│   │   ├── ChannelApplicationsPage.vue# 频道申请审核
│   │   ├── ChannelPage.vue            # 频道帖子流
│   │   ├── ChannelSearchPage.vue      # 频道搜索
│   │   ├── ChatPage.vue               # 私聊页面 (STOMP + Raw WS)
│   │   ├── CreatePostPage.vue         # 发帖页 (含草稿/编辑模式)
│   │   ├── DeviceManagementPage.vue   # 设备管理
│   │   ├── DraftsPage.vue             # 草稿箱
│   │   ├── FavouritesPage.vue         # 我的收藏
│   │   ├── FollowListPage.vue         # 粉丝/关注列表
│   │   ├── FollowingFeedPage.vue      # 关注动态流
│   │   ├── FriendPage.vue             # 好友列表
│   │   ├── GroupChatPage.vue          # 群聊页面 (STOMP)
│   │   ├── HomePage.vue               # 首页 (频道Tab + 关注Tab + 热门Tab)
│   │   ├── HotPostsPage.vue           # 热门帖子页
│   │   ├── LikedPostsPage.vue         # 我赞过的帖子
│   │   ├── LoginPage.vue              # 登录页
│   │   ├── NotificationPage.vue       # 通知中心 (分类Tab)
│   │   ├── PostDetailPage.vue         # 帖子详情 (评论/点赞/编辑/收藏)
│   │   ├── ProfilePage.vue            # 个人中心
│   │   ├── RegisterPage.vue           # 注册页
│   │   ├── SearchPage.vue             # 帖子搜索
│   │   ├── SettingsPage.vue           # 设置页
│   │   ├── TreeHolePage.vue           # 匿名树洞/告白
│   │   └── UserProfilePage.vue        # 用户主页
│   ├── router/
│   │   └── index.ts                 # Vue Router 配置 (Hash模式)
│   ├── stores/
│   │   ├── auth.ts                  # Pinia authStore: token/user/login/logout
│   │   └── theme.ts                 # Pinia themeStore: 18种主题,CSS Variables动态切换
│   ├── utils/                     # 工具函数
│   │   ├── canvasTransitionRenderer.ts
│   │   ├── canvasTransitions.ts
│   │   ├── cursorEffects.ts
│   │   ├── cursorRenderer.ts
│   │   ├── hybridTransitionManager.ts
│   │   ├── hybridTransitions.ts
│   │   ├── pageTransitionManager.ts
│   │   └── pageTransitions.ts
│   ├── types/
│   │   └── index.ts               # TS 类型定义 (User, Post, Channel, Comment等)
│   ├── App.vue                    # 根组件
│   ├── env.d.ts                   # Vite 环境声明
│   ├── main.ts                    # 应用入口
│   └── style.css                  # 全局样式 + CSS Variables
├── public/                        # 静态资源
├── package.json
└── vite.config.ts
```

---

## 四、状态管理关键

### auth store (stores/auth.ts)
- `token`: localStorage 持久化 JWT Token (不带 Bearer 前缀存储, 请求时自动拼接)
- `user`: User 对象, localStorage + session
- `isLoggedIn`: computed → !!token.value
- `isAdmin`: computed → user.role === 'sys_admin'
- `login(email, password)` → 登录 → 自动 strip "Bearer " 前缀 → 保存 token/user 到 localStorage
- `register(email, username, password, code, realName?)`
- `logout()` → 清除所有状态
- `loadFromStorage()` → 页面刷新时恢复用户信息

### theme store (stores/theme.ts)
- 18种主题 (lvy-neko暗/浅 + Material You + 15种自定义配色)
- 支持 Light/Dark/System 切换
- CSS Variables 通过 :root 动态更新 style attribute
- Theme 接口定义: name, brand, primary, secondary, surface, background, onSurface 等40+属性
- `style`: 'md3' | 'glass'
- borderRadius/cardRadius/buttonRadius/shadow/cardShadow 均随主题变化

---

## 五、路由系统

**模式**: createWebHashHistory (带 # 的 Hash 路由)

**28条路由:**
```
/          → /home           # Home: 首页信息流
/login     → LoginPage       # 登录
/register  → RegisterPage    # 注册
/home      → HomePage        # 首页 (requiresAuth)
/channel/:id → ChannelPage   # 频道帖子流 (requiresAuth)
/channels/search → ChannelSearchPage  # 频道搜索 (requiresAuth)
/post/create → CreatePostPage       # 发帖 (requiresAuth)
/post/:id    → PostDetailPage       # 帖子详情 (requiresAuth)
/chat        → ChatPage              # 私聊 (requiresAuth)
/friends     → FriendPage            # 好友 (requiresAuth)
/notifications → NotificationPage    # 通知 (requiresAuth)
/profile     → ProfilePage           # 个人中心 (requiresAuth)
/settings    → SettingsPage          # 设置页 (requiresAuth)
/admin       → AdminPage             # 管理后台 (requiresAuth + requiresAdmin)
/devices     → /device-management
/device-management → DeviceManagementPage  # 设备管理 (requiresAuth)
/liked-posts → LikedPostsPage                 # 我赞过的 (requiresAuth)
/channels/applications → ChannelApplicationsPage  # 频道申请审核
/tree-hole → TreeHolePage                   # 树洞告白 (requiresAuth)
/announcements → AnnouncementPage           # 公告 (requiresAuth)
/favourites → FavouritesPage                 # 收藏 (requiresAuth)
/channel/:id/group-chat → GroupChatPage     # 群聊 (requiresAuth)
/search   → SearchPage                      # 帖子搜索 (requiresAuth)
/hot-posts → HotPostsPage                   # 热门帖子 (requiresAuth)
/drafts   → DraftsPage                       # 草稿箱 (requiresAuth)
/user/:id → UserProfilePage                  # 用户主页 (requiresAuth)
/follow-list → FollowListPage                # 粉丝关注列表 (requiresAuth)
/following-feed → FollowingFeedPage           # 关注动态 (requiresAuth)
```

**守卫逻辑:**
- `requiresAuth` 路由: 无 token → /login; 已有 token -> 访问 login → /home
- `requiresAdmin` 路由: AuthStore.isAdmin 校验

---

## 六、后端 API 全集梳理

### Base URL
- Vite dev server proxy to `http://10.50.30.104:8080/api`
- CORS enabled for localhost dev
- Axios baseURL: `/api`, timeout: 15000ms

### JWT 认证
- Header: `Authorization: Bearer <token>` (Token 不带 "Bearer " 存储)
- Token 过期时间: 24小时
- 单设备登录, 新登录踢旧设备

### API 接口汇总 (共19个模块, 约80+端点)

#### 1. 身份认证 `/api/auth` (3)
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /auth/send-code | 发送注册验证码 (仅 @stu.gdmec.edu.cn) |
| POST | /auth/register | 用户注册 {email, username, password, code, realName?} |
| POST | /auth/login | 登录 {email/username, password} → token + userId + username |

#### 2. 用户中心 `/api/users` (9)
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /users/me | 获取当前用户信息 |
| GET | /users/profile | 获取个人资料 (含统计数据) |
| GET | /users/{userId} | 根据ID获取用户信息 |
| GET | /users/{userId}/profile | 获取用户名片 (+最近20条帖子) |
| PUT | /users/profile | 更新资料 {username, realName?, phone?} |
| PUT | /users/password | 修改密码 {oldPassword, newPassword} |
| POST | /users/avatar | 上传头像 (multipart: file) |
| GET | /users/devices | 获取登录设备列表 |
| DELETE | /users/devices/{deviceId} | 远程下线设备 |

#### 3. 帖子管理 `/api/posts` (18)
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /posts?page=1&size=10 | 首页信息流 |
| GET | /posts/tree-hole?page=1&size=10 | 匿名树洞 |
| POST | /posts | 创建帖子 {channelId, content, images?, videoUrls?, isAnonymous?} |
| PUT | /posts/{postId} | 编辑帖子 (递增 editCount) |
| DELETE | /posts/{postId} | 删除帖子 |
| GET | /posts/channel/{channelId}?page=1&size=10 | 获取频道帖子 (置顶+时间排序) |
| GET | /posts/user/{userId}?page=1&size=20 | 获取用户帖子 |
| GET | /posts/my?page=1&size=10 | 我的帖子 |
| GET | /posts/hot?page=1&size=10 | 热门帖子 (7天热度) |
| GET | /posts/favourites?page=1&size=10 | 我的收藏 |
| GET | /posts/liked?page=1&size=10 | 我赞过的 |
| POST | /posts/{postId}/favourite | 收藏/取消收藏 (toggle) |
| GET | /posts/{postId}/favourite/status | 检查收藏状态 {isFavourited, count} |
| POST | /posts/{postId}/like | 点赞/取消点赞 (toggle) {liked, likeCount} |
| GET | /posts/{postId}/like/status | 检查点赞状态 |
| POST | /posts/{postId}/pin | 置顶/取消置顶 {isPinned, message} |
| POST | /posts/{postId}/report | 举报帖子 |
| GET | /posts/search?keyword=&page=1&size=20 | 搜索帖子 |
| GET | /posts/{postId}/view | 增加浏览量 |
| POST | /posts/{postId}/reveal | 记录解开告白 (跨设备同步) |
| GET | /posts/drafts?page=1&size=20 | 获取草稿列表 |
| POST | /posts/draft | 保存草稿 |
| DELETE | /posts/draft/{id} | 删除草稿 |
| POST | /posts/draft/{id}/publish | 发布草稿 (自动删除) |

#### 4. 频道管理 `/api/channels` (14)
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /channels | 创建频道 {name, description} |
| GET | /channels/search?keyword= | 搜索频道 |
| GET | /channels/my | 我的频道列表 |
| GET | /channels/{id} | 获取频道详情 |
| POST | /channels/{id}/join | 申请加入 |
| POST | /channels/{id}/leave | 退出频道 |
| PUT | /channels/{id} | 编辑频道 |
| GET | /channels/{id}/members | 获取成员 |
| POST | /channels/{id}/members/{userId}/role | 设置角色 {role: admin/member} |
| POST | /channels/{id}/members/{userId}/mute | 禁言/取消禁言 {muted: true/false} |
| GET | /channels/applications/pending/count | 待审核总数 |
| GET | /channels/applications/pending | 待审核申请列表 |
| POST | /channels/applications/{id}/approve | 审核通过 |
| POST | /channels/{id}/members/{userId}/remove | 移除成员 |

#### 5. 聊天模块 `/api/chat` (10)
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /chat/online/{userId} | 查询用户在线 |
| GET | /chat/online/batch?userIds=1,2,3 | 批量查询在线状态 |
| POST | /chat/messages/send | 发送消息 {receiverId, content, type: 1/2/3} |
| GET | /chat/history/{friendId}?page=1&size=20 | 获取聊天记录 |
| POST | /chat/messages/{id}/recall | 撤回消息 |
| GET | /chat/conversations | 会话列表 |
| GET | /chat/conversations/with-unread | 含未读计数的会话列表 |
| GET | /chat/unread/{friendId} | 获取未读数 |
| POST | /chat/read-all/{friendId} | 标记全部已读 |
| POST | /chat/messages/{id}/read | 标记单条已读 |

#### 6. 评论模块 (4)
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /posts/{postId}/comments | 发表评论 {content, parentId?} |
| GET | /posts/{postId}/comments?page=1&size=20 | 获取评论列表 (含 likeCount+isLiked) |
| DELETE | /posts/{postId}/comments/{commentId} | 删除评论 |
| POST | /posts/{postId}/comments/{commentId}/like | 评论点赞/取消 (toggle) |

#### 7. 画廊模块 (12)
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /gallery?page=1&size=20&channelId=1 | 画廊列表 |
| POST | /gallery | 添加画作 {imageUrl?, videoUrl?, mediaType, title, description, channelId} |
| GET | /gallery/my | 我的画作 |
| DELETE | /gallery/{id} | 删除画作 |
| POST | /gallery/{id}/like | 点赞/取消 (toggle) |
| GET | /gallery/{id}/like/status | 检查点赞状态 |
| POST | /gallery/{id}/comment | 评论画作 |
| GET | /gallery/{id}/comments | 获取画作评论 |
| POST | /gallery/{id}/share | 分享画作到聊天 |
| GET | /gallery/pending (admin) | 待审核作品 |
| POST | /gallery/{id}/approve (admin) | 审核通过 |
| DELETE | /gallery/admin/{id} (admin) | 管理员删除 |

#### 8. 好友模块 (5)
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /friends/request | 发送好友申请 {friendId} |
| GET | /friends/requests | 获取好友请求列表 |
| POST | /friends/request/{id}/handle | 处理申请 {accepted: true/false} |
| GET | /friends | 获取好友列表 (+ onlineStatus) |
| DELETE | /friends/{friendId} | 删除好友 |

#### 9. 通知模块 (5)
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /notifications/unread | 获取未读通知 |
| GET | /notifications/unread/count | 获取未读数 |
| GET | /notifications/history?page=1&size=20&category= | 历史 (支持分类过滤: system/interaction/chat) |
| POST | /notifications/{id}/read | 标记已读 |
| POST | /notifications/read-all | 全部已读 |

通知类型: like, comment, mention, friend_request, channel_system

#### 10. 公告模块 (2)
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /announcements?page=1&size=10 | 获取公告列表 |
| GET | /announcements/{id} | 获取详情 |

#### 11. 徽章模块 (3)
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /badges/my | 我的徽章 |
| POST | /badges/{id}/equip | 佩戴 |
| POST | /badges/{id}/unequip | 取消佩戴 |

#### 12. 举报模块 (2)
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /reports | 提交举报 {targetType, targetId, reason} |
| GET | /reports/my | 我的举报 |

#### 13. 上传模块 (3)
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /upload/image | 图片上传 (multipart: file) → {url} |
| POST | /upload/video | 视频上传 + FFmpeg压缩 → {url} (≤5MB, 自动去重) |
| GET | /upload/video/check?hash=xxx | 秒传校验 → {exists, url} |

#### 14. 管理员模块 (7)
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/users?page=1&size=20 | 所有用户 |
| POST | /admin/users/{id}/role | 设置角色 {role: sys_admin/channel_admin/user} |
| POST | /admin/users/{id}/status | 禁用/启用 {status: 0/1} |
| GET | /admin/reports?page=1&size=20 | 所有举报 |
| POST | /admin/reports/{id}/handle | 处理举报 {handled, action} |
| POST | /admin/announcements | 发布公告 {title, content} |
| DELETE | /admin/announcements/{id} | 删除公告 |

#### 15. 群聊模块 (3)
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /group-messages | 发送群消息 {channelId, content?, mediaUrl?, msgType:1/2/3} |
| GET | /group-messages/{channelId}?page=1&size=50 | 获取频道消息 |
| DELETE | /group-messages/{id} | 撤回群消息 |

#### 16. 关注模块 (6)
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /follow/{userId}/toggle | 关注/取消关注 (toggle) → {message, data: true/false} |
| GET | /follow/{userId}/followers?page=1&size=20 | 粉丝列表 |
| GET | /follow/{userId}/following?page=1&size=20 | 关注列表 |
| GET | /follow/{userId}/counts | 粉丝数+关注数 {followerCount, followingCount} |
| GET | /follow/{userId}/is-following | 检查是否已关注 → {data: true/false} |
| GET | /follow/feed?page=1&size=20 | 关注动态Feed流 |

---

## 七、WebSocket 实时通信

### PC 端 (STOMP)
- 地址: `ws://localhost:8080/ws` (或 `wss://host/ws`)
- 连接时使用 Authorization Header
- 订阅频道:
  - `/user/queue/messages` - 私聊消息
  - `/user/queue/read-receipts` - 已读回执
  - `/user/queue/notifications` - 系统通知
- 发送: `/app/chat.send`

### Flutter端 (Raw WebSocket)
- 地址: `ws://localhost:8080/ws/raw?token=xxx`
- 消息格式: `{ type, data, timestamp }`

---

## 八、前端关键开发规范

### API 调用约定
1. **统一 baseURL**: `/api` (Vite proxy 转发到 `http://10.50.30.104:8080/api`)
2. **Token**: localStorage.getItem('token') + `Authorization: Bearer ${token}`
3. **错误处理**: Axios response interceptor 自动处理 401 → redirect /login
4. **响应格式**: `{ code, message, data }` — code 200 = 成功
5. **文件上传**: Content-Type: multipart/form-data, field name: `file`
6. **视频秒传**: SparkMD5 分片计算 (2MB chunk) → GET /upload/video/check?hash=xxx

### 状态管理约定
1. Auth 状态: Pinia authStore (stores/auth.ts)
2. Theme 状态: Pinia themeStore (stores/theme.ts) — 通过 setCSSVariables 更新根节点 CSS vars
3. Token 存储: localStorage (`token` / `user`)
4. Token 携带: 请求拦截器自动拼接 `Bearer ${token}`

### 页面组件约定
1. 所有页面无登录态 → 守卫跳转 /login
2. 用户信息通过 authStore.user 获取
3. 图片URL统一处理 (`https://` before `/uploads/`): API返回相对路径需拼接 base URL
4. Pinia stores 使用 `defineStore` + Composition API 风格

### 主题系统
1. CSS Variables 体系: :root style attribute 动态更新
2. theme.ts 定义完整的 Theme interface (~40个属性)
3. 18种预设主题: Lvy-neko暗/浅, Material You, 15种自定义配色
4. Style系统: 'glass' (玻璃态) | 'md3' (Material Design 3)
5. ThemeSwitcher 组件提供可视化选择
6. 主题偏好 localStorage 持久化

### 视频上传流程
1. SparkMD5 分片计算文件 Hash (2MB 分片, 不阻塞主线程)
2. 调用 `GET /upload/video/check?hash=xxx` 秒传校验
3. 不存在则 `POST /upload/video` 上传 (multipart: file)
4. 后端 FFmpeg 自动压缩到 ~5MB

### 路由约定
1. Hash 模式: createWebHashHistory()
2. requiresAuth 守卫 → 无 token 跳转 /login
3. requiresAdmin 守卫 → authStore.isAdmin 校验
4. window.__VUE_ROUTER__ = router (供过渡动画系统使用)

---

## 九、页面开发清单 (已完成 100%)

| 页面 | 路由 | V3.0 P1 | 说明 |
|------|------|---------|------|
| HomePage | /home | ✅ | 频道Tab + 关注Tab + 热门Tab |
| LoginPage | /login | - | 邮箱+密码登录 |
| RegisterPage | /register | - | 验证码+注册 |
| ChannelPage | /channel/:id | ✅ | 频道帖子流 (置顶标记) |
| PostDetailPage | /post/:id | ✅ | 详情/评论/点赞/收藏/分享(已编辑标记) |
| ChatPage | /chat | ✅ | 私聊 (STOMP/WebSocket + 多媒体渲染) |
| GroupChatPage | /channel/:id/group-chat | ✅ | 群聊 (禁言/撤回/成员面板) |
| FriendPage | /friends | ✅ | 好友列表 (+ 在线状态圆点) |
| NotificationPage | /notifications | ✅ | 分类Tab (全部/系统/互动/聊天) + 已读 |
| ProfilePage | /profile | ✅ | 我的帖子/收藏/徽章 + 主题切换 |
| SettingsPage | /settings | ✅ | 个人信息/密码/设备管理 |
| AdminPage | /admin | ✅ | 用户/频道/内容/举报/公告管理 |
| FavouritesPage | /favourites | ✅ | 我的收藏列表 |
| LikedPostsPage | /liked-posts | - | 我赞过的帖子 |
| SearchPage | /search | ✅ | 关键词搜索 + 最近搜索记录 |
| HotPostsPage | /hot-posts | ✅ | 热门帖子排行榜 (7天热度) |
| DraftsPage | /drafts | ✅ | 草稿箱 + 编辑/发布/删除 |
| ChannelSearchPage | /channels/search | - | 频道搜索 |
| ChannelApplicationsPage | /channels/applications | - | 申请审核管理 |
| TreeHolePage | /tree-hole | ✅ | 匿名树洞 (迷雾效果+解开) |
| AnnouncementPage | /announcements | ✅ | 公告列表 |
| UserProfilePage | /user/:id | ✅ | 用户主页 + 帖子列表 |
| FollowListPage | /follow-list | ✅ | 粉丝/关注列表 |
| FollowingFeedPage | /following-feed | ✅ | 关注动态流 |
| CreatePostPage | /post/create | ✅ | 发帖 (含草稿/编辑模式) |

---

## 十、V3.0 P1 完成度汇总

| 功能 | 状态 | P1编号 |
|------|------|--------|
| 帖子编辑 (editCount + lastEditTime) | ✅ 100% | P1-5 |
| 评论点赞 (comment_like表 + toggle API + UI) | ✅ 100% | P1-6 |
| 用户主页增强 (UserProfilePage + UserProfileInfoView) | ✅ 100% | P1-7 |
| 关注系统 (follow表 + toggleAPI + FollowingFeed + FollowList) | ✅ 100% | P1-8 |
| 通知中心优化 (分类Tab + read-all API + 类型化图标) | ✅ 100% | P1-9 |
| 深色模式 (18种主题 + CSS Variables + ThemeSwitcher) | ✅ 100% | P1-10 |

**V3.0 P1 总体完成度: 6/6 = 100%**

---

## 十一、后续开发建议

### 1. 类型系统增强
- Post 接口缺失 `isPinned`, `editCount`, `lastEditTime` 字段
- Comment 接口缺失 `likeCount`, `isLiked` 字段
- 建议创建完整的 API Response Types (区分 request type 和 response DTO)

### 2. API 封装层优化
- client.ts 仅有 Axios 实例, 无具体 API 方法封装
- 建议按模块拆分: authApi.ts, postApi.ts, chatApi.ts 等
- 使用 composables 模式统一管理接口调用

### 3. WebSocket 消息类型定义
- STOMP + Raw WS 的消息类型没有 TypeScript 定义
- 建议创建 webSocketTypes.ts 统一定义消息格式

### 4. P2 (V3.1) 功能预留
关注模块已实现但前端尚未完整使用所有接口:
- POST /users/{id}/follow → toggleFollow(已用)
- GET /users/{id}/followers/following → FollowListPage (已用)
- GET /follow/feed → FollowingFeedPage (已用)
- 其余 V3.1 P2 功能待实现: 帖子分享/转发, 表情包/GIF, 频道排行榜, 用户等级/勋章, E2EE, 厂商推送

### 5. CSS/主题系统注意
- 全局 style.css 定义了 CSS Variables 体系
- 新增组件必须使用 `var()` 引用颜色, 禁止硬编码颜色值
- borderRadius/cardRadius/buttonRadius/shadow 等所有尺寸随主题变化
- glass/md3 两种 style 切换影响整体视觉风格

### 6. API Base URL 注意
| 环境 | baseURL 设置 |
|------|-------------|
| Dev proxy | Vite proxy → /api → http://10.50.30.104:8080/api |
| Production | 需配置实际部署地址 |
- Axios interceptor: `Authorization: Bearer ${token}`
- Token 存储不带 "Bearer " 前缀

---

## 十二、关键文件清单

| 文件 | 用途 |
|------|------|
| src/api/client.ts | Axios 实例 + interceptors (认证/401处理) |
| src/stores/auth.ts | Pinia authStore (登录/注册/token/user) |
| src/stores/theme.ts | Pinia themeStore (18种主题管理) |
| src/router/index.ts | 28条路由 + 导航守卫 |
| src/types/index.ts | User/Post/Channel/Comment/Friendship/Message/Notification |
| src/style.css | 全局样式 + CSS Variables 基础定义 |
| src/composables/useVideoUploader.ts | 视频上传逻辑 (SparkMD5) |
| src/components/NavSidebar.vue | 侧边导航栏 |
| src/components/UserCard.vue | 用户信息卡片 |
| src/components/SmartVideoUploader.vue | 视频上传组件 |
| src/components/ThemeSwitcher.vue | 主题切换器 |
| src/canvas/Post3DGallery.ts | Three.js 3D画廊 |
| src/pages/HomePage.vue | 首页 (核心入口) |
| src/pages/ChatPage.vue | 私聊页面 |
| src/pages/GroupChatPage.vue | 群聊页面 |
| src/pages/PostDetailPage.vue | 帖子详情 |
| src/pages/CreatePostPage.vue | 发帖页 |
| src/pages/FollowingFeedPage.vue | 关注动态 |

---

## 十三、数据库表前端映射关系

| 数据库表 | 对应 API | 前端页面 |
|----------|---------|---------|
| user | /api/users/* | ProfilePage, UserProfilePage |
| post | /api/posts/* | HomePage, ChannelPage, PostDetailPage |
| comment | /api/posts/{id}/comments* | PostDetailPage |
| channel | /api/channels/* | ChannelPage, ChannelSearchPage |
| channel_member | /api/channels/*/members* | GroupChatPage (禁言/角色) |
| post_favourite | /api/posts/*/favourite | FavouritesPage, PostDetailPage |
| post_like | /api/posts/*/like | PostCard (点赞按钮), PostDetailPage |
| comment_like | /api/posts/{id}/comments/{cid}/like | PostDetailPage (评论项) |
| follow | /api/follow/* | FollowListPage, FollowingFeedPage, UserCard |
| friendship | /api/friends/* | FriendPage, UserProfilePage |
| message | /api/chat/* | ChatPage |
| group_message | /api/group-messages* | GroupChatPage |
| notification | /api/notifications/* | NotificationPage |
| gallery | /api/gallery* | Post3DViewer + GalleryPreview |
| post_draft | /api/drafts* | DraftsPage, CreatePostPage |
| badge/user_badge | /api/badges/* | BadgeShowcase, ProfilePage |
| announcement | /api/announcements* | AnnouncementPage |
| report | /api/reports* | AdminPage (举报处理) |

---

**文档总结**: 项目已处于 V3.0 P1 完成阶段 (100%), 前后端功能全面对齐。后续重点在 P2/V3.1 体验增强功能、类型系统完善、API层优化等方面推进。
