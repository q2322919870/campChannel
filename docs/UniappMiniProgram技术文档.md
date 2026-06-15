# Camp Channel 微信小程序端 (UniApp) 技术文档

> 版本: V2.0
> 创建日期: 2026-06-10
> 最后更新: 2026-06-15
> 状态: 功能快速补齐中，核心功能已基本完成

---

## 一、项目概述

Camp Channel 微信小程序端基于 UniApp 3.x (alpha) 框架构建，使用 Vue 3 + TypeScript + Pinia 技术栈。目标平台包括 **微信小程序 (mp-weixin)** 和 **H5 (浏览器)**。

后端 API 基础地址: `http://10.50.30.104:8080/api`
WebSocket地址: `ws://10.50.30.104:8080/ws/raw?token=xxx`

---

## 二、技术栈总览

| 层级 | 技术方案 |
|------|---------|
| UI框架 | UniApp 3.0.0-alpha (Vue 3 Composition API) |
| 状态管理 | Pinia 2.1+ (defineStore + ref) |
| HTTP客户端 | uni.request API (在 utils/request.ts 中封装) |
| WebSocket | uni.connectSocket + wsManager (utils/websocket.ts) |
| 语言 | TypeScript 5.2+ + Vue SFC (.vue 单文件组件) |
| 构建工具 | Vite 5.1+ (@dcloudio/vite-plugin-uni) |
| 样式系统 | uni-app scoped style, rpx 响应式单位, backdrop-filter |

**package.json 依赖:**
- `@dcloudio/uni-app` 3.0.0-alpha (编译到各平台)
- `@dcloudio/uni-h5` 3.0.0-alpha (H5 平台适配)
- `@dcloudio/uni-mp-weixin` 3.0.0-alpha (微信小程序适配)
- `pinia` ^2.1.7
- `vue` ^3.4.21 + `vue-i18n` ^9.9.1
- TypeScript ^5.2.2, Vite ^5.1.4

**构建命令:**
- 开发小程序: `npm run dev:mp-weixin`
- 构建小程序: `npm run build:mp-weixin`
- 开发 H5: `npm run dev:h5`
- 构建 H5: `npm run build:h5`

---

## 三、目录结构与模块说明

```
camp-channel-client-uniapp/
├── package.json                    # NPM 依赖 & 构建脚本
├── vite.config.ts                  # Vite / UniApp 插件配置
├── tsconfig.json                   # TypeScript 编译配置
├── index.html                      # H5 入口 HTML
└── src/
    ├── main.ts                     # Vue 应用挂载入口 (Pinia 初始化)
    ├── App.vue                     # 根组件 (全局样式 + 生命周期钩子)
    ├── env.d.ts                    # TypeScript 环境类型声明
    ├── manifest.json               # UniApp 应用配置 (应用名称、图标、SDK 配置等)
    ├── pages.json                  # UniApp 页面路由表和 tabBar 配置
    ├── stores/
    │   └── auth.ts                 # ⭐ Pinia Store - 认证状态管理 (token + userInfo)
    ├── utils/
    │   ├── request.ts              # ⭐ HTTP 请求核心封装 (uni.request 代理, BearerToken自动附加, 401强制下线)
    │   ├── websocket.ts            # ⭐ WebSocket 单例管理器 (事件总线模式, PERSISTANT重连机制)
    │   └── useSwipeTab.ts          # 自定义 Hook - 滑动导航手势检测
    ├── components/
    │   └── PostCard.vue            # 帖子卡片组件 (头像/标题/内容/图片预览/点赞/评论/分享)
    └── pages/                      # 页面模块 (按领域分组)
        ├── index/index.vue         # 🔖 TabBar首页 - 频道信息流 + 搜索栏 + WebSocket实时推送
        ├── login/login.vue         # 登录页 (邮箱+密码, @stu.gdmec.edu.cn 验证)
        ├── register/register.vue   # 注册页
        ├── channel/channel.vue     # 🔖 TabBar频道广场 - 搜索/发现频道 + 频道详情(帖子/成员/管理/群聊入口)
        ├── chat/list.vue           # 🔖 TabBar消息列表 - 频道群聊 + 私聊会话列表
        ├── chat/detail.vue         # 私聊详情页 - 文字/图片/视频消息 + 历史加载 + 实时推送 + 撤回 + 已读状态
        ├── chat/group-chat.vue     # 频道群聊页 - 文字/图片/视频消息 + WebSocket实时推送 + 消息撤回
        ├── friend/list.vue         # 好友列表页
        ├── friend/search.vue       # 搜索好友/查看名片
        ├── notification/notification.vue  # 🔖 TabBar通知中心 - 分类筛选 + 全部已读
        ├── profile/profile.vue     # 🔖 TabBar个人中心 - 关注/粉丝数 + 收藏入口 + Avatar
        ├── settings/settings.vue   # 设置页
        ├── post/create.vue         # 发布/编辑帖子页 (支持编辑模式)
        ├── post/detail.vue         # 帖子详情页 (评论/点赞/收藏/分享/浏览量)
        ├── post/favourites.vue     # 我的收藏页 (分页加载)
        ├── post/my-posts.vue       # 我的帖子页
        ├── post/liked-posts.vue    # 赞过的贴页
        ├── admin/admin.vue         # 管理后台页
        └── test/connection.vue     # 连接测试页 (开发调试用)
```

