# Camp Channel PC 端技术文档

> 版本：V3.1
> 最后更新：2026-07-06
> 状态：V3.1 性能与体验优化已完成

## 项目概述

Camp Channel PC 端是一个基于 Vue 3 + TypeScript 的桌面端校园社交平台客户端，采用现代化的 SPA 架构。

### 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| Vue.js | 3.x | 前端框架 |
| TypeScript | 5.x | 类型安全 |
| Vite | 5.x | 构建工具（V3.1 启用代码分割与压缩优化） |
| Pinia | 2.x | 状态管理 |
| Vue Router | 4.x | 路由管理 |
| Three.js | 0.160+ | 3D 画廊渲染 |
| FFmpeg.wasm | 0.12+ | 前端视频处理（已废弃） |
| SparkMD5 | 3.x | 文件 Hash 计算 |
| Axios | 1.x | HTTP 请求 |
| TailwindCSS | 3.x | CSS 框架 |
| ESBuild | 0.20+ | V3.1 生产构建压缩器 |

### 项目结构

```
camp-channel-client-pc/
├── src/
│   ├── api/              # API 请求层
│   │   └── client.ts     # Axios 封装，统一处理认证、Token 刷新与错误
│   ├── components/       # Vue 组件
│   │   ├── NavSidebar.vue      # 左侧导航栏
│   │   ├── PostCard.vue        # 帖子卡片
│   │   ├── Post3DViewer.vue    # 3D 画廊查看器
│   │   ├── SmartVideoUploader.vue # 视频上传组件
│   │   ├── UserCard.vue        # 用户信息卡片
│   │   ├── SearchResultHighlight.vue # 搜索结果高亮（V3.1 新增）
│   │   ├── PostSkeleton.vue    # 帖子骨架屏（V3.1 新增）
│   │   ├── BrowserCompatCheck.vue # 浏览器兼容性检测（V3.1 新增）
│   │   └── ...
│   ├── composables/      # 组合式函数
│   │   ├── useVideoUploader.ts # 视频上传逻辑
│   │   ├── useFormValidation.ts # 统一表单校验（V3.1 新增）
│   │   ├── useErrorHandler.ts  # 统一错误处理（V3.1 新增）
│   │   └── useSEO.ts           # SEO 元信息管理（V3.1 新增）
│   ├── canvas/           # Canvas/Three.js 渲染
│   │   └── Post3DGallery.ts    # 3D 轮播图实现
│   ├── stores/           # Pinia 状态管理
│   │   └── themeStore.ts       # 主题管理
│   ├── views/            # 页面视图
│   └── router/           # 路由配置（含 requiresAdmin 守卫）
├── public/               # 静态资源
├── vite.config.ts        # Vite 配置（V3.1 启用代码分割）
└── package.json
```

---

## 核心功能技术实现

### 1. 视频上传

**技术方案：前端 Hash 计算 + 后端压缩**

视频上传流程：
1. **文件选择**：用户选择视频文件（最大 100MB）
2. **Hash 计算**：使用 `SparkMD5` 分片计算文件 MD5（2MB 分片，不阻塞主线程）
3. **秒传校验**：调用 `GET /api/upload/video/check?hash=xxx` 检查文件是否已存在
4. **上传**：通过 `POST /api/upload/video` 上传原始视频
5. **后端处理**：服务器使用 FFmpeg 自动压缩视频到 5MB 以内

**关键文件**：
- `src/composables/useVideoUploader.ts` - 视频上传组合式函数
- `src/components/SmartVideoUploader.vue` - 视频上传 UI 组件

**技术细节**：
```typescript
// Hash 计算采用分片读取，避免大文件阻塞
function calculateFileHash(file: File, chunkSize = 2 * 1024 * 1024): Promise<string> {
  // 使用 FileReader 分片读取
  // 进度 = (已读分片 / 总分片) * 50%
}

// 上传使用 XMLHttpRequest 监听进度
// 总进度 = Hash(50%) + 上传(50%)
```

