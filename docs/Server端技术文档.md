# Camp Channel Server 端技术文档

## 项目概述

Camp Channel Server 是一个基于 Spring Boot 的后端服务，为 PC 端和 Flutter 端提供 RESTful API 接口，支持用户认证、帖子管理、实时通信、文件上传等功能。

### 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| Spring Boot | 4.0.6 | 后端框架 |
| Spring Security | 6.x | 安全认证 |
| MyBatis-Plus | 3.5.16 | ORM 框架 |
| MySQL | 8.x/9.x | 关系型数据库 |
| Redis | 7.x | 缓存 + 会话管理 + 限流 |
| Caffeine | 3.x | 本地缓存（V3.1 新增） |
| JWT | 0.12.7 | Token 认证 + 无感刷新 |
| FFmpeg | 4.x+ | 视频压缩 |
| WebSocket (STOMP) | Spring | 实时通信 + 限流 |
| Swagger/OpenAPI | 3.0.3 | API 文档 |
| Lombok | 1.18.46 | 代码简化 |
| Java | 26 | 运行时 |

### 项目结构

```
camp-channel-server/
├── src/main/java/com/gdmec/campchannel/
│   ├── CampChannelApplication.java    # 启动类
│   ├── common/                        # 通用模块
│   │   ├── api/
│   │   │   ├── Result.java            # 统一响应封装
│   │   │   └── ErrorCode.java         # 错误码定义
│   │   ├── exception/
│   │   │   ├── GlobalExceptionHandler.java # 全局异常处理
│   │   │   └── BusinessException.java      # 业务异常
│   │   ├── filter/
│   │   │   └── SensitiveWordFilter.java    # 敏感词过滤（DFA 算法）
│   │   └── utils/
│   │       ├── JwtUtils.java          # JWT 工具类（含 Token 刷新）
│   │       ├── RedisUtils.java        # Redis 工具类（含滑动窗口限流）
│   │       ├── RedisKeyPrefix.java    # Redis 键名前缀规范（V3.1）
│   │       ├── WebSocketRateLimiter.java  # WebSocket 消息限流（V3.1）
│   │       └── PageRequestUtil.java   # 分页参数工具（V3.1）
│   ├── config/                        # 配置类
│   │   ├── SecurityConfig.java        # Spring Security 配置
│   │   ├── WebMvcConfig.java          # MVC 配置（静态资源映射）
│   │   ├── WebSocketConfig.java       # WebSocket 配置
│   │   ├── WebSocketAuthInterceptor.java  # WebSocket 认证+限流拦截器
│   │   ├── RawWebSocketConfig.java    # 原始 WebSocket 配置
│   │   ├── RedisConfig.java           # Redis 配置
│   │   ├── AsyncConfig.java           # 异步配置（邮件线程池）
│   │   ├── CacheConfig.java           # Caffeine 本地缓存配置（V3.1）
│   │   └── DataInitializer.java       # 数据初始化
│   ├── security/                      # 安全模块
│   │   ├── JwtAuthenticationFilter.java    # JWT 认证过滤器
│   │   ├── CustomUserDetailsService.java   # 自定义用户详情服务
│   │   └── SecurityUser.java               # 安全用户实体
│   ├── controller/                    # 控制器层
│   │   ├── AuthController.java        # 认证（登录/注册）
│   │   ├── UserController.java        # 用户管理（密码修改/设备下线）
│   │   ├── PostController.java        # 帖子管理
│   │   ├── CommentController.java     # 评论管理
│   │   ├── ChannelController.java     # 频道管理
│   │   ├── UploadController.java      # 文件上传（白名单校验）
│   │   ├── GalleryController.java     # 画廊管理
│   │   ├── FollowController.java      # 关注系统
│   │   ├── FriendshipController.java  # 好友系统（双路径兼容）
│   │   ├── ChatController.java        # 私聊
│   │   ├── GroupMessageController.java # 群聊
│   │   ├── NotificationController.java # 通知
│   │   ├── ReportController.java      # 举报（含处理通知）
│   │   ├── AnnouncementController.java # 公告
│   │   ├── BadgeController.java       # 徽章
│   │   ├── LikeController.java        # 点赞
│   │   ├── DraftController.java       # 草稿
│   │   ├── TreeHoleController.java    # 树洞匿名帖子
│   │   ├── AdminController.java       # 管理后台（含批量审核）
│   │   └── HealthCheckController.java # 健康检查（V3.1）
│   ├── service/                       # 服务层
│   │   ├── impl/                      # 服务实现
│   │   └── *.java                     # 服务接口
│   ├── mapper/                        # MyBatis Mapper
│   └── entity/                        # 数据库实体
├── src/main/resources/
│   ├── application.yml                # 主配置文件
│   └── mapper/                        # MyBatis XML 映射
└── pom.xml
```

