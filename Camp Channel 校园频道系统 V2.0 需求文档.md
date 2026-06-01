# Camp Channel 校园频道系统需求文档
## V2.0

| 项目 | 内容 |
| --- | --- |
| 文档版本 | V2.0 |
| 产品形态 | Web PC端 / Flutter移动端 / 微信小程序 |
| 适用对象 | 广东机电职业技术学院在校学生 |
| 登录方式 | 邮箱 + 密码登录（邮箱后缀限定 @stu.gdmec.edu.cn） |
| 核心场景 | 学生在校内频道发布图文/视频内容，互动交流，好友聊天，**群组沟通** |
| 基干版本 | V1.0（已完成全部核心功能） |
| 成文日期 | 2026-05-29 |

---

## 一、V2.0 定位

V1.0 已实现完整的校园社交基础功能（频道、帖子、聊天、好友、通知、管理后台）。
V2.0 聚焦于**深度社交体验**与**内容运营能力**，引入群聊、推荐算法、帖子富媒体化等能力。

---

## 二、V2.0 新增功能清单

| 优先级 | 模块 | 功能 | 工作量 |
|--------|------|------|--------|
| 🔴 P0 | **群聊** | 频道内群聊（文本/图片/视频消息） | 大 |
| 🔴 P0 | **消息已读回执** | 聊天消息显示已读/未读状态 | 中 |
| 🔴 P0 | **帖子收藏** | 收藏帖子到个人收藏夹 | 小 |
| 🟡 P1 | **热门/推荐** | 首页增加热门帖子信息流（点赞数+评论数排序） | 中 |
| 🟡 P1 | **帖子搜索** | 按关键词搜索帖子 | 中 |
| 🟡 P1 | **图片/视频消息** | 聊天中支持发送图片和短视频 | 中 |
| 🟡 P1 | **帖子置顶** | 频道主/管理员可置顶重要帖子 | 小 |
| 🟡 P1 | **在线状态** | 好友列表显示在线/离线状态 | 中 |
| 🟢 P2 | **端对端加密** | 聊天内容端到端加密（E2EE） | 大 |
| 🟢 P2 | **内容推送** | 集成厂商推送服务（华为/小米/APNs） | 大 |
| 🟢 P2 | **帖子草稿箱** | 未发布的帖子自动保存为草稿 | 小 |
| 🟢 P2 | **@提及通知** | 帖子中被@时实时推送通知 | 中 |
| 🟢 P2 | **系统性能优化** | 数据库索引优化、接口缓存、图片CDN | 中 |

---

## 三、V2.0 详细功能描述

### 1. 🔴 群聊功能

#### 1.1 频道群聊
- 每个频道默认拥有一个群聊房间
- 频道成员自动加入频道群聊
- 群聊消息对频道所有成员可见

#### 1.2 群聊消息类型
| 类型 | 说明 |
|------|------|
| 文字消息 | 支持文字+表情，≤2000字 |
| 图片消息 | 支持发送图片（≤10MB） |
| 视频消息 | 支持发送短视频（≤30秒，≤50MB） |

#### 1.3 群聊管理
- 频道主/管理员可撤回任意群消息
- 普通成员可撤回自己的消息（不限时间）
- 频道主/管理员可禁言成员

#### 1.4 数据库表扩展
- 新建 `group_message` 表存储群聊消息
- 新建 `group_member` 表（或复用 channel_member）

---

### 2. 🔴 消息已读回执

#### 2.1 一对一聊天
- 消息发送后显示"已发送"状态
- 对方收到消息后状态变为"已送达"
- 对方打开聊天窗口后状态变为"已读"
- 在消息气泡上显示状态标记（✓ 已发送、✓✓ 已送达、蓝色✓✓ 已读）

#### 2.2 设计
- 消息体增加 `status` 字段细化：0=发送中, 1=已发送, 2=已送达, 3=已读
- `read_at` 字段记录已读时间
- 通过 WebSocket 实时推送状态变更

---

### 3. 🔴 帖子收藏

#### 3.1 收藏功能
- 帖子操作区新增"收藏"按钮（书签图标）
- 每个用户可收藏任意帖子，每人每帖仅收藏1次
- 在个人中心增加"我的收藏"入口

#### 3.2 数据库设计
- 新建 `post_favourite` 表：(id, post_id, user_id, create_time)
- 唯一约束：(post_id, user_id)

---

### 4. 🟡 热门/推荐信息流

#### 4.1 热门帖子
- 首页新增"热门"标签，按近7天点赞数+评论数加权排序
- 算法：`热度分 = like_count × 1 + comment_count × 2`

#### 4.2 推荐帖子
- 基于用户已加入频道的帖子，按时间倒序混排
- 结合用户历史点赞，倾向展示高频互动频道的帖子

---

### 5. 🟡 帖子搜索

#### 5.1 搜索功能
- 首页顶部增加搜索框
- 支持按帖子内容关键词搜索
- 支持按话题（#话题#）过滤

#### 5.2 后端
- `GET /posts/search?keyword=&topic=&page=&size=`
- 使用 MySQL LIKE 或引入 ElasticSearch（V2.1规划）

---

### 6. 🟡 聊天图片/视频消息

#### 6.1 图片消息
- 聊天输入框+号扩展菜单增加"图片"选项
- 调用 `/upload/image` 上传图片
- 消息类型 `type=2`（图片消息），content 存储图片URL

#### 6.2 视频消息
- +号扩展菜单增加"视频"选项
- 调用 `/upload/video` 上传视频
- 消息类型 `type=3`（视频消息）

---

### 7. 🟡 帖子置顶