---

## 四、全局共享文档参考

所有端负责人必读的根目录文档:
1. `README.md` - 项目总览 (Camp Channel / 机电校园论坛)
2. `API接口文档.md` - **API契约** (19个模块, ~75个接口)
3. `V3.0_开发进度.md` - V3.0 P0+P1 完成度 (全部已完成)
4. `V2.0_开发进度.md` - V2.0 历史里程碑
5. `Camp Channel 校园频道系统 V2.0 需求文档.md` - V2 需求规格
6. `CAMP_CHANNEL_ISSUES.md` - 已知问题清单
7. `V3.0_升级方案.md` - V3.0 升级方案
8. `implementation_plan.md` - 实施计划

其他端技术文档 (docs/):
- `Server端技术文档.md` - Spring Boot + JDK26 (后端)
- `Flutter端技术文档.md` - Dart + Flutter (移动端)
- `PC端技术文档.md` + `Vue3前端开发要点总结.md` - PC Web端

---

## 五、页面路由表 (pages.json)

### Tabs (底部导航栏)
| Tab Index | Page Path | Title | 功能说明 |
|-----------|-----------|-------|---------|
| 0 | pages/index/index | 校园频道 | 🔖 首页信息流 |
| 1 | pages/channel/channel | 频道广场 | 🔖 发现/加入频道 |
| 2 | pages/chat/list | 消息 | 🔖 私聊会话列表 |
| 3 | pages/notification/notification | 通知中心 | 🔖 系统/互动/聊天通知 |
| 4 | pages/profile/profile | 我的 | 🔖 个人中心 |

### 普通页面 (通过 navigateTo/switchTab/reLaunch)
| Page Path | Title | 对应 API 模块 |
|-----------|-------|-------------|
| pages/login/login | 登录 | 认证模块 |
| pages/register/register | 注册账号 | 认证模块 |
| pages/post/create | 发布帖子 | 帖子管理 |
| pages/post/detail | 帖子详情 | 帖子/评论/点赞/收藏 |
| pages/post/favourites | 我的收藏 | 帖子收藏列表 |
| pages/post/my-posts | 我的帖子 | 帖子管理 |
| pages/post/liked-posts | 赞过的贴 | 帖子管理 |
| pages/chat/detail | 私聊对话 | 聊天(文字/图片/视频) |
| pages/chat/group-chat | 频道群聊 | 群聊消息模块 |
| pages/friend/list | 好友列表 | 好友关系 |
| pages/friend/search | 搜索好友 | 好友关系 |
| pages/settings/settings | 设置 | 用户中心/通知配置 |
| pages/admin/admin | 管理后台 | 管理员模块 |
| pages/test/connection | 连接测试 | 开发调试用 |