**去重机制**：
- 前端计算 MD5 → 后端秒传校验 → 如存在则直接返回 URL
- 后端也会计算 MD5 进行二次去重

### 2. 3D 画廊

**技术方案：Three.js + UV 坐标翻转**

3D 画廊使用 Three.js 实现旋转木马效果：

- **渲染**：Three.js WebGL 渲染器
- **布局**：圆柱面排列，半径 180px
- **交互**：鼠标拖拽旋转、点击选中、自动旋转
- **图片方向**：通过 UV 坐标翻转确保图片在顶部时显示正向

**关键文件**：
- `src/canvas/Post3DGallery.ts` - Three.js 3D 场景实现
- `src/components/Post3DViewer.vue` - Vue 包装组件

**UV 翻转实现**（解决镜像问题）：
```typescript
// 不使用 mesh.scale.x = -1（会导致不一致）
// 改为翻转 UV 坐标
const uvAttr = geo.attributes.uv
for (let i = 0; i < uvAttr.count; i++) {
  uvAttr.setXY(i, 1 - uvAttr.getX(i), uvAttr.getY(i))
}
```

### 3. 主题系统

**技术方案：Pinia 状态管理 + CSS 变量**

- 主题配置存储在 Pinia store 中
- 支持亮色/暗色模式切换
- 主题属性：`primary`、`secondary`（注意：不是 `accent`）

**关键文件**：
- `src/stores/themeStore.ts`

### 4. 用户系统

**用户信息卡片**：
- `src/components/UserCard.vue` - 显示用户资料、帖子列表
- 使用 `watch` 监听 `userId` 和 `visible` 变化，自动刷新数据

**左侧导航栏**：
- `src/components/NavSidebar.vue` - 用户头像、频道列表
- CSS 使用 `box-sizing: border-box` + `overflow: hidden` 防止头像溢出

### 5. API 通信

**技术方案：Axios 封装**

- `src/api/client.ts` - 统一 API 客户端
- 自动附加 Bearer Token
- 统一错误处理
- 请求/响应拦截器

---

## 与后端搭配

| 前端功能 | 后端接口 | 说明 |
|---------|---------|------|
| 视频上传 | `POST /api/upload/video` | 上传视频，后端自动压缩 |
| 视频秒传校验 | `GET /api/upload/video/check?hash=xxx` | 检查文件是否已存在 |
| 图片上传 | `POST /api/upload/image` | 上传图片 |
| 头像上传 | `POST /api/upload/avatar` | 上传头像 |
| 帖子列表 | `GET /api/posts` | 获取全部帖子 |
| 频道帖子 | `GET /api/posts/channel/{id}` | 获取指定频道帖子 |
| 发布帖子 | `POST /api/posts` | 创建新帖子 |
| 点赞 | `POST /api/posts/{id}/like` | 切换点赞状态 |
| 评论 | `GET /api/posts/{id}/comments` | 获取评论列表 |
| 画廊列表 | `GET /api/gallery` | 获取画廊作品 |

---

## 已知问题与修复记录

| 问题 | 原因 | 修复方案 |
|------|------|---------|
| 视频上传重复 | `onUploaded` 被调用两次（emit + props） | 移除冗余的 `props.onUploaded?.(url)` |
| 3D 画廊图片镜像 | 使用 `mesh.scale.x = -1` 导致不一致 | 改为 UV 坐标翻转 |
| TypeScript 类型错误 | 使用 `theme.accent` 但类型定义为 `secondary` | 替换为 `theme.secondary` |
| 导航栏头像溢出 | padding 未计入布局计算 | 添加 `box-sizing: border-box` + `overflow: hidden` |
| UserCard 不刷新 | 仅在 mount 时获取数据 | 添加 `watch` 监听 props 变化 |
| Token 过期白屏 | 无感刷新未实现 | `api/client.ts` 实现请求队列 + 自动刷新 |
| 路由权限绕过 | 缺少后台守卫 | `router/index.ts` 添加 `requiresAdmin` 守卫 |
| WebSocket 资源泄漏 | 订阅未清理 | `ChatPage.vue` 在 onUnmounted 中清理订阅 |
| 帖子类型字段缺失 | Post/Comment 接口不完整 | `types/index.ts` 补齐所有字段 |