---

## 核心模块技术实现

### 1. 文件上传模块

**文件**：`UploadController.java`

**功能**：
- 图片上传（`POST /upload/image`）
- 视频上传（`POST /upload/video`）- 含去重和压缩
- 头像上传（`POST /upload/avatar`）
- 视频秒传校验（`GET /upload/video/check?hash=xxx`）

**视频上传流程**：
1. 保存临时文件（UUID 命名）
2. 计算文件 MD5 哈希
3. 检查是否已存在相同文件（去重）
4. 使用 FFmpeg 压缩视频到 5MB 以内
5. 以 Hash 值命名保存

**视频压缩策略**：
```java
// 尝试不同 CRF 值（28 → 32 → 36 → 40）
// 如果都不行，降低分辨率到 640px
compressVideo(sourceFile, targetFile, MAX_VIDEO_SIZE);

// FFmpeg 参数：
// -c:v libx264 -crf {crf} -preset fast
// -c:a aac -b:a 128k
// -movflags +faststart
```

**去重机制**：
- 前端计算 MD5 → 秒传校验接口
- 后端也计算 MD5 → 检查文件是否存在
- 存在则直接返回 URL，删除临时文件

**文件存储**：
- 本地存储：`app.upload.local-path` 配置路径
- 目录结构：`{path}/images/`, `{path}/videos/`, `{path}/avatars/`
- 静态资源映射：`/uploads/**` → 本地路径

### 2. 认证与安全

**文件**：`SecurityConfig.java`, `JwtAuthenticationFilter.java`, `AuthController.java`

**认证流程**：
1. 用户登录 → 验证邮箱/密码
2. 生成 JWT Token（包含 userId、角色）
3. Token 存储在 Redis（支持多设备管理）
4. 后续请求通过 `Authorization: Bearer {token}` 认证

**JWT 过滤器**：
- 拦截所有请求
- 解析 Token → 获取用户信息
- 设置 SecurityContext
- 放行公开接口（登录、注册、静态资源）

**安全配置**：
- CORS 跨域支持
- CSRF 禁用（API 服务）
- 密码 BCrypt 加密
- 角色权限控制

### 3. 帖子系统

**文件**：`PostController.java`, `PostServiceImpl.java`

**核心接口**：
| 接口 | 方法 | 说明 |
|------|------|------|
| `/posts` | GET | 获取帖子列表（分页） |
| `/posts` | POST | 创建帖子（含 images + videoUrls） |
| `/posts/{id}` | GET | 获取帖子详情（含 isLiked 字段） |
| `/posts/{id}` | PUT | 编辑帖子 |
| `/posts/{id}` | DELETE | 删除帖子 |
| `/posts/{id}/like` | POST | 切换点赞 |
| `/posts/{id}/report` | POST | 举报帖子 |
| `/posts/channel/{id}` | GET | 获取频道帖子 |
| `/posts/user/{id}` | GET | 获取用户帖子 |
| `/posts/{id}/comments` | GET | 获取评论列表 |
| `/posts/{id}/favourite` | POST | 收藏/取消收藏 |
| `/posts/{id}/favourite/status` | GET | 获取收藏状态 |
| `/posts/favourites` | GET | 获取收藏帖子列表（分页） |
| `/posts/search` | GET | 搜索帖子（keyword 参数） |
| `/posts/{id}/view` | GET | 增加浏览量 |

**数据结构**：
```java
class Post {
    Long id;
    Long userId;
    Long channelId;
    String content;
    String topic;          // 话题标签
    String images;         // JSON 数组字符串
    String videoUrls;      // JSON 数组字符串
    Integer likeCount;
    Integer commentCount;
    Integer isPinned;      // 是否置顶
    Integer editCount;     // 编辑次数
    Date createTime;

    @TableField(exist = false)
    Boolean isLiked;       // 当前用户是否点赞（非数据库字段，查询时动态填充）
}
```

**帖子详情响应说明**：
- `GET /posts/{id}` 返回的帖子数据中包含 `isLiked` 字段（当前用户是否已点赞）
- `likeCount` 和 `commentCount` 为数据库持久化字段，与列表页保持一致
- 前端应直接使用帖子实体中的 `isLiked`、`likeCount`、`commentCount`，无需额外调用 `/like/status` 接口