#### 7.1 置顶功能
- 频道主/管理员可将帖子置顶
- 置顶帖在频道帖子列表顶部展示，带有"📌 置顶"标记
- 最多同时置顶3个帖子

#### 7.2 数据库
- `post` 表增加 `is_pinned` 字段（TINYINT, 0/1）
- `GET /posts/channel/{id}` 返回值按置顶+时间排序

---

### 8. 🟡 在线状态

#### 8.1 状态显示
- 好友列表每个好友头像右下角显示在线状态圆点（绿色=在线，灰色=离线）
- 聊天窗口头部显示对方在线状态

#### 8.2 实现方案
- 通过 WebSocket 心跳机制维护在线状态
- Redis 存储用户最后活跃时间（key: `online:{userId}`, TTL: 60秒）

---

### 9. 🟢 端对端加密（V2.0规划）

#### 9.1 加密方案
- 采用 Signal Protocol 双棘轮算法（或简化版）
- 聊天消息在客户端加密后发送，服务端仅存储密文
- 密钥在客户端生成，服务端无法解密

#### 9.2 注意
- 需要引入加密库（如 libsignal-protocol-dart / libsodium.js）
- 仅支持一对一聊天加密，群聊加密延至 V2.1

---

### 10. 🟢 内容推送

#### 10.1 推送服务
- 集成华为推送、小米推送、APNs（iOS）
- 当用户不在线时，通过厂商通道推送通知

#### 10.2 推送类型
| 类型 | 说明 |
|------|------|
| 新消息 | 对方发来聊天消息时 |
| @提及 | 帖子中被@时 |
| 好友申请 | 收到好友申请时 |
| 频道审核 | 频道加入申请审核通过/拒绝时 |

---

## 四、数据库变更

### 新增表
```sql
-- 群聊消息表
CREATE TABLE IF NOT EXISTS `group_message` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `channel_id` BIGINT NOT NULL COMMENT '频道ID',
    `sender_id` BIGINT NOT NULL COMMENT '发送者ID',
    `content` TEXT COMMENT '文字内容',
    `media_url` VARCHAR(500) COMMENT '图片/视频URL',
    `msg_type` TINYINT DEFAULT 1 COMMENT '类型: 1-文字, 2-图片, 3-视频',
    `status` TINYINT DEFAULT 1 COMMENT '状态: 1-正常, 2-已撤回',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_gm_channel_id` (`channel_id`),
    INDEX `idx_gm_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='群聊消息表';

-- 帖子收藏表
CREATE TABLE IF NOT EXISTS `post_favourite` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `post_id` BIGINT NOT NULL COMMENT '帖子ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uk_fav_post_user` (`post_id`, `user_id`),
    INDEX `idx_fav_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='帖子收藏表';
```

### 修改表
```sql
-- message 表增加字段
ALTER TABLE `message` ADD COLUMN `read_at` DATETIME COMMENT '已读时间' AFTER `status`;
ALTER TABLE `message` MODIFY COLUMN `status` TINYINT DEFAULT 1 COMMENT '状态: 0-发送中, 1-已发送, 2-已送达, 3-已读, 5-已撤回';

-- post 表增加字段
ALTER TABLE `post` ADD COLUMN `is_pinned` TINYINT DEFAULT 0 COMMENT '是否置顶: 0-否, 1-是' AFTER `comment_count`;
```

---

## 五、API 变更

### 新增接口

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/posts/search` | 搜索帖子 |
| POST | `/posts/{id}/favourite` | 收藏/取消收藏帖子 |
| GET | `/posts/favourites` | 获取我的收藏列表 |
| POST | `/posts/{id}/pin` | 置顶/取消置顶帖子 |
| GET | `/group-messages/{channelId}` | 获取频道群聊消息 |
| POST | `/group-messages/send` | 发送群聊消息 |
| DELETE | `/group-messages/{id}` | 撤回群聊消息 |
| POST | `/chat/messages/{id}/read` | 标记消息已读 |
| GET | `/posts/hot` | 获取热门帖子 |

### 修改接口

| 方法 | 路径 | 变更 |
|------|------|------|
| GET | `/posts/channel/{id}` | 返回值按 `is_pinned` 降序 |
| GET | `/friends/list` | 返回值增加 `onlineStatus` 字段 |
| GET | `/chat/history/{friendId}` | 返回值增加 `readAt` 字段 |
| GET | `/chat/conversations` | 返回值增加 `unreadCount` 和 `lastMessageStatus` |

---

## 六、安全与性能

### 安全
- 加密聊天的密钥协商流程需做安全审计
- 群聊消息存储需防止 SQL 注入

### 性能
- 热门帖子推荐增加 Redis 缓存（TTL: 5分钟）
- 帖子搜索加 MySQL 全文索引或引入 ElasticSearch
- 群聊消息表按 channel_id 分区

---

## 七、版本规划

| 版本 | 内容 | 预计工作量 |
|------|------|-----------|
| V2.0-P0 | 群聊 + 已读回执 + 收藏 | 大 |
| V2.0-P1 | 热门推荐 + 帖子搜索 + 图片/视频消息 + 置顶 + 在线状态 | 中-大 |
| V2.0-P2 | E2EE + 推送 + 草稿箱 + @通知 + 性能优化 | 中-大 |

---

> **文档说明**  
> 1. V2.0 基于 V1.0 完整实现的功能进行扩展。  
> 2. P0 为必须实现的核心功能，P1 为重要功能，P2 为体验增强功能。  
> 3. 优先实现 P0，逐步推进 P1 和 P2。  

**文档版本历史**  
| 版本 | 日期 | 修改内容 | 修改人 |
|------|------|----------|--------|
| V2.0 | 2026-05-29 | V2.0初稿创建 | 需求分析师 |