---

## V3.1 性能与体验优化

V3.1 版本围绕《Camp_Channel_Bug_Analysis_And_Optimization_Plan.md》中标记的 Vue PC 端 P1/P2 问题进行系统性优化，覆盖代码分割、表单校验、错误处理、SEO、骨架屏、搜索高亮与浏览器兼容性等关键场景。

### 1. Vite 构建优化（ISSUE-V-P1-002）

**文件**：`vite.config.ts`

**问题**：原构建未做代码分割，首屏一次性加载全部依赖（vue、vue-router、pinia、@stomp/stompjs、sockjs-client），首屏体积过大，加载时间过长。

**优化方案**：
```typescript
build: {
  rollupOptions: {
    output: {
      manualChunks: {
        'vue-vendor': ['vue', 'vue-router', 'pinia'],
        'stomp-vendor': ['@stomp/stompjs', 'sockjs-client'],
      },
      chunkFileNames: 'assets/js/[name]-[hash].js',
      entryFileNames: 'assets/js/[name]-[hash].js',
      assetFileNames: 'assets/[ext]/[name]-[hash].[ext]',
    },
  },
  chunkSizeWarningLimit: 1000,  // 大型 SPA 必然有较大块
  cssCodeSplit: true,            // 启用 CSS 代码分割
  minify: 'esbuild',             // ESBuild 压缩，比 terser 更快
}
```

**收益**：
- Vue 核心库独立成 `vue-vendor` chunk，可被浏览器长期缓存
- STOMP/WebSocket 依赖独立成 `stomp-vendor` chunk，仅聊天页加载
- CSS 按页分割，首屏仅加载当前页样式
- ESBuild 压缩相比 terser 构建速度提升 20%~40%

### 2. 统一表单校验（ISSUE-V-P1-003）

**文件**：`src/composables/useFormValidation.ts`

**问题**：各页面（登录、注册、发帖、修改资料）各自实现校验逻辑，规则不一致、维护成本高。

**方案**：抽取为通用 composable，提供统一校验器集合。

```typescript
const { form, errors, validateAll, validateField } = useFormValidation({
  email: '',
  username: '',
  password: '',
}, {
  email: [validateEmail],
  username: [validateRequired, validateUsername, validateMinLength(3), validateMaxLength(20)],
  password: [validateRequired, validateMinLength(8)],
});
```

**内置校验器**：`validateEmail`、`validateUsername`、`validatePassword`、`validatePhone`、`validateRequired`、`validateMinLength(n)`、`validateMaxLength(n)`。

### 3. 统一错误处理（ISSUE-V-P1-005）

**文件**：`src/composables/useErrorHandler.ts`

**问题**：HTTP 错误码直接透传到 UI，用户看到 "500 Internal Server Error" 等不友好提示。

**方案**：将 HTTP 状态码映射为用户可理解的友好消息。

```typescript
const { handleError, handleSuccess, handleWarning, setToastHandler } = useErrorHandler();

try {
  await api.createPost(payload);
  handleSuccess('发布成功');
} catch (e) {
  handleError(e);  // 自动识别 400/401/403/404/429/500/502-504 给出友好提示
}
```

**状态码映射**：
| HTTP 状态 | 友好提示 |
|----------|---------|
| 400 | 请求参数有误，请检查后重试 |
| 401 | 登录已过期，请重新登录 |
| 403 | 没有权限执行此操作 |
| 404 | 请求的资源不存在 |
| 429 | 操作过于频繁，请稍后再试 |
| 500 | 服务器开小差了，请稍后重试 |
| 502/503/504 | 网络异常，请检查网络连接 |

