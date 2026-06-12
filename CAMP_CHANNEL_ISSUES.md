# Camp Channel 全栈项目 Issue 追踪文档

**创建时间**: 2026-06-10  
**负责人**: 项目负责人（技术总监）  
**版本**: V3.0  

---

## 使用说明

| 状态 | 说明 |
|------|------|
| `待处理` | 尚未开始修复 |
| `修复中` | 对应子Agent已开始修复（仅用于内部跟踪，由项目负责人变更） |
| `等待验证` | 子Agent声称已修复，等待项目负责人检查确认 |
| `已解决` | 项目负责人验证通过，问题确认为解 |
| `待讨论` | 需要项目经理决策的技术方向 |

### Issue ID编号规则
- `BP0-XXX`: Backend P0 级别  
- `VP0-XXX`: Vue Frontend P0 级别  
- `FP0-XXX`: Flutter Mobile P0 级别  
- `UP0-XXX`: UniApp MiniProgram P0 级别  
- `V1/V2/F1...` 同理为各自模块的P1/P2级别

---

## ==================== 🔴 后端 Issues (Backend_Dev) ====================

### BP0-001 [API路径] PUT /api/users/profile 接口路径不匹配
**状态**: 待讨论  
**优先级**: P0（阻断）

**问题描述**:  
- API文档定义个人资料更新为 `PUT /api/users/profile`，且字段为 `username`, `realName`, `phone`
- 代码中实际实现为 `PUT /users/me`，字段不匹配
- 前端同时使用 `/users/me` 和 `/users/profile` 两种方式调用

**后端建议修改**:  
统一到文档规范的 `PUT /api/users/profile`，确保请求体包含 `username`, `realName`, `phone` 字段。

---

### BP0-002 [API路径] PUT /api/users/password vs PUT /users/change-password
**状态**: 待讨论  
**优先级**: P1  

**问题描述**:  
- API文档定义密码修改为 `PUT /api/users/password`
- 代码中实际实现为 `POST /users/change-password`（HTTP方法错误+路径错误）

**后端建议修改**:  
改为 `PUT /api/users/password`，请求体包含 `oldPassword`, `newPassword`。

---

### BP0-003 [API路径] 设备下线接口多端不统一
**状态**: 待讨论  
**优先级**: P1  

**问题描述**:  
- API文档定义：`DELETE /api/users/devices/{deviceId}`
- 代码实现为 `POST /logout-device`（全局） + `POST /devices/{deviceId}/logout`（指定设备）
- HTTP方法错误，端点位置不一致

---

### BP0-004 [功能缺失] GET /admin/stats 不存在
**状态**: 待处理  
**优先级**: P1  

**问题描述**:  
PC端 admin.vue 调用 `GET /admin/stats` 获取统计数据，但后端无此端点，返回404。

---

### BP0-005 [功能缺失] GET /admin/posts/pending 不存在
**状态**: 待处理  
**优先级**: P1  

**问题描述**:  
PC端 admin.vue 调用 `GET /admin/posts/pending` 待审核帖子列表，后端无此端点。

---

### BP0-006 [功能缺失] GET /admin/channels 不存在
**状态**: 待处理  
**优先级**: P1  

**问题描述**:  
PC端 admin.vue 调用 `GET /admin/channels` 管理频道列表，后端无此端点。

---

### BP0-007 [功能缺失] POST /api/admin/announcements vs POST /admin/announcement
**状态**: 待讨论  
**优先级**: P1  

**问题描述**:  
AdminController 和 AnnouncementController 各有一个发布/接收公告的端点，逻辑可能不一致。需要统一或明确各自职责。

---

### BP0-008 [功能缺失] POST /api/admin/users/{userId}/status
**状态**: 待讨论  
**优先级**: P1  

**问题描述**:  
代码中 admin.vue 使用 PUT，但 API文档定义可能为 POST。需确认并统一。

---

### BP0-009 [功能缺失] GET /admin/logs (操作日志) 不存在
**状态**: 待处理  
**优先级**: P2  