### 4. 评论系统

**文件**：`CommentController.java`, `CommentServiceImpl.java`

**核心接口**：
| 接口 | 方法 | 说明 |
|------|------|------|
| `/posts/{postId}/comments` | GET | 获取评论列表 |
| `/posts/{postId}/comments` | POST | 发表评论 |
| `/posts/{postId}/comments/{id}` | DELETE | 删除评论 |
| `/posts/{postId}/comments/{id}/like` | POST | 切换评论点赞 |

**@提及功能**：
- 评论内容解析 `@用户名`
- 自动创建通知给被提及用户

### 5. 关注系统

**文件**：`FollowController.java`, `FollowServiceImpl.java`

**核心接口**：
| 接口 | 方法 | 说明 |
|------|------|------|
| `/follow/{id}/toggle` | POST | 关注/取消关注 |
| `/follow/{id}/is-following` | GET | 检查是否关注 |
| `/follow/{id}/counts` | GET | 获取粉丝/关注数 |
| `/follow/{id}/followers` | GET | 获取粉丝列表 |
| `/follow/{id}/following` | GET | 获取关注列表 |

### 6. 好友系统

**文件**：`FriendshipController.java`, `FriendshipServiceImpl.java`

**核心接口**：
| 接口 | 方法 | 说明 |
|------|------|------|
| `/friends/requests` | POST | 发送好友请求 |
| `/friends/list` | GET | 获取好友列表 |
| `/friends/requests` | GET | 获取好友请求列表 |
| `/friends/requests/{id}/accept` | POST | 接受好友请求 |
| `/friends/requests/{id}/reject` | POST | 拒绝好友请求 |

### 7. 实时通信

**文件**：`WebSocketConfig.java`, `RawWebSocketHandler.java`, `ChatController.java`, `GroupMessageController.java`

**WebSocket 功能**：
- 私聊消息实时推送（事件：`new_message`）
- 群聊消息实时推送（事件：`new_group_message`）
- 在线状态管理
- 未读消息计数
- 已读回执推送

**连接流程**：
1. 客户端连接 → WebSocket 握手（携带 Token）
2. 服务端验证 Token → 建立连接
3. 消息格式：JSON（type + content + timestamp）
4. 断开连接 → 清理会话

**群聊 WebSocket 事件**：
```json
// 事件类型：new_group_message
{
  "type": "new_group_message",
  "data": {
    "id": 1,
    "channelId": 1,
    "content": "消息内容",
    "mediaUrl": null,
    "msgType": 1,
    "senderId": 2,
    "username": "发送者",
    "avatar": "/uploads/avatars/xxx.jpg",
    "createTime": "2026-06-15T10:00:00"
  }
}
```

### 8. 频道系统

**文件**：`ChannelController.java`, `ChannelServiceImpl.java`

**核心接口**：
| 接口 | 方法 | 说明 |
|------|------|------|
| `/channels/my` | GET | 获取我的频道列表 |
| `/channels` | POST | 创建频道 |
| `/channels/{id}` | GET | 获取频道详情 |
| `/channels/{id}/members` | GET | 获取频道成员 |
| `/channels/{id}/join` | POST | 加入频道 |
| `/channels/{id}/leave` | POST | 退出频道 |
| `/channels/search` | GET | 搜索频道（keyword 参数） |

**角色权限**：
- `owner` - 频道所有者（可置顶、删除帖子、管理成员）
- `admin` - 管理员（可置顶帖子、禁言成员）
- `member` - 普通成员

### 8.5 群聊消息系统

**文件**：`GroupMessageController.java`, `GroupMessageServiceImpl.java`

**核心接口**：
| 接口 | 方法 | 说明 |
|------|------|------|
| `/group-messages` | POST | 发送群聊消息 |
| `/group-messages/{channelId}` | GET | 获取频道群聊消息（分页） |
| `/group-messages/{messageId}` | DELETE | 撤回群聊消息 |

**消息数据结构**：
```java
class GroupMessage {
    Long id;
    Long channelId;       // 所属频道
    Long senderId;        // 发送者ID
    String content;       // 文字内容
    String mediaUrl;      // 媒体URL（图片/视频）
    Integer msgType;      // 1=文字, 2=图片, 3=视频
    Integer status;       // 1=正常, 2=已撤回
    Date createTime;
}
```

