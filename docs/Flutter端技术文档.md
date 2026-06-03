# Camp Channel Flutter 端技术文档

## 项目概述

Camp Channel Flutter 端是一个基于 Flutter/Dart 的跨平台移动端应用，支持 Android 和 iOS，与 PC 端功能保持一致。

### 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| Flutter | 3.x | 跨平台框架 |
| Dart | 3.x | 编程语言 |
| Dio | 5.x | HTTP 客户端 |
| Provider | 6.x | 状态管理 |
| ImagePicker | 1.x | 图片/视频选择 |
| Crypto | 3.x | MD5 哈希计算 |
| VideoPlayer | 2.x | 视频播放 |
| PermissionHandler | 11.x | 运行时权限 |
| SharedPrefs | 2.x | 本地存储 |
| WebSocketChannel | 3.x | 实时通信 |

### 项目结构

```
camp-channel-client-flutter/
├── lib/
│   ├── core/               # 核心模块
│   │   ├── network/
│   │   │   └── api_client.dart     # Dio 封装，统一 API 请求
│   │   └── services/
│   │       ├── storage_service.dart # 本地存储（SharedPreferences）
│   │       ├── user_provider.dart   # 用户状态管理（Provider）
│   │       ├── websocket_service.dart # WebSocket 实时消息
│   │       └── burst_service.dart   # 粒子爆发效果
│   ├── pages/              # 页面
│   │   ├── home_page.dart          # 首页（底部导航）
│   │   ├── channel_feed_page.dart  # 频道帖子流
│   │   ├── create_post_page.dart   # 发帖页面（支持图片+视频）
│   │   ├── post_detail_page.dart   # 帖子详情页
│   │   ├── gallery_upload_page.dart # 画廊上传页
│   │   ├── profile_page.dart       # 个人中心
│   │   └── ...
│   ├── widgets/            # 可复用组件
│   │   ├── post_card.dart          # 帖子卡片
│   │   ├── user_card.dart          # 用户信息卡片
│   │   ├── comment_widget.dart     # 评论组件
│   │   └── ...
│   ├── canvas/             # Canvas 动画效果
│   │   ├── canvas_effects.dart     # 流体背景、粒子系统
│   │   └── gallery_3d_carousel.dart # 3D 轮播图
│   └── main.dart           # 入口文件
├── pubspec.yaml            # 依赖配置
└── android/ / ios/         # 平台配置
```

---

## 核心功能技术实现

### 1. 视频上传

**技术方案：MD5 Hash + 秒传校验 + 后端压缩**

视频上传流程（与 PC 端一致）：
1. **文件选择**：使用 `ImagePicker.pickVideo()` 选择视频（最大 100MB）
2. **Hash 计算**：使用 `crypto` 包的 `md5.convert()` 计算文件 MD5
3. **秒传校验**：调用 `ApiClient.checkVideoExists(hash)` 检查文件是否已存在
4. **上传**：通过 `ApiClient.uploadFile('/upload/video', file)` 上传
5. **后端处理**：服务器使用 FFmpeg 自动压缩

**关键文件**：
- `lib/pages/create_post_page.dart` - 发帖页面，包含视频选择上传
- `lib/core/network/api_client.dart` - API 客户端，包含 `checkVideoExists()` 方法

**技术细节**：
```dart
// 使用 compute 在隔离线程计算 Hash，不阻塞 UI
Future<String> _calculateFileHash(File file) async {
  final hash = await compute(_hashFile, file.path);
  return hash;
}

static String _hashFile(String path) {
  final file = File(path);
  final bytes = file.readAsBytesSync();
  final digest = md5.convert(bytes);
  return digest.toString();
}
```

**媒体管理**：
- 使用 `MediaItem` 类统一管理图片和视频
- 支持最多 9 个媒体文件（图片+视频混合）
- 上传状态实时显示（计算指纹 → 检查秒传 → 上传中）

### 2. 3D 画廊

**技术方案：Flutter Transform + 数学投影**

3D 画廊是 PC 端 Three.js 版本的 Flutter 移植：

- **渲染**：使用 Flutter `Transform` + `Matrix4` 实现 3D 投影
- **布局**：圆柱面排列，半径 180px
- **交互**：拖拽旋转、惯性滑动、自动旋转
- **视频支持**：支持视频项显示（播放图标覆盖）

**关键文件**：
- `lib/canvas/gallery_3d_carousel.dart`

**Gallery3DItem 数据结构**：
```dart
class Gallery3DItem {
  final int id;
  final String imageUrl;
  final String? videoUrl; // 视频 URL，存在则为视频项
  final String? title;
  final String? username;
  
  bool get isVideo => videoUrl != null && videoUrl!.isNotEmpty;
}
```

### 3. 帖子系统

**帖子卡片**（`lib/widgets/post_card.dart`）：
- 支持图片网格显示（1-9 张自适应布局）
- 支持视频网格显示（最多 4 个，16:9 比例）
- 点赞动画、评论计数
- 置顶标识

**帖子详情页**（`lib/pages/post_detail_page.dart`）：
- 完整帖子内容展示
- 图片/视频网格 + 点击预览
- 评论列表 + @提及
- 点赞、收藏、举报、删除操作
- 编辑帖子（传递图片和视频 URL）

**发帖页**（`lib/pages/create_post_page.dart`）：
- 频道选择
- 内容编辑（话题 #、@提及）
- 图片上传（多选，最大 1920px，质量 85%）
- 视频上传（单选，Hash 计算 + 秒传 + 后端压缩）
- 草稿保存

### 4. 用户系统