**问题描述**:  
管理后台需要查询操作日志的功能，但无对应端点。operation_log表存在但有接口吗？需确认并补充。

---

## ==================== 💻 Vue Frontend Issues ====================

### VP0-001 [数据类型] Post 接口缺失关键字段
**状态**: 待处理  
**优先级**: P0（阻断）  

**问题描述**:  
`src/types/index.ts` 中 Post 类型定义不完整，导致大量手动映射和类型丢失：

| 字段 | 说明 | 使用位置 |
|------|------|---------|
| `isPinned: boolean` | 是否置顶 | HomePage, PostDetailPage |
| `isLiked: boolean` | 是否已点赞 | PostCard, UI层 |
| `isFavourited: boolean` / `favouriteCount: number` | 收藏状态/数量 | FavouritesPage, PostDetailPage |
| `editCount: number` | 编辑次数 | PostDetailPage（显示"已编辑"标签） |
| `lastEditTime: string` | 最后编辑时间 | PostDetailPage |
| `imagesUrls: string[]` / `videoUrls: string[]` | VS images/videoUrl | 后端返回数组，前端用字符串映射 |

**修复方案**:  
修改 `src/types/index.ts` 中 Post 类型定义，新增上述字段。确保与API返回数据完全匹配。

---

### VP0-002 [数据类型] Comment 接口缺失关键字段
**状态**: 待处理  
**优先级**: P0（阻断）  

**问题描述**:  
Comment 类型只有 `content`/`parentId`/`status`，缺少：
| 字段 | 说明 |
|------|------|
| `username: string` | 评论者用户名 |
| `avatar: string` | 评论者头像 |
| `likeCount: number` | 点赞数 |
| `isLiked: boolean` | 是否已点赞 |

---

### VP0-003 [数据类型] Message / Channel 类型不完整
**状态**: 待处理  
**优先级**: P0（阻断）  

**问题描述**:  
- Message 缺少：username, avatar, isRead, status(撤回标)
- Channel 缺少：memberCount, hasJoined, unReadPosts
- Notification isRead应为 `number`而非boolean

---

### VP0-004 [API路径] Friends模块API调用与文档不一致
**状态**: 待处理  
**优先级**: P0（阻断）  

| 前端当前调用 | API文档定义 | 问题 |
|-------------|------------|------|
| `GET /friends/list` | `GET /api/friends` | 多了`/list` |
| `GET /friends/requests/pending` | `GET /api/friends/requests` | 多了`/pending` |
| `POST /friends/requests/{id}/approve` | `POST /api/friends/request/{id}/handle` | 命名不一致 |
| `POST /friends/requests/{id}/reject` | API无此端点 | ❌ 不存在 |

---

### VP0-005 [API路径] SettingsPage用户资料更新API调用错误
**状态**: 待处理  
**优先级**: P0（阻断）  

| 前端调用 | 正确API |
|----------|--------|
| `PUT /users/me` (改username/email) | `PUT /api/users/profile` |
| `POST /users/change-password` | `PUT /api/users/password` |

---

### VP0-006 [数据类型] Notification isRead 类型不匹配
**状态**: 待处理  
**优先级**: P1  

**问题描述**:  
后端isRead为 `number`(0/1)，前端类型定义为:boolean。虽然代码中有手动映射 `=== 1`，但类型定义应统一。

---

### VP0-007 [功能缺失] LikedPostsPage 路由存在但组件不存在
**状态**: 待处理  
**优先级**: P1  

**问题描述**:  
router/index.ts line 37定义了 `/liked-posts` 路由指向 LikedPostsPage.vue，但 `src/pages/` 下无此文件。页面白屏。

---

### VP0-008 [功能缺失] BlindBox.vue 组件未注册
**状态**: 待处理  
**优先级**: P2  

**问题描述**:  
`BlindBox.vue` 存在于components目录但无任何路由或页面引用，属于孤立组件。需确认是否删除还是接入功能。