**共计: 5 个 TabBar 页面 + 14 个普通页面 = 19 个页面**

---

## 六、状态管理方案

### Auth Store (Pinia)
文件: `stores/auth.ts`

```typescript
export const useAuthStore = defineStore('auth', () => {
  // token 存储于 uni.getStorageSync('auth_token')
  // userInfo 存储于 uni.getStorageSync('user_info')
  const token = ref(tokenStr)
  const userInfo = ref(userInfoObj)  // {userId, username, email, role, avatar}

  function setAuth(newToken, user)    // 登录成功后写入
  function clearAuth()                // 清除缓存
  function logout()                   // 退出登录 (调用clearAuth)
})
```

- Token 在 `utils/request.ts` 中自动附加到 Authorization header
- 收到 HTTP 401 或业务码 1009 时触发强制下线弹窗 → 跳转登录页
- uni.connectSocket (WebSocket) 也在 URL query 中附加 token

---

## 七、网络请求封装

文件: `utils/request.ts`

### BASE_URL 解析策略
1. 优先读取 `uni.getStorageSync('api_base_url')` 缓存值
2. 默认 fallback → `http://10.50.30.104:8080/api`

### request() 方法签名
```typescript
// 两种调用方式都支持
request('/auth/login', { method: 'POST', data: {...} })
request('/posts')  // GET默认
```

### 核心行为
1. **Token 自附加**: 自动从 `uni.getStorageSync('auth_token')` 读取, 写入 Authorization header
2. **Content-Type**: 固定 application/json
3. **401/1009 处理**: 清除 token + userInfo → 弹窗通知 → uni.reLaunch('/pages/login/login')
4. **图片 URL 转换**: `processImageUrl()` — 相对路径 `/uploads/images/x.jpg` → `BASE_URL/uploads/images/x.jpg`

---

## 八、WebSocket 集成方案

文件: `utils/websocket.ts`, WSManager (单例模式)

### 连接地址解析
```
http://xxx/api → ws://xxx/ws/raw?token=xxx
https://xxx/api → wss://xxx/ws/raw?token=xxx  (暂不支持)
本地开发默认: ws://localhost:8080/ws/raw?token=xxx
生产环境默认: ws://10.50.30.104:8080/ws/raw?token=xxx
```

### 事件类型与订阅端点

| 消息类型 (data.type) | 订阅位置 | 行为 |
|---------------------|---------|------|
| new_post | pages/index/index (首页) | 刷新信息流 |
| new_comment | pages/index/index (首页) | 刷新信息流 |
| new_like | pages/index/index (首页) | 刷新信息流 |
| new_message | pages/chat/detail (私聊) | 追加消息到列表 (支持type=1/2/3) |
| message_read | pages/chat/detail (私聊) | 更新已读状态 ✓✓ |
| new_group_message | pages/chat/group-chat (群聊) | 追加群聊消息到列表 |

### 重连机制
- 指数退避: 1s → 2s → 4s → ... → 30s max
- 最多重试 5 次, 超过后停止自动重连

---

## 九、已实现功能清单

### ✅ 身份认证 (API Section 1) — 完成度 100%
| API | UniApp 实现 | 所在页面 |
|-----|------------|---------|
| POST /auth/login | ✅ `request({url:'/auth/login', method:'POST'})` | login.vue |
| POST /auth/register | ✅ register.vue | register.vue |
| POST /auth/send-code | TODO (验证码功能) | 未实装 |

### ✅ 用户中心 (API Section 2) — 完成度 60%
| API | UniApp 实现 | 状态 |
|-----|------------|------|
| GET /users/me | ✅ profile.vue, chat/detail (获取自己信息) | ✅ |
| GET /users/profile | 未直接调用, userInfo来自store | ⚠️ 需确认是否需要单独调用 |
| GET /users/{userId} | TODO | ⚠️ search好友用? |
| PUT /users/profile | **未实现** | ❌ 缺漏 |
| PUT /users/password | **未实现** | ❌ 缺漏 |
| POST /users/avatar | ✅ profile.vue: uni.uploadFile → `${BASE_URL}/users/avatar` | ✅ |