### 4. 搜索结果高亮（ISSUE-V-P1-006）

**文件**：`src/components/SearchResultHighlight.vue`

**问题**：搜索结果直接展示原文，关键词未突出，用户难以快速定位匹配内容。

**方案**：使用正则分割文本，对匹配部分用 `<mark>` 标签包裹，支持自定义高亮类名。

```vue
<SearchResultHighlight
  :text="post.content"
  :keyword="searchKeyword"
  highlight-class="search-highlight"
/>
```

**实现要点**：
- 转义关键词中的正则特殊字符，避免注入
- 使用 computed 缓存分割结果，避免重复计算
- 支持暗色模式（通过 CSS 变量）

### 5. 帖子骨架屏（ISSUE-V-P2-001）

**文件**：`src/components/PostSkeleton.vue`

**问题**：帖子列表加载时显示空白或简单的 "加载中..."，体验突兀。

**方案**：Shimmer 动画骨架屏，模拟帖子卡片的头像、标题、内容、图片占位。

```vue
<PostSkeleton v-if="loading" />
<PostCard v-else v-for="post in posts" :key="post.id" :post="post" />
```

**实现要点**：
- `@keyframes shimmer` 通过 background-position 平移实现微光流动
- 布局与真实 PostCard 完全一致，避免抖动
- 支持 `@media (prefers-color-scheme: dark)` 暗色模式

### 6. 浏览器兼容性检测（ISSUE-V-P2-002）

**文件**：`src/components/BrowserCompatCheck.vue`

**问题**：低版本浏览器（如 IE、旧版 Edge、Safari < 14）缺少必要 API，页面直接白屏且无任何提示。

**方案**：应用启动时检测关键 API，缺失则展示升级提示。

**检测项**：
- `fetch` / `Promise` / `WebSocket`
- `localStorage` / `Map` / `Set`
- `Array.from` / `IntersectionObserver`

```vue
<BrowserCompatCheck v-if="!compatChecked" @checked="onChecked" />
```

### 7. SEO 元信息管理（ISSUE-V-P2-003）

**文件**：`src/composables/useSEO.ts`

**问题**：SPA 单一 HTML，所有页面共用相同 title/meta，搜索引擎无法区分页面。

**方案**：在路由切换时动态更新 document.title 与 meta 标签，支持 Open Graph。

```typescript
const { setTitle, setMetaDescription, setMetaKeywords, setOGTags } = useSEO();

setTitle('帖子详情 - Camp Channel');
setMetaDescription('查看校园频道精彩帖子');
setOGTags({ title: '...', description: '...', image: '...' });
```

**实现要点**：
- `initSEO()` 保存原始 head 状态，路由离开时 `restoreSEO()` 还原
- 支持 keywords、description、og:title、og:description、og:image

---

## V3.1 修复实施清单

| 编号 | 优先级 | 问题 | 状态 |
|------|--------|------|------|
| ISSUE-V-P1-002 | P1 | 首屏加载缓慢 | ✅ 已修复（Vite 代码分割） |
| ISSUE-V-P1-003 | P1 | 表单校验逻辑分散 | ✅ 已修复（useFormValidation） |
| ISSUE-V-P1-005 | P1 | 错误提示不友好 | ✅ 已修复（useErrorHandler） |
| ISSUE-V-P1-006 | P1 | 搜索无高亮 | ✅ 已修复（SearchResultHighlight） |
| ISSUE-V-P2-001 | P2 | 加载状态体验差 | ✅ 已修复（PostSkeleton） |
| ISSUE-V-P2-002 | P2 | 低版本浏览器白屏 | ✅ 已修复（BrowserCompatCheck） |
| ISSUE-V-P2-003 | P2 | SEO 缺失 | ✅ 已修复（useSEO） |

---

**文档版本**：V3.1
**本次更新**：补充 V3.1 性能与体验优化章节，记录代码分割、表单校验、错误处理、搜索高亮、骨架屏、浏览器兼容、SEO 等优化项