---

### VP0-009 [WebSocket] ChatPage双重subscribe
**状态**: 待处理  
**优先级**: P1  

**问题描述**:  
ChatPage line 137/165在onConnect前和onConnect中都调用了subscribe，可能导致消息重复合并。应只保留一处。

---

### VP0-010 [WebSocket] WebSocket消息类型定义遗漏
**状态**: 待处理  
**优先级**: P2  

**问题描述**:  
以下消息类型无对应TS定义：
| 端点 | payload示例 |
|------|------------|
| message | `{id, content, type, creatorId, createTime, username, avatar}` |
| read_receipt | `{friendId}` |
| notification | `{type, category, data, timestamp}` |
| online_status | `{userId, online}` |

---

### VP0-011 [API路径] Admin端点多处不匹配（详见VP0-005系列问题）
**状态**: 待处理  
**优先级**: P1  

**涉及子问题**:
- `POST /admin/announcement` vs `POST /api/admin/announcements` (复数)
- `GET /admin/posts/pending` → 后端无此端点
- `GET /admin/channels` → 后端无此端点  
- `PUT /admin/channels/{id}/status` → `PUT /api/channels/{channelId}`
- `DELETE /admin/channels/{id}` → 后端无直接删除频道端点
- `PUT /admin/users/{id}/status` vs `POST /api/admin/users/{userId}/status`
- `GET /admin/logs` → 后端无此端点
- `GET /reports` vs `GET /api/admin/reports`
- `POST /reports/{id}/handle` vs `POST /api/admin/reports/{reportId}/handle`

---

## ==================== 📱 Flutter Mobile Issues ====================

### FP0-001 [依赖缺失] pubspec.yaml 缺少 web_socket_channel
**状态**: 待处理  
**优先级**: P0（阻断）  

**问题描述**:  
移动端使用 Raw WebSocket 进行实时通信，但 `pubspec.yaml` 中未声明 `web_socket_channel` 依赖。导致 import 失败或运行时错误。

---

### FP1-001 [V3.1规划] GIF/表情包渲染 - 帖子消息和评论
**状态**: 待处理  
**优先级**: P1  

**问题描述**:  
后端支持类型5为撤回（可能是图片型），需前端支持GIF渲染。当前未实现。

---

### FP1-002 [V3.1规划] 帖子分享海报生成
**状态**: 待处理  
**优先级**: P1  

**问题描述**:  
需要集成 Canvas/Image 组件，生成分享图像。后端可能需提供图片端点。

---

### FP1-003 [V3.1规划] 用户等级/勋章系统UI更新
**状态**: 待讨论  
**优先级**: P1  

**问题描述**:  
徽章后端已实现（GET /badges, GET /badges/my, POST /badges/{id}/equip），Flutter需展示新UI入口。

---

### FP2-001 [V3.1规划] 帖子分享/表情包/GIF
**状态**: 待处理  
**优先级**: P2  

---

### FP2-002 [V3.1规划] 频道排行榜
**状态**: 待处理  
**优先级**: P2  

---

### FP2-003 [V3.1规划] 消息全文搜索
**状态**: 待处理  
**优先级**: P2  

---

## ==================== 🟢 UniApp MiniProgram Issues (最严重）==================== 

### UP0-001 [功能完全缺失] Gallery 画廊模块
**状态**: 待处理  
**优先级**: P0（阻断）  

**问题描述**:  
后端已实现 `POST/GET/DELETE /api/gallery` 全链路（含like/comment/share/approve/pending），小程序端零实现。

**需新建页面**:
- `/pages/gallery/list` - 画廊列表页
- `/pages/gallery/upload` - 发布画作页
- `/pages/gallery/detail` - 画作详情页(含评论)

---

### UP0-002 [功能完全缺失] 草稿箱模块
**状态**: 待处理  
**优先级**: P0（阻断）  