### ✅ 帖子管理 (API Section 3) — 完成度 85%
| API | UniApp 实现 | 所在页面 | 状态 |
|-----|------------|---------|------|
| POST /posts | ✅ create.vue | pages/post/create | ✅ |
| GET /posts/{postId} | ✅ detail.vue (含 isLiked/likeCount/commentCount) | pages/post/detail | ✅ |
| PUT /posts/{postId} | ✅ create.vue 编辑模式 (URL query带editId, 按钮显示"发布"/"更新") | pages/post/create | ✅ |
| DELETE /posts/{postId} | ❌ **未实现** | ? | ❌ 缺漏 |
| GET /posts/hot | ❓ TODO | ? | ⚠️ |
| GET /posts/my | ✅ profile.vue | pages/profile | ✅ |
| GET /posts/favourites | ✅ favourites.vue (分页滚动加载) | pages/post/favourites | ✅ |
| POST /posts/{id}/favourite | ✅ detail.vue: 收藏/取消收藏 toggle | pages/post/detail | ✅ |
| GET /posts/{id}/favourite/status | ✅ detail.vue: 独立try/catch静默失败 | pages/post/detail | ✅ |
| GET /posts/search?keyword=X | ✅ index.vue: 搜索栏 | pages/index | ✅ |
| GET /posts/{id}/view | ✅ detail.vue: 进入详情自动+1 | pages/post/detail | ✅ |
| GET /posts/channel/{id} | ✅ channel.vue, index.vue | pages/channel, index | ✅ |
| @提及通知 + 自动解析 | 后端已有, 小程序端依赖通知API | 通用能力 | ✅ |

### ✅ 频道管理 (API Section 4) — 完成度 70%
| API | UniApp 实现 | 所在页面 | 状态 |
|-----|------------|---------|------|
| POST /channels | ✅ channel.vue: `/channels` | pages/channel | ? |
| GET /channels/search | ✅ channel.vue: `/channels/search?keyword=` | pages/channel/list | ✅ |
| GET /channels/my | ✅ home page: `/channels/my`, channel.vue detail | pages/index, channel | ✅ |
| POST /channels/{id}/join | ✅ channel.vue: `POST /channels/${id}/join` | pages/channel | ✅ |
| POST /channels/{id}/leave | ✅ channel.vue: `POST /channels/${id}/leave` | pages/channel | ✅ |
| GET /channels/{id}/members | ✅ channel.vue: `/channels/${id}/members` | pages/channel | ✅ |
| Channel 创建页 (form) | **未找到** — search 中 `channel_create_page.dart` 仅为 Flutter 端文件 | ❌ uniapp缺漏 |

### ✅ 聊天模块 (API Section 5) — 完成度 95%
| API | UniApp 实现 | 所在页面 | 状态 |
|-----|------------|---------|------|
| GET /chat/online/batch | TODO | chat/list? | ⚠️ 在线状态查询 |
| POST /chat/messages/send | ✅ detail.vue: type=1文字, type=2图片, type=3视频 | pages/chat/detail | ✅ |
| GET /chat/history/{friendId} | ✅ detail.vue: 含type字段解析图片/视频URL + 30s轮询 | pages/chat/detail | ✅ |
| POST /chat/read-all/{friendId} | ✅ detail.vue mounted时调用 | pages/chat/detail | ✅ |
| POST /chat/messages/{id}/recall | ✅ detail.vue: 2min限制 + showModal确认 | pages/chat/detail | ✅ |
| POST /upload/image | ✅ detail.vue: uni.uploadFile + 发送图片消息 | pages/chat/detail | ✅ |
| POST /upload/video | ✅ detail.vue: uni.chooseVideo + uni.uploadFile + 发送视频消息 | pages/chat/detail | ✅ |
| 多媒体渲染 | ✅ `<image>` type=2, `<video>` type=3, 文本 type=1 | pages/chat/detail | ✅ |