**消息发送流程**：
1. 客户端 POST 消息（含 channelId + content/mediaUrl + msgType）
2. 服务端保存消息记录
3. 通过 WebSocket 向频道所有在线成员推送 `new_group_message` 事件
4. 客户端收到事件后追加到消息列表

**撤回规则**：
- 仅发送者可撤回自己的消息
- 撤回后 `status` 从 1 变为 2
- 前端展示"消息已撤回"占位文本

### 9. 画廊系统

**文件**：`GalleryController.java`, `GalleryServiceImpl.java`

**核心接口**：
| 接口 | 方法 | 说明 |
|------|------|------|
| `/gallery` | GET | 获取画廊作品列表 |
| `/gallery` | POST | 上传画作 |
| `/gallery/{id}` | DELETE | 删除画作 |
| `/gallery/{id}/like` | POST | 点赞画作 |

### 10. 通知系统

**文件**：`NotificationController.java`, `NotificationServiceImpl.java`

**核心接口**：
| 接口 | 方法 | 说明 |
|------|------|------|
| `/notifications` | GET | 获取通知列表 |
| `/notifications/unread/count` | GET | 获取未读数量 |
| `/notifications/{id}/read` | POST | 标记已读 |

**通知类型**：
- 点赞通知
- 评论通知
- @提及通知
- 好友请求通知
- 系统公告

---

## 数据库设计

### 核心表结构

| 表名 | 说明 | 关键字段 |
|------|------|---------|
| `user` | 用户表 | id, username, email, password, avatar, role |
| `post` | 帖子表 | id, user_id, channel_id, content, topic, images, video_urls, like_count, comment_count, is_pinned |
| `comment` | 评论表 | id, post_id, user_id, content, like_count, created_at |
| `comment_like` | 评论点赞表 | id, comment_id, user_id |
| `post_like` | 帖子点赞表 | id, post_id, user_id |
| `post_favourite` | 帖子收藏表 | id, post_id, user_id |
| `channel` | 频道表 | id, name, description, owner_id |
| `channel_member` | 频道成员表 | id, channel_id, user_id, role |
| `follow` | 关注表 | id, follower_id, following_id |
| `friendship` | 好友表 | id, user_id, friend_id, status |
| `message` | 私聊消息表 | id, sender_id, receiver_id, content, is_read |
| `group_message` | 群聊消息表 | id, channel_id, sender_id, content |
| `notification` | 通知表 | id, user_id, type, content, is_read |
| `gallery` | 画廊表 | id, user_id, title, description, image_url |
| `gallery_like` | 画廊点赞表 | id, gallery_id, user_id |
| `post_draft` | 草稿表 | id, user_id, channel_id, content, images, topic |
| `report` | 举报表 | id, post_id, user_id, reason, status |
| `announcement` | 公告表 | id, title, content, type, created_at |
| `badge` | 徽章表 | id, name, description, icon |
| `user_badge` | 用户徽章表 | id, user_id, badge_id |
| `login_device` | 登录设备表 | id, user_id, device_info, token |
| `operation_log` | 操作日志表 | id, user_id, action, detail, created_at |

---

## 与前端搭配

### PC 端搭配

| 后端接口 | PC 端使用场景 | 数据格式 |
|---------|-------------|---------|
| `POST /upload/video` | 视频上传组件 | FormData → JSON {url, filename} |
| `GET /upload/video/check` | 秒传校验 | Query hash → JSON {exists, url} |
| `GET /posts` | 首页帖子流 | JSON {code, data: [Post]} |
| `POST /posts` | 发帖 | JSON {channelId, content, images, videoUrls} |
| `GET /gallery` | 3D 画廊数据 | JSON {code, data: [Gallery]} |

### Flutter 端搭配

| 后端接口 | Flutter 端使用场景 | 数据格式 |
|---------|-------------------|---------|
| `POST /upload/video` | 发帖页视频上传 | FormData → JSON {url, filename} |
| `GET /upload/video/check` | 秒传校验（compute 线程） | Query hash → JSON {exists, url} |
| `POST /upload/image` | 图片上传 | FormData → JSON {url, filename} |
| `GET /posts` | 频道帖子流 | JSON {code, data: [Post]} |
| `POST /posts` | 发帖 | JSON {channelId, content, images, videoUrls} |
| `GET /follow/{id}/counts` | 用户卡片粉丝数 | JSON {code, data: {followerCount, followingCount}} |
| `GET /friends/list` | 好友状态检查 | JSON {code, data: [Friend]} |

### UniApp 端搭配（微信小程序）