**问题描述**:  
后端已实现 `POST/GET/DELETE /api/drafts` + `POST /api/drafts/{id}/publish`，小程序发布流程直接调 `/posts`，无草稿机制。

---

### UP0-003 [功能完全缺失] 关注系统
**状态**: 待处理  
**优先级**: P0（阻断）  

**问题描述**:  
后端已实现6个Follow接口但小程序端零实现。

**需新建页面**:
- `/pages/follow/list` - 粉丝/关注列表页
- `/pages/follow/feed` - 动态流

---

### UP0-004 [功能完全缺失] 徽章系统
**状态**: 待处理  
**优先级**: P0（阻断）  

---

### UP0-005 [Bug] API对接错误 (8项)

| BUG编号 | 错误调用 | 正确API | 风险 |
|---------|---------|--------|------|
| A | `/users/devices` 页面不存在 | - | 白屏 |
| B | `/settings/change-password` 页面不存在 | - | 白屏 |
| C | post/create `videoUrl` vs `videoUrls` | videoUrls | 视频创建失败 |
| D | `/api/upload/image` getBaseUrl() + BASE_URL 冲突 → `/api/api/`重复前缀 | - | 上传404 |
| E | `friend/list.vue` 调 `/friends/list` | `/friends` | 接口不匹配 |
| F | admin.vue 调 `GET /admin/stats` | 后端无此端点 | 404 |
| G | admin.vue 调 `PUT /reports/xx/handle` | `PUT /api/admin/{id}` | 404 |
| H | `/friends/list` vs `/friends` + `/pending` | 去掉多余的 /list, /pending | 接口不匹配 |
| I | admin.vue 调 `POST /admin/announcement` | `POST /announcements`(复数) | endpoint不一致 |

---

### UP0-006 [功能缺失] 核心页面缺失 (8项)

**需新建页面**：
1. `/pages/search/global-search` - 全局搜索（帖+频道）
2. `/pages/hot-posts/index` - 热门帖子
3. `/pages/tree-hole/index` - 树洞告白
4. `/pages/favourite/index` - 收藏页面
5. `/pages/channel-create/index` - 创建频道
6. `/pages/gallery/list` - 画廊列表
7. `/pages/announcements/list` - 公告列表
8. `/pages/drafts/list` - 草稿箱

---

### UP0-007 [安全] HTTPS与域名白名单
**状态**: 待讨论  
**优先级**: P1  

**问题描述**:  
小程序上线强制HTTPS，当前BASE_URL为 `http://10.50.30.104` 需配合法云域名+SSL证书并加至微信公众平台"服务器域名"/Socket合法域名白名单。

---

### UP0-008 [架构] UniApp技术文档缺失
**状态**: 待补全  
**优先级**: P2  

**问题描述**:  
docs目录下无小程序端独立技术文档。需根据当前代码和项目现状编写一份完整的小程序技术文档（含项目结构、API对接规范、微信生态配置等）。

---

## ==================== 📊 统计汇总 ====================

| 模块 | P0 (阻断) | P1 (重要) | P2 (一般) | 合计 |
|------|-----------|-----------|-----------|------|
| Backend_Dev | 0 | 7 | 1 | 8 |
| Vue_Frontend | 4 | 4 | 2 | 10 |
| Flutter_Mobile | 1 | 3 | 1 | 5 |
| Uniapp_MiniProgram | 5 | 1 | 2 | 8 (+ 8 Bug + 8 缺失页面) |
| **总计** | **10+** | **15** | **6** | **31+** |

---

## ⚠️ 项目负责人特别提示

本Issue文档由项目负责人综合4名子Agent的自查报告生成。

### 处理流程（严格执行）:
1. 项目经理审阅后将各Issue指派给对应的子Agent
2. 子Agent修复后报告状态 → 项目负责人人工验证
3. **只有项目负责人有权变更Issue状态**（等待验证 → 已解决 / 驳回 -> 待处理）
4. Issue的修改/状态变更仅由项目负责人在 CAMP_CHANNEL_ISSUES.md 中操作
