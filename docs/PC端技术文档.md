# Camp Channel PC 端技术文档

## 项目概述

Camp Channel PC 端是一个基于 Vue 3 + TypeScript 的桌面端校园社交平台客户端，采用现代化的 SPA 架构。

### 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| Vue.js | 3.x | 前端框架 |
| TypeScript | 5.x | 类型安全 |
| Vite | 5.x | 构建工具 |
| Pinia | 2.x | 状态管理 |
| Vue Router | 4.x | 路由管理 |
| Three.js | 0.160+ | 3D 画廊渲染 |
| FFmpeg.wasm | 0.12+ | 前端视频处理（已废弃） |
| SparkMD5 | 3.x | 文件 Hash 计算 |
| Axios | 1.x | HTTP 请求 |
| TailwindCSS | 3.x | CSS 框架 |

### 项目结构

```
camp-channel-client-pc/
├── src/
│   ├── api/              # API 请求层
│   │   └── client.ts     # Axios 封装，统一处理认证和错误
│   ├── components/       # Vue 组件
│   │   ├── NavSidebar.vue      # 左侧导航栏
│   │   ├── PostCard.vue        # 帖子卡片
│   │   ├── Post3DViewer.vue    # 3D 画廊查看器
│   │   ├── SmartVideoUploader.vue # 视频上传组件
│   │   ├── UserCard.vue        # 用户信息卡片
│   │   └── ...
│   ├── composables/      # 组合式函数
│   │   └── useVideoUploader.ts # 视频上传逻辑
│   ├── canvas/           # Canvas/Three.js 渲染
│   │   └── Post3DGallery.ts    # 3D 轮播图实现
│   ├── stores/           # Pinia 状态管理
│   │   └── themeStore.ts       # 主题管理
│   ├── views/            # 页面视图
│   └── router/           # 路由配置
├── public/               # 静态资源
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