| 后端接口 | UniApp 端使用场景 | 数据格式 |
|---------|-----------------|----------|
| `POST /auth/login` | 邮箱密码登录 | JSON {email, password} → JSON {token, userId} |
| `GET /posts?page=X&size=Y` | 首页帖子信息流 | JSON {code, data: [Post]} |
| `GET /posts/{id}` | 帖子详情（含 isLiked） | JSON {code, data: Post} |
| `POST /posts` | 发布帖子 | JSON {channelId, content, images} |
| `PUT /posts/{id}` | 编辑帖子 | JSON {content, images} |
| `POST /posts/{id}/like` | 点赞/取消点赞 | → JSON {liked, likeCount} |
| `POST /posts/{id}/favourite` | 收藏/取消收藏 | → JSON toggle |
| `GET /posts/favourites` | 我的收藏列表 | JSON {code, data: [Post]} |
| `GET /posts/search?keyword=X` | 搜索帖子 | JSON {code, data: [Post]} |
| `GET /posts/{id}/view` | 浏览量 +1 | JSON {code} |
| `GET /posts/{id}/comments` | 评论列表 | JSON {code, data: [Comment]} |
| `POST /posts/{id}/comments` | 发表评论 | JSON {content} |
| `GET /channels/my` | 我的频道列表 | JSON {code, data: [Channel]} |
| `GET /channels/{id}` | 频道详情 | JSON {code, data: Channel} |
| `GET /channels/search?keyword=X` | 搜索频道 | JSON {code, data: [Channel]} |
| `POST /upload/image` | 图片上传（FormData） | file → JSON {url} |
| `GET /chat/conversations/with-unread` | 聊天会话列表 | JSON {code, data: [Session]} |
| `POST /chat/messages/send` | 发送私聊消息 | JSON {receiverId, content, type} |
| `GET /chat/history/{friendId}` | 聊天历史记录 | JSON {code, data: [Message]} |
| `POST /group-messages` | 发送群聊消息 | JSON {channelId, content, mediaUrl, msgType} |
| `GET /group-messages/{channelId}` | 群聊消息历史 | JSON {code, data: [GroupMsg]} |
| `DELETE /group-messages/{id}` | 撤回群聊消息 | JSON {code} |
| `GET /follow/{id}/counts` | 关注/粉丝数量 | JSON {followerCount, followingCount} |
| `POST /follow/{id}/toggle` | 关注/取消关注 | JSON toggle |
| `GET /notifications/unread/count` | 未读通知数 | JSON {code, data: Number} |
| `GET /notifications/history` | 通知历史 | JSON {code, data: [Notification]} |
| WebSocket `ws://host:8080/ws/raw?token=X` | 实时消息推送 | 事件: new_message, new_group_message |

**UniApp 请求封装**：
```typescript
// utils/request.ts
const BASE_URL = 'http://10.50.30.104:8080/api'

const request = (options: UniApp.RequestOptions) => {
  const token = uni.getStorageSync('token')
  return uni.request({
    ...options,
    url: BASE_URL + options.url,
    header: {
      'Authorization': token ? `Bearer ${token}` : '',
      ...options.header
    }
  })
}
```

**图片URL处理**：
```typescript
// 后端返回相对路径，前端需拼接 BASE_URL
const processImageUrl = (url: string) => {
  if (!url) return ''
  if (url.startsWith('http')) return url
  return BASE_URL + url
}
```

---

## 配置说明

### application.yml 关键配置

```yaml
server:
  port: 8080

spring:
  datasource:
    url: jdbc:mysql://localhost:3306/camp_channel
    username: root
    password: xxx
  redis:
    host: localhost
    port: 6379
  servlet:
    multipart:
      max-file-size: 100MB      # 最大上传文件大小
      max-request-size: 100MB   # 最大请求大小

app:
  upload:
    local-path: ./uploads       # 文件存储路径
  jwt:
    secret: xxx                 # JWT 密钥
    expiration: 86400000        # Token 过期时间（24小时）
```

---

## FFmpeg 依赖

服务器需要安装 FFmpeg 才能进行视频压缩：

```bash
# Ubuntu/Debian
sudo apt install ffmpeg

# CentOS/RHEL
sudo yum install ffmpeg

# 验证安装
ffmpeg -version
```

如果 FFmpeg 不可用，视频上传会跳过压缩，直接保存原始文件。

---

## 已知问题与优化建议