**用户信息卡片**（`lib/widgets/user_card.dart`）：
- 头像展示 + 点击预览
- 关注/取消关注
- 好友状态检查
- 粉丝/关注数
- 用户帖子列表
- 私聊入口

**个人中心**：
- 头像上传
- 资料编辑
- 我的帖子/收藏

### 5. 实时通信

**WebSocket 服务**（`lib/core/services/websocket_service.dart`）：
- 自动连接/重连
- 消息接收处理
- 未读消息计数

### 6. 视觉效果

**Canvas 动画**（`lib/canvas/canvas_effects.dart`）：
- 流体动画背景（FluidBackground）
- 粒子系统 + 连线（ParticleSystemWidget）
- 天气效果（WeatherEffectsOverlay）
- 粒子爆发效果（ParticleBurstService）

**Shader 卡片**：
- 玻璃态效果（MoodMode.glass）
- 故障效果（MoodMode.glitch）

### 7. API 通信

**技术方案：Dio 封装**

- `lib/core/network/api_client.dart` - 统一 API 客户端
- 自动附加 Bearer Token
- 统一错误处理
- 图片 URL 处理（`processImageUrl()`）

**核心方法**：
```dart
// GET 请求
Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters})

// POST 请求
Future<Response<T>> post<T>(String path, {dynamic data})

// 文件上传
Future<Response<T>> uploadFile<T>(String path, File file, {String fieldName = 'file'})

// 视频秒传校验
Future<Map<String, dynamic>?> checkVideoExists(String hash)
```

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
| 发布帖子 | `POST /api/posts` | 创建新帖子（含 images + videoUrls） |
| 编辑帖子 | `PUT /api/posts/{id}` | 更新帖子 |
| 删除帖子 | `DELETE /api/posts/{id}` | 删除帖子 |
| 点赞 | `POST /api/posts/{id}/like` | 切换点赞状态 |
| 评论列表 | `GET /api/posts/{id}/comments` | 获取评论 |
| 评论点赞 | `POST /api/posts/{id}/comments/{cid}/like` | 切换评论点赞 |
| 收藏状态 | `GET /api/posts/{id}/favourite/status` | 获取收藏状态 |
| 关注状态 | `GET /api/follow/{id}/is-following` | 检查是否关注 |
| 关注计数 | `GET /api/follow/{id}/counts` | 获取粉丝/关注数 |
| 关注切换 | `POST /api/follow/{id}/toggle` | 关注/取消关注 |
| 好友列表 | `GET /api/friends/list` | 获取好友列表 |
| 好友请求 | `POST /api/friends/requests` | 发送好友请求 |
| 画廊列表 | `GET /api/gallery` | 获取画廊作品 |
| 画廊上传 | `POST /api/gallery` | 上传画作到画廊 |
| 我的频道 | `GET /api/channels/my` | 获取用户频道列表 |
| 通知未读 | `GET /api/notifications/unread/count` | 获取未读通知数 |
| 用户资料 | `GET /api/users/profile` | 获取当前用户资料 |
| 用户帖子 | `GET /api/posts/user/{id}` | 获取用户帖子列表 |

---

## 与 PC 端功能对比

| 功能 | PC 端 | Flutter 端 | 状态 |
|------|-------|-----------|------|
| 文字发帖 | ✅ | ✅ | 一致 |
| 图片上传 | ✅ | ✅ | 一致 |
| 视频上传 | ✅ | ✅ | 一致 |
| 视频秒传 | ✅ | ✅ | 一致 |
| 后端压缩 | ✅ | ✅ | 一致 |
| 3D 画廊 | ✅ (Three.js) | ✅ (Transform) | 一致 |
| 画廊视频 | ✅ | ✅ | 一致 |
| 帖子详情 | ✅ | ✅ | 一致 |
| 视频预览 | ✅ | ✅ | 一致 |
| 评论系统 | ✅ | ✅ | 一致 |
| 用户卡片 | ✅ | ✅ | 一致 |
| 关注系统 | ✅ | ✅ | 一致 |
| 好友系统 | ✅ | ✅ | 一致 |
| 私聊 | ✅ | ✅ | 一致 |
| 通知 | ✅ | ✅ | 一致 |
| 主题切换 | ✅ | ✅ | 一致 |
| 粒子效果 | ✅ | ✅ | 一致 |
| 流体背景 | ✅ | ✅ | 一致 |
| 草稿保存 | ✅ | ✅ | 一致 |
| 帖子置顶 | ✅ | ✅ | 一致 |
| 帖子收藏 | ✅ | ✅ | 一致 |
| 帖子举报 | ✅ | ✅ | 一致 |
| 帖子编辑 | ✅ | ✅ | 一致 |
| 画廊上传 | ✅ | ✅ | 一致 |
| 搜索 | ✅ | ✅ | 一致 |
| 热门帖子 | ✅ | ✅ | 一致 |
| 关注流 | ✅ | ✅ | 一致 |
| 树洞 | ✅ | ✅ | 一致 |
| 群聊 | ✅ | ✅ | 一致 |
| 公告系统 | ✅ | ✅ | 一致 |

---

## 已知问题与修复记录

| 问题 | 原因 | 修复方案 |
|------|------|---------|
| 缺少视频上传 | 仅支持图片 | 添加视频选择、Hash 计算、秒传校验、后端压缩上传 |
| 3D 画廊不支持视频 | Gallery3DItem 无 videoUrl 字段 | 添加 videoUrl 字段和 isVideo 判断 |
| 帖子详情不显示视频 | 仅解析 images 字段 | 添加 videoUrls 解析和网格显示 |
| PostCard 不显示视频 | 无 videoUrls 参数 | 添加 videoUrls 参数和视频网格组件 |