### ✅ 评论模块 (API Section 6) — 完成度 100%
| API | UniApp 实现 | 所在页面 | 状态 |
|-----|------------|---------|------|
| POST /posts/{id}/comments | ✅ detail.vue | pages/post/detail | ✅ |
| GET /posts/{id}/comments | ✅ detail.vue | pages/post/detail | ✅ |

### ✅ 点赞模块 (API Section 7) — 完成度 ~80%
| API | UniApp 实现 | 所在页面 | 状态 |
|-----|------------|---------|------|
| POST /posts/{id}/like | ✅ home/index.vue: toggleLike → `POST /posts/${post.id}/like` | pages/index | ✅ |
| Comment Like (P1) | TODO — detail.vue评论列表是否有点赞按钮? | ? | 待检查 |

### ⚠️ 画廊模块 (API Section 8) — **完全缺失**
| API | UniApp 实现 | 状态 |
|-----|------------|------|
| GET /gallery | ❌ | ❌❌❌ 未实装 |
| POST /gallery | ❌ | ❌❌❌ 未实装 |
| DELETE /gallery/{id} | ❌ | ❌ |

### ✅ 好友关系 (API Section 9) — 完成度 ~50%
| API | UniApp 实现 | 所在页面 | 状态 |
|-----|------------|---------|------|
| GET /friends/list | ✅ profile.vue: `request('/friends/list')` 获取好友数 | pages/profile | ⚠️ 仅用于计数? |
| GET /friends/requests/pending | TODO | ? | ❌ |
| POST /friends/request | TODO | friend/search? | ⚠️ 待确认 |

### ✅ 通知模块 (API Section 10) — 完成度 ~100%
| API | UniApp 实现 | 所在页面 | 状态 |
|-----|------------|---------|------|
| GET /notifications/unread/count | home page 获取未读数 | pages/index | ✅ |
| POST /notifications/history | notification.vue | pages/notification | ✅ |
| GET /notifications/read-all | notification.vue | pages/notification | ✅ |
| POST /{id}/read | notification.vue | pages/notification | ✅ |

### ⚠️ 公告模块 (API Section 11) — **部分缺失**
- home/index.vue 首页获取公告信息: `GET /announcements` → ?
- 管理后台创建/编辑公告: **未实装**

### ❌ 徽章模块 (API Section 12) — **完全缺失** (0%)
| API | UniApp 实现 | 状态 |
|-----|------------|------|
| GET /badges/my/badges | ❌ | ❌ |
| POST /badges/{badgeId}/equip | ❌ | ❌ |
| POST /badges/{badgeId}/unequip | ❌ | ❌ |

### ⚠️ 举报模块 (API Section 13) — **部分缺失**
- 举报提交按钮: 在帖子的"..."菜单中应该有, 待确认是否实装
- GET /reports/my: ❌ 未实现

### ✅ 上传模块 (API Section 14) — 完成度 ~50%
- POST /users/avatar ✅ profile.vue
- POST /gallery ❌ 完全缺失 (上面已记录)

### ⚠️ 管理员工具箱 (API Section 15) — **极不完整**
- admin/admin.vue 页面存在但功能严重不足:
  - 帖子管理 (查看/删除帖子): ❌
  - 用户管理 (封禁/权限): ❌
  - 公告发布: ❌
  - 频道审核: 部分 (频道申请审批有逻辑在channel.vue)

### ⚠️ WebSocket实时通信 (API Section 16) — **完成度 ~80%**
- ✅ wsManager 核心框架已搭好
- ✅ 事件订阅: new_post, new_comment, new_like, new_message, message_read, **new_group_message**
- ✅ 私聊支持 type=1/2/3 多媒体消息
- ✅ 群聊实时消息推送
- ❌ **重大隐患**: 不支持 wss:// 协议 — 微信小程序生产环境必须用 wss，当前 baseUrl.replace('http','ws') 将 https→hwps (无效)

### ✅ 草稿箱模块 (API Section 17) — **完成度待确认**
- POST /drafts: create.vue 草稿保存逻辑?
- GET /drafts: 草稿列表?
- DELETE /drafts/{id}: ?
- 需要确认 pages/chat/detail 是否涉及此功能