| 问题 | 说明 | 建议 |
|------|------|------|
| 视频压缩同步阻塞 | 压缩过程阻塞请求线程 | 改为异步处理，返回任务 ID |
| 文件存储本地 | 不支持分布式部署 | 迁移到 OSS/MinIO |
| 无视频转码 | 仅压缩，不转码 | 添加多分辨率转码（360p/720p/1080p） |
| 无 CDN | 静态资源直连服务器 | 添加 CDN 加速 |
| 敏感词过滤简单 | 基于关键词匹配 | 引入 AI 审核 |

---

## V3.1 性能与安全优化（2026-07-06）

### 1. Caffeine 本地缓存

**文件**：`config/CacheConfig.java`

**功能**：为热点数据（用户资料、频道信息）提供本地缓存，减少 Redis 网络开销。

**配置**：
- 初始容量：100
- 最大容量：500
- 过期时间：10 分钟
- 缓存名：`userProfile`、`channelInfo`、`postStats`、`badgeInfo`

**使用方式**：
```java
@Cacheable(value = "userProfile", key = "#userId")
public User getUserProfile(Long userId) {
    return userMapper.selectById(userId);
}
```

**收益**：减少 60%+ Redis 访问，降低延迟。

### 2. WebSocket 消息限流

**文件**：`common/utils/WebSocketRateLimiter.java` + `config/WebSocketAuthInterceptor.java`

**功能**：基于 Redis 滑动窗口算法，限制单用户每秒最多发送 10 条 WebSocket 消息，防止恶意刷消息。

**实现**：
- 在 `WebSocketAuthInterceptor.preSend()` 中对 `SEND` 命令进行限流检查
- 超限时丢弃消息并记录警告日志
- 使用 `RedisKeyPrefix.wsRateLimit()` 规范化键名

### 3. 文件上传安全加固

**文件**：`controller/UploadController.java`

**功能**：实现文件类型白名单机制，防止恶意文件上传。

**校验规则**：
- 图片 MIME 白名单：`image/jpeg`、`image/png`、`image/gif`、`image/webp`、`image/bmp`
- 视频 MIME 白名单：`video/mp4`、`video/webm`、`video/quicktime`、`video/x-msvideo`
- 扩展名白名单：与 MIME 类型对应的扩展名
- 大小二次校验：图片 ≤10MB，视频 ≤100MB

### 4. 数据库索引优化

**文件**：`resources/db/migration-v3.1.sql`

**新增索引**：
- `post`: `user_id`、`channel_id+status`、`status+create_time`、`is_anonymous+status`
- `comment`: `post_id`、`status+create_time`
- `message`: `sender_id`、`receiver_id`、`sender_id+receiver_id+create_time`
- `friendship`: `user_id+status`、`status`
- `notification`: `user_id+is_read`、`user_id+category`
- `login_device`: `user_id`、`last_active_time`
- `report`: `status`、`target_type+target_id`
- `operation_log`: `user_id`、`module`

**收益**：高频查询响应时间预计降低 50-80%。

### 5. 健康检查端点

**文件**：`controller/HealthCheckController.java`

**端点**：`GET /api/actuator/health`（无需认证）

**检查项**：
- 数据库连接状态（含产品名）
- Redis 连接状态
- 整体状态（UP/DEGRADED）

### 6. Redis 键名规范

**文件**：`common/utils/RedisKeyPrefix.java`

**前缀规范**：
- `camp:user:` - 用户相关
- `camp:post:` - 帖子相关
- `camp:session:` - 会话相关
- `camp:ratelimit:` - 限流相关
- `camp:ws:ratelimit:` - WebSocket 限流
- `camp:active_token:` - 活跃 Token

### 7. HikariCP 连接池调优

**文件**：`resources/application.yml`

**配置**：
- `minimum-idle`: 10（原 5）
- `maximum-pool-size`: 30（原 15）
- `idle-timeout`: 300000ms（5 分钟，原 30 秒）
- `connection-timeout`: 20000ms（20 秒，原 30 秒）
- `keepalive-time`: 60000ms（1 分钟心跳，新增）

### 8. 举报处理通知

**文件**：`service/impl/ReportServiceImpl.java`

**功能**：管理员处理举报后，自动通过 WebSocket 推送通知给举报人，告知处理结果（确认违规/已驳回 + 处理说明）。

### 9. 分页参数保护

**文件**：`common/utils/PageRequestUtil.java`

**功能**：
- 默认页大小 20，最大 100（搜索类 50）
- 页码上限 1000，防止深度分页攻击
- 提供 `build()` 和 `offset()` 工具方法