### ✅ 群聊消息模块 (API Section 18) — 完成度 95%
| API | UniApp 实现 | 所在页面 | 状态 |
|-----|------------|---------|------|
| POST /group-messages | ✅ group-chat.vue: 文字/图片/视频消息发送 | pages/chat/group-chat | ✅ |
| GET /group-messages/{channelId} | ✅ group-chat.vue: 分页加载 + processImageUrl | pages/chat/group-chat | ✅ |
| DELETE /group-messages/{id} | ✅ group-chat.vue: 长按撤回 (仅自己消息) | pages/chat/group-chat | ✅ |
| WebSocket new_group_message | ✅ group-chat.vue: 实时推送追加消息 | pages/chat/group-chat | ✅ |
| 多媒体渲染 | ✅ `<image>` msgType=2, `<video>` msgType=3, 文本 msgType=1 | pages/chat/group-chat | ✅ |
| 入口 | ✅ channel.vue "群聊"按钮 + chat/list.vue 频道群聊列表 | pages/channel, chat/list | ✅ |

### ⚠️ 关注系统 (API Section 19) — **部分缺失** (P1 已全部完成)
| API | UniApp 实现 | 状态 |
|-----|------------|------|
| POST /follow/{userId}/toggle | TODO | ⚠️ 个人卡片关注按钮?待查 |
| GET /follow/feed | TODO | ❌ |
| GET /follow/{id}/followers | TODO | ❌ |
| GET /follow/{id}/following | TODO | ❌ |

---

## 十、技术细节汇总

### 1. 设计系统
- **配色**: 主色 `#7C9FCB` (蓝灰), 辅助 `#F2B5D4` (粉), 背景 `#0F1923`
- **UI风格**: Glassmorphism/Glass-card 效果 (`backdrop-filter: blur(20px)` + rgba半透明边框)
- **单位**: rpx 响应式, 750rpx = 屏幕宽度 (uni-app 标准)
- **字体**: iOS/Android 默认 font-family (无特殊定制)

### 2. WebSocket URL 构建逻辑 (关键路径)
```typescript
// utils/websocket.ts Line:40-46
const storedUrl = uni.getStorageSync('api_base_url')
const baseUrl = storedUrl || 'http://localhost:8080'
let wsUrl = baseUrl.replace('http', 'ws').replace('/api', '') + '/ws/raw'
```
⚠️ **注意**: `http` → `ws`, `https` → `hwps` (无效) — 小程序生产环境 HTTPS 会出错。

### 3. 认证流程
1. 用户登录 → POST /auth/login → 返回 `{token, userId, username, email, role, avatar}`
2. authStore.setAuth(token, userInfo) → 写入 uni.setStorageSync('auth_token') + uni.setStorageSync('user_info')
3. 后续请求: request.ts 自动读取 auth_token 附加到 Authorization header

### 4. 图片处理流程
1. API 返回: `/uploads/avatars/xxx.jpg` (相对路径)
2. processImageUrl() → `${BASE_URL}/uploads/avatars/xxx.jpg`
3. `<image :src="..." />` uni-app image 组件渲染

---

## 十一、严重问题清单

### P0 — 阻断类 (必须立即修复)

| # | 问题 | 影响范围 | 建议修复方案 |
|---|------|---------|------------|
| P0-1 | WebSocket URL 不支持 HTTPS → wss 转换 | **全应用实时通信** | websocket.ts: `let proto = baseUrl.startsWith('https') ? 'wss' : 'ws';` |
| P0-2 | UniApp 小程序必须用 wss（非 ws）——当前硬编码替换逻辑将 https→hwps | **生产环境聊天完全不可用** | 同P0-1 |
| P0-3 | package.json 中未列 pinia | **状态管理可能不生效** | yarn add pinia 或确认 uni-app alpha 内置 Pinia |

### P1 — 高优先级 (应在一周内完成)

| # | 问题 | 当前功能 | 建议修复方案 |
|---|------|---------|------------|
| P1-1 | PUT /users/profile 个人资料修改 — 设置页仅有 emailNotify 开关, **无用户名/电话更新** | 无法修改个人资料 | settings.vue + request PUT /users/profile |
| P1-2 | PUT /users/password 修改密码 — 完全缺失 | 无法改密 | settings.vue + request PUT /users/password |
| P1-3 | DELETE /posts/{id} 删除帖子 — 未实现 | 用户删贴功能 | post/detail.vue "..."菜单添加删除选项 |
| P1-4 | GET /posts/hot 热帖 — `GET /posts/search` 接口不明确 | 搜索/热帖可能走错API | 确认 API路径并实装 |
| P1-5 | follow feed / followers / following 页面完全缺失 | P1已后端完成, Uniapp端未跟进 | 新建关注动态页 + 粉丝/关注列表页 |

### P2 — 中优先级

| # | 问题 | 建议修复方案 |
|---|------|------------|
| P2-1 | 画廊模块 (Section 8) 完全缺失 | 新建 gallery/gallery.vue, 实现图片浏览/上传功能 |
| P2-2 | 徽章模块 (Section 12) 完全缺失 | 新增 badges/badges.vue 展示已装备徽章 |
| ~~P2-3~~ | ~~群聊功能 (Section 18)~~ | ✅ 已完成: group-chat.vue + WebSocket + 多媒体 |
| P2-4 | admin/admin.vue 管理面板严重不足 | 补齐: 帖子审核/删除/用户封禁/公告发布 |
| P2-5 | POST /auth/send-code 发送验证码未实现 | login/register 页加验证码入口 |

---

## 十二、加速补课建议 (P0 → sprint plan)

### Sprint 1 — 立即处理 (本周)
1. **修复 wsManager HTTPS→WSS** (30min) — websocket.ts 单文件修改
2. **补充 Pinia 依赖** (15min) — package.json
3. **PUT /users/profile + PUT /users/password** (2h) — settings.vue 补齐设置表单

### Sprint 2 — 一周内完成
4. **帖子删除功能** (1h) — post/detail.vue "..."菜单加 delete
5. **热帖/搜索接口确认与实装** (2h) — 对照 API文档 修正路径
6. **关注系统跟进** (3h) — user_profile + following feed/list 页面

### Sprint 3 — 两周补齐
7. **画廊模块** (4h) — gallery/page 创建 + CRUD
8. **徽章模块** (2h) — badges/展示页
9. **群聊功能** (6h) — group-chat/多端适配
10. **管理后台补全** (4h) — admin/帖子管理/用户管理/公告

---

## 十三、跨端一致性检查清单

| 模块 | UniApp | Flutter | PC Web | 三端一致? |
|------|--------|---------|--------|----------|
| 登录/注册 | ✅ | ✅ | ✅ | ✅ |
| 首页信息流 | ✅ | ✅ | ✅ | ✅ |
| 帖子列表/详情 | ✅ | ✅ | ✅ | ✅ |
| 频道管理 | ✅(部分) | ✅ | ✅ | ⚠️ UniApp缺创建页 |
| 私聊消息 | ✅(含图片/视频) | ✅ | ✅ | ✅ |
| 群聊消息 | ✅(文字/图片/视频) | ✅ | ✅ | ✅ |
| 好友系统 | ✅(部分) | ✅ | ? | ⚠️ UniApp待补 |
| 通知中心 | ✅ | ✅ | ✅ | ✅ |
| 个人中心 | ✅(关注/粉丝/收藏) | ✅ | ✅ | ✅ |
| 设置 | ✅(缺密码/资料) | ✅ | ✅ | ❌ UniApp缺2项 |
| 搜索 | ✅(帖子+频道) | ✅ | ✅ | ✅ |

---

**文档版本**: V2.0
**编写人**: Uniapp_MiniProgram Agent
**本次更新**: 补齐私聊图片/视频消息、群聊功能(文字/图片/视频+WebSocket)、收藏页、帖子搜索/编辑/浏览量、关注计数等
**下次更新**: Sprint 完成后同步更新完成状态
