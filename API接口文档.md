# Camp Channel API 接口文档

> 版本：V3.0
> 基础URL：`http://10.50.30.104:8080/api`
> 认证方式：JWT Token，通过请求头 `Authorization: Bearer <token>` 传递

---

## 目录
- [1. 身份认证模块](#1-身份认证模块)
- [2. 用户中心模块](#2-用户中心模块)
- [3. 帖子管理模块](#3-帖子管理模块)
- [4. 频道管理模块](#4-频道管理模块)
- [5. 聊天模块](#5-聊天模块)
- [6. 评论模块](#6-评论模块)
- [7. 点赞模块](#7-点赞模块)
- [8. 画廊模块](#8-画廊模块)
- [9. 好友关系模块](#9-好友关系模块)
- [10. 通知模块](#10-通知模块)
- [11. 公告模块](#11-公告模块)
- [12. 徽章模块](#12-徽章模块)
- [13. 举报模块](#13-举报模块)
- [14. 上传模块](#14-上传模块)
- [15. 管理员模块](#15-管理员模块)
- [16. WebSocket实时通信](#16-websocket实时通信)
- [17. 草稿箱模块](#17-草稿箱模块)
- [18. 群聊消息模块](#18-群聊消息模块)
- [19. 关注模块](#19-关注模块)

---

## 1. 身份认证模块

**基础路径：** `/api/auth`

### 1.1 发送注册验证码
```
POST /api/auth/send-code
```
**请求体：**
```json
{
  "email": "xxx@stu.gdmec.edu.cn"
}
```
**响应：**
```json
{
  "code": 200,
  "message": "验证码已发送至您的邮箱",
  "data": null
}
```
**说明：**
- 仅支持广东机电职业技术学院邮箱（@stu.gdmec.edu.cn）
- 60秒内不能重复发送
- 验证码有效期5分钟

### 1.2 用户注册
```
POST /api/auth/register
```
**请求体：**
```json
{
  "email": "xxx@stu.gdmec.edu.cn",
  "username": "用户名",
  "password": "密码",
  "code": "123456",
  "realName": "真实姓名（可选）",
  "phone": "手机号（可选）"
}
```
**响应：**
```json
{
  "code": 200,
  "message": "注册成功",
  "data": { "id": 1, "username": "...", "email": "...", ... }
}
```

### 1.3 用户登录
```
POST /api/auth/login
```
**请求体：**
```json
{
  "email": "xxx@stu.gdmec.edu.cn",  // 或 username
  "password": "密码"
}
```
**响应：**
```json
{
  "code": 200,
  "message": "登录成功",
  "data": {
    "token": "Bearer eyJhbGci...",
    "accessToken": "Bearer eyJhbGci...",
    "userId": 1,
    "username": "xxx",
    "email": "xxx@stu.gdmec.edu.cn",
    "role": "user",
    "avatar": "/uploads/avatars/xxx.jpg"
  }
}
```
**说明：**
- 密码错误5次锁定30分钟
- 单设备登录，新登录会踢掉旧设备

---

## 2. 用户中心模块

**基础路径：** `/api/users`

### 2.1 获取当前用户信息
```
GET /api/users/me
Authorization: Bearer <token>
```
**响应：** 返回当前用户完整信息（不含密码）

### 2.2 获取个人资料（含统计数据）
```
GET /api/users/profile
Authorization: Bearer <token>
```
**响应：**
```json
{
  "code": 200,
  "data": {
    "id": 1,
    "username": "xxx",
    "email": "xxx@stu.gdmec.edu.cn",
    "avatar": "/uploads/avatars/xxx.jpg",
    "role": "user",
    "emailNotify": true,
    "postCount": 10,
    "friendCount": 5
  }
}
```

### 2.3 根据ID获取用户信息
```
GET /api/users/{userId}
```

### 2.4 获取用户名片
```
GET /api/users/{userId}/profile
Authorization: Bearer <token>
```
**响应：** 包含用户信息、是否好友关系、用户最近20条帖子
```json
{
  "code": 200,
  "data": {
    "id": 1,
    "username": "xxx",
    "email": "xxx@stu.gdmec.edu.cn",
    "avatar": "/uploads/avatars/xxx.jpg",
    "isFriend": false,
    "posts": [
      {
        "id": 123,
        "topic": "帖子标题",
        "content": "帖子内容",
        "images": ["/uploads/images/xxx.jpg"],
        "createTime": "2026-06-03T10:00:00"
      }
    ]
  }
}
```

### 2.5 更新个人资料
```
PUT /api/users/profile
Authorization: Bearer <token>
```
**请求体：**
```json
{
  "username": "新用户名",
  "realName": "新真实姓名",
  "phone": "新手机号"
}
```

### 2.6 修改密码
```
PUT /api/users/password
Authorization: Bearer <token>
```
**请求体：**
```json
{
  "oldPassword": "旧密码",
  "newPassword": "新密码"
}
```

### 2.7 上传头像
```
POST /api/users/avatar
Authorization: Bearer <token>
Content-Type: multipart/form-data
```
**表单字段：** `file`（图片文件）

### 2.8 获取登录设备列表
```
GET /api/users/devices
Authorization: Bearer <token>
```

### 2.9 远程下线设备
```
DELETE /api/users/devices/{deviceId}
Authorization: Bearer <token>
```

---

## 3. 帖子管理模块

**基础路径：** `/api/posts`

### 3.1 获取首页信息流
```
GET /api/posts?page=1&size=10
Authorization: Bearer <token>
```
**响应：** 返回用户所有频道的帖子列表

### 3.2 获取匿名树洞帖子
```
GET /api/posts/tree-hole?page=1&size=10
Authorization: Bearer <token>
```

### 3.3 发布帖子
```
POST /api/posts
Authorization: Bearer <token>
```
**请求体：**
```json
{
  "channelId": 1,
  "content": "帖子内容",
  "images": ["图片URL1", "图片URL2"],
  "videoUrls": ["视频URL1", "视频URL2"],
  "isAnonymous": false
}
```
**说明：**
- `images` 和 `videoUrls` 可以混合使用，总数不能超过9个
- 视频文件大小不能超过5MB

### 3.4 获取频道帖子
```
GET /api/posts/channel/{channelId}?page=1&size=10
Authorization: Bearer <token>
```

### 3.5 获取帖子详情
```
GET /api/posts/{postId}
```

### 3.6 获取我的帖子
```
GET /api/posts/my?page=1&size=10
Authorization: Bearer <token>
```

### 3.7 删除帖子
```
DELETE /api/posts/{postId}
Authorization: Bearer <token>
```

### 3.8 获取热门帖子
```
GET /api/posts/hot?page=1&size=10
```

### 3.9 获取收藏帖子
```
GET /api/posts/favourites?page=1&size=10
Authorization: Bearer <token>
```

### 3.10 收藏/取消收藏帖子
```
POST /api/posts/{postId}/favourite
Authorization: Bearer <token>
```

### 3.11 获取点赞帖子
```
GET /api/posts/liked?page=1&size=10
Authorization: Bearer <token>
```

### 3.12 搜索帖子
```
GET /api/posts/search?keyword=关键词&page=1&size=20
Authorization: Bearer <token>
```

### 3.13 增加浏览量
```
GET /api/posts/{postId}/view
```

### 3.14 编辑帖子
```
PUT /api/posts/{postId}
Authorization: Bearer <token>
```
**请求体：**
```json
{
  "content": "更新后的内容",
  "images": ["图片URL1"],
  "videoUrls": ["视频URL1"]
}
```
**说明：**
- 仅作者可编辑，会自动递增 `editCount` 并记录 `lastEditTime`
- `images` 和 `videoUrls` 可以混合使用，总数不能超过9个
- 视频文件大小不能超过5MB

### 3.15 置顶/取消置顶帖子
```
POST /api/posts/{postId}/pin
Authorization: Bearer <token>
```
**响应：**
```json
{
  "code": 200,
  "data": {
    "isPinned": true,
    "message": "已置顶"
  }
}
```

### 3.16 记录解开告白
```
POST /api/posts/{postId}/reveal
Authorization: Bearer <token>
```
**说明：** 用于匿名树洞/告白帖子的解开状态记录，跨设备同步

### 3.17 获取指定用户的帖子
```
GET /api/posts/user/{userId}?page=1&size=20
```

### 3.18 检查收藏状态
```
GET /api/posts/{postId}/favourite/status
Authorization: Bearer <token>
```
**响应：**
```json
{
  "code": 200,
  "data": {
    "isFavourited": true,
    "count": 5
  }
}
```

---

## 4. 频道管理模块

**基础路径：** `/api/channels`

### 4.1 创建频道
```
POST /api/channels
Authorization: Bearer <token>
```
**请求体：**
```json
{
  "name": "频道名称",
  "description": "频道描述"
}
```

### 4.2 搜索频道
```
GET /api/channels/search?keyword=关键词
```

### 4.3 获取我的频道
```
GET /api/channels/my
Authorization: Bearer <token>
```

### 4.4 申请加入频道
```
POST /api/channels/{channelId}/join
Authorization: Bearer <token>
```

### 4.5 退出频道
```
POST /api/channels/{channelId}/leave
Authorization: Bearer <token>
```

### 4.6 编辑频道
```
PUT /api/channels/{channelId}
Authorization: Bearer <token>
```

### 4.7 获取频道成员
```
GET /api/channels/{channelId}/members
```

### 4.8 获取待审核申请
```
GET /api/channels/{channelId}/applications
Authorization: Bearer <token>
```

### 4.9 审核加入申请
```
POST /api/channels/applications/{applicationId}/approve
Authorization: Bearer <token>
```
**请求体：**
```json
{
  "approved": true
}
```

### 4.10 移除成员
```
POST /api/channels/{channelId}/members/{userId}/remove
Authorization: Bearer <token>
```

### 4.11 设置成员角色
```
POST /api/channels/{channelId}/members/{userId}/role
Authorization: Bearer <token>
```
**请求体：**
```json
{
  "role": "admin"  // admin 或 member
}
```

### 4.12 禁言/取消禁言
```
POST /api/channels/{channelId}/members/{userId}/mute
Authorization: Bearer <token>
```
**请求体：**
```json
{
  "muted": true
}
```

### 4.13 获取待审核申请总数
```
GET /api/channels/applications/pending/count
Authorization: Bearer <token>
```

### 4.14 获取所有待审核申请
```
GET /api/channels/applications/pending
Authorization: Bearer <token>
```

---

## 5. 聊天模块

**基础路径：** `/api/chat`

### 5.1 查询用户在线
```
GET /api/chat/online/{userId}
```
**响应：** `{ "code": 200, "data": true }`

### 5.2 批量查询在线状态
```
GET /api/chat/online/batch?userIds=1,2,3
Authorization: Bearer <token>
```

### 5.3 发送消息
```
POST /api/chat/messages/send
Authorization: Bearer <token>
```
**请求体：**
```json
{
  "receiverId": 2,
  "content": "消息内容",
  "type": 1  // 1: 文本, 2: 图片, 3: 文件
}
```

### 5.4 获取聊天记录
```
GET /api/chat/history/{friendId}?page=1&size=20
Authorization: Bearer <token>
```

### 5.5 撤回消息
```
POST /api/chat/messages/{messageId}/recall
Authorization: Bearer <token>
```

### 5.6 获取会话列表
```
GET /api/chat/conversations
Authorization: Bearer <token>
```

### 5.7 获取会话列表（含未读计数）
```
GET /api/chat/conversations/with-unread
Authorization: Bearer <token>
```
**响应：**
```json
{
  "code": 200,
  "data": [
    {
      "id": 2,
      "username": "对方用户名",
      "avatar": "/uploads/avatars/xxx.jpg",
      "lastMsg": "最后一条消息",
      "createTime": "2024-01-01T12:00:00",
      "senderId": 2,
      "isRead": false,
      "unread": 3,
      "online": true
    }
  ]
}
```

### 5.8 获取未读消息数
```
GET /api/chat/unread/{friendId}
Authorization: Bearer <token>
```

### 5.9 标记全部已读
```
POST /api/chat/read-all/{friendId}
Authorization: Bearer <token>
```

### 5.10 标记单条消息已读
```
POST /api/chat/messages/{messageId}/read
Authorization: Bearer <token>
```

---

## 6. 评论模块

**基础路径：** `/api/posts/{postId}/comments`

### 6.1 发表评论
```
POST /api/posts/{postId}/comments
Authorization: Bearer <token>
```
**请求体：**
```json
{
  "content": "评论内容",
  "parentId": null  // 二级回复时填写父评论ID
}
```

### 6.2 获取评论列表
```
GET /api/posts/{postId}/comments?page=1&size=20
Authorization: Bearer <token>
```
**响应：** 每条评论包含 `likeCount`、`isLiked`（当前用户是否已点赞）字段

### 6.3 删除评论
```
DELETE /api/posts/{postId}/comments/{commentId}
Authorization: Bearer <token>
```

### 6.4 评论点赞/取消点赞
```
POST /api/posts/{postId}/comments/{commentId}/like
Authorization: Bearer <token>
```
**响应：**
```json
{
  "code": 200,
  "message": "点赞成功",
  "data": true
}
```
**说明：** `data` 为 `true` 表示已点赞，`false` 表示已取消点赞。切换式操作，无需传参

---

## 7. 点赞模块

**基础路径：** `/api/posts/{postId}/like`

### 7.1 点赞/取消点赞
```
POST /api/posts/{postId}/like
Authorization: Bearer <token>
```
**响应：**
```json
{
  "code": 200,
  "data": {
    "liked": true,
    "likeCount": 10
  }
}
```

### 7.2 检查点赞状态
```
GET /api/posts/{postId}/like/status
Authorization: Bearer <token>
```

---

## 8. 画廊模块

**基础路径：** `/api/gallery`

### 8.1 添加画作
```
POST /api/gallery
Authorization: Bearer <token>
```
**请求体：**
```json
{
  "imageUrl": "图片URL",
  "videoUrl": "视频URL",
  "mediaType": 1,
  "title": "画作标题",
  "description": "画作描述",
  "channelId": 1
}
```
**说明：**
- `mediaType`: 1-图片, 2-视频
- 发布视频时，`videoUrl` 必填，`imageUrl` 可为空
- 发布图片时，`imageUrl` 必填，`videoUrl` 可为空
- 视频文件大小不能超过5MB

### 8.2 获取画廊列表
```
GET /api/gallery?page=1&size=20&channelId=1
```

### 8.3 获取我的画作
```
GET /api/gallery/my
Authorization: Bearer <token>
```

### 8.4 删除画作
```
DELETE /api/gallery/{galleryId}
Authorization: Bearer <token>
```

### 8.5 点赞/取消点赞画作
```
POST /api/gallery/{galleryId}/like
Authorization: Bearer <token>
```
**响应：**
```json
{
  "code": 200,
  "data": {
    "liked": true,
    "likeCount": 5
  }
}
```

### 8.6 检查画作点赞状态
```
GET /api/gallery/{galleryId}/like/status
Authorization: Bearer <token>
```

### 8.7 评论画作
```
POST /api/gallery/{galleryId}/comment
Authorization: Bearer <token>
```
**请求体：**
```json
{
  "content": "评论内容"
}
```
**响应：**
```json
{
  "code": 200,
  "message": "评论成功",
  "data": {
    "id": 1,
    "userId": 1,
    "username": "用户名",
    "avatar": "头像URL",
    "content": "评论内容",
    "createTime": "2024-01-01T12:00:00"
  }
}
```

### 8.8 获取画作评论
```
GET /api/gallery/{galleryId}/comments
```
**响应：** 返回评论列表，每条评论包含用户信息

### 8.9 分享画作到聊天
```
POST /api/gallery/{galleryId}/share
Authorization: Bearer <token>
```
**请求体：**
```json
{
  "targetUserId": 2
}
```

### 8.10 获取待审核画作（管理员）
```
GET /api/gallery/pending
Authorization: Bearer <token>
```

### 8.11 审核画作（管理员）
```
POST /api/gallery/{galleryId}/approve
Authorization: Bearer <token>
```
**请求体：**
```json
{
  "approved": true
}
```

### 8.12 管理员删除画作
```
DELETE /api/gallery/admin/{galleryId}
Authorization: Bearer <token>
```

---

## 9. 好友关系模块

**基础路径：** `/api/friends`

### 9.1 发送好友申请
```
POST /api/friends/request
Authorization: Bearer <token>
```
**请求体：**
```json
{
  "friendId": 2
}
```

### 9.2 获取好友申请列表
```
GET /api/friends/requests
Authorization: Bearer <token>
```

### 9.3 处理好友申请
```
POST /api/friends/request/{requestId}/handle
Authorization: Bearer <token>
```
**请求体：**
```json
{
  "accepted": true
}
```

### 9.4 获取好友列表
```
GET /api/friends
Authorization: Bearer <token>
```

### 9.5 删除好友
```
DELETE /api/friends/{friendId}
Authorization: Bearer <token>
```

---

## 10. 通知模块

**基础路径：** `/api/notifications`

### 10.1 获取未读通知列表
```
GET /api/notifications/unread
Authorization: Bearer <token>
```
**响应：** 返回未读通知列表

### 10.2 获取未读通知数
```
GET /api/notifications/unread/count
Authorization: Bearer <token>
```
**响应：** `data` 为未读通知数量（整数）

### 10.3 获取通知历史（支持分类过滤）
```
GET /api/notifications/history?page=1&size=20&category=
Authorization: Bearer <token>
```
**参数说明：**
- `page`: 页码，默认1
- `size`: 每页数量，默认20
- `category`: 通知分类（可选），可选值：`system`（系统）、`interaction`（互动）、`chat`（聊天）

**响应：** 返回通知列表，每项包含：
```json
{
  "id": 1,
  "userId": 1,
  "type": "like",
  "category": "interaction",
  "title": "点赞通知",
  "content": "xxx 赞了你的帖子",
  "relatedId": "123",
  "isRead": 0,
  "createTime": "2026-06-03T10:00:00"
}
```

### 10.4 标记通知已读
```
POST /api/notifications/{notificationId}/read
Authorization: Bearer <token>
```

### 10.5 标记全部已读
```
POST /api/notifications/read-all
Authorization: Bearer <token>
```

**通知分类说明：**
- `system`: 系统通知（如公告、系统消息）
- `interaction`: 互动通知（如点赞、评论、@提及、关注）
- `chat`: 聊天相关通知（如新消息、好友请求）

---

## 11. 公告模块

**基础路径：** `/api/announcements`

### 11.1 获取公告列表
```
GET /api/announcements?page=1&size=10
```

### 11.2 获取公告详情
```
GET /api/announcements/{announcementId}
```

---

## 12. 徽章模块

**基础路径：** `/api/badges`

### 12.1 获取我的徽章
```
GET /api/badges/my
Authorization: Bearer <token>
```

### 12.2 佩戴徽章
```
POST /api/badges/{badgeId}/equip
Authorization: Bearer <token>
```

### 12.3 取消佩戴
```
POST /api/badges/{badgeId}/unequip
Authorization: Bearer <token>
```

---

## 13. 举报模块

**基础路径：** `/api/reports`

### 13.1 提交举报
```
POST /api/reports
Authorization: Bearer <token>
```
**请求体：**
```json
{
  "targetType": "post",  // post, comment, user
  "targetId": 1,
  "reason": "举报原因"
}
```

### 13.2 获取我的举报
```
GET /api/reports/my
Authorization: Bearer <token>
```

---

## 14. 上传模块

**基础路径：** `/api/upload`

### 14.1 上传图片
```
POST /api/upload/image
Authorization: Bearer <token>
Content-Type: multipart/form-data
```
**表单字段：** `file`

**响应：**
```json
{
  "code": 200,
  "data": {
    "url": "/uploads/images/xxx.jpg"
  }
}
```

### 14.2 上传视频
```
POST /api/upload/video
Authorization: Bearer <token>
Content-Type: multipart/form-data
```
**表单字段：** `file`

**响应：**
```json
{
  "code": 200,
  "data": {
    "url": "/uploads/videos/xxx.mp4"
  }
}
```
**说明：**
- 视频文件大小不能超过5MB
- 支持自动去重（基于文件哈希）
- 如果FFmpeg可用，会自动压缩视频

---

## 15. 管理员模块

**基础路径：** `/api/admin`

### 15.1 获取所有用户
```
GET /api/admin/users?page=1&size=20
Authorization: Bearer <token>
```

### 15.2 设置用户角色
```
POST /api/admin/users/{userId}/role
Authorization: Bearer <token>
```
**请求体：**
```json
{
  "role": "sys_admin"  // sys_admin, channel_admin, user
}
```

### 15.3 禁用/启用用户
```
POST /api/admin/users/{userId}/status
Authorization: Bearer <token>
```
**请求体：**
```json
{
  "status": 0  // 0: 禁用, 1: 启用
}
```

### 15.4 获取所有举报
```
GET /api/admin/reports?page=1&size=20
Authorization: Bearer <token>
```

### 15.5 处理举报
```
POST /api/admin/reports/{reportId}/handle
Authorization: Bearer <token>
```
**请求体：**
```json
{
  "handled": true,
  "action": "delete_post"
}
```

### 15.6 发布公告
```
POST /api/admin/announcements
Authorization: Bearer <token>
```
**请求体：**
```json
{
  "title": "公告标题",
  "content": "公告内容"
}
```

### 15.7 删除公告
```
DELETE /api/admin/announcements/{announcementId}
Authorization: Bearer <token>
```

---

## 16. WebSocket实时通信

### 16.1 STOMP WebSocket（PC端）
**连接地址：** `ws://localhost:8080/ws`

**订阅频道：**
- `/user/queue/messages` - 接收私信
- `/user/queue/read-receipts` - 接收已读回执
- `/user/queue/notifications` - 接收系统通知

**发送消息：**
```
/app/chat.send
{
  "receiverId": 2,
  "content": "消息内容",
  "type": 1
}
```

### 16.2 Raw WebSocket（移动端）
**连接地址：** `ws://localhost:8080/ws/raw`

**连接时携带Token：** `ws://localhost:8080/ws/raw?token=xxx`

**接收消息格式：**
```json
{
  "type": "message",
  "data": { "id": 1, "content": "...", "senderId": 2, ... }
}
```

---

## 通用响应格式

```json
{
  "code": 200,
  "message": "成功",
  "data": {}
}
```

## 错误码

| 错误码 | 说明 |
|--------|------|
| 200 | 成功 |
| 400 | 请求参数错误 |
| 401 | 未授权/Token无效 |
| 403 | 权限不足 |
| 404 | 资源不存在 |
| 429 | 请求过于频繁 |
| 500 | 服务器内部错误 |

## PC端接入说明

### 1. 初始化
```typescript
// src/api/index.ts
import axios from 'axios'

const api = axios.create({
  baseURL: 'http://localhost:8080/api',
  timeout: 10000,
})

// 请求拦截器：添加Token
api.interceptors.request.use(config => {
  const token = localStorage.getItem('token')
  if (token) {
    config.headers.Authorization = token
  }
  return config
})

// 响应拦截器：处理401
api.interceptors.response.use(
  res => res,
  err => {
    if (err.response?.status === 401) {
      localStorage.removeItem('token')
      window.location.href = '/login'
    }
    return Promise.reject(err)
  }
)

export default api
```

### 2. 登录流程
```typescript
// 1. 调用登录接口
const res = await api.post('/auth/login', { email, password })
// 2. 保存Token
localStorage.setItem('token', res.data.data.token)
// 3. 跳转首页
router.push('/')
```

### 3. WebSocket连接
```typescript
import { Client } from '@stomp/stompjs'

const stompClient = new Client({
  brokerURL: 'ws://localhost:8080/ws',
  connectHeaders: {
    Authorization: localStorage.getItem('token') || ''
  },
  onConnect: () => {
    // 订阅消息
    stompClient.subscribe('/user/queue/messages', msg => {
      const message = JSON.parse(msg.body)
      // 处理新消息
    })
  }
})

stompClient.activate()
```

## 移动端接入说明（Flutter）

### 1. 初始化Dio
```dart
import 'package:dio/dio.dart';

final dio = Dio(BaseOptions(
  baseUrl: 'http://localhost:8080/api',
  connectTimeout: Duration(seconds: 10),
));

// 添加Token拦截器
dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) {
    final token = SharedPreferences.getInstance()
        .then((prefs) => prefs.getString('token'));
    if (token != null) {
      options.headers['Authorization'] = token;
    }
    return handler.next(options);
  },
  onError: (error, handler) {
    if (error.response?.statusCode == 401) {
      // Token过期，跳转登录
    }
    return handler.next(error);
  },
));
```

### 2. Raw WebSocket连接
```dart
import 'package:web_socket_channel/web_socket_channel.dart';

final channel = WebSocketChannel.connect(
  Uri.parse('ws://localhost:8080/ws/raw?token=$token'),
);

channel.stream.listen((data) {
  final message = jsonDecode(data);
  // 处理消息
});
```

---

## 17. 草稿箱模块

**基础路径：** `/api/drafts`

### 17.1 保存草稿（新增或更新）
```
POST /api/drafts
Authorization: Bearer <token>
```
**请求体：**
```json
{
  "id": null,
  "channelId": 1,
  "content": "草稿内容",
  "images": "url1,url2",
  "videoUrl": "视频URL（可选）",
  "topic": "话题",
  "isAnonymous": false
}
```
**说明：** `id` 为 null 时新建草稿，非 null 时更新已有草稿。`images` 为逗号分隔的图片URL字符串。

### 17.2 获取草稿列表
```
GET /api/drafts?page=1&size=20
Authorization: Bearer <token>
```
**响应：** 返回当前用户的所有草稿列表，包含 `channelName` 字段

### 17.3 获取单个草稿详情
```
GET /api/drafts/{draftId}
Authorization: Bearer <token>
```

### 17.4 删除草稿
```
DELETE /api/drafts/{draftId}
Authorization: Bearer <token>
```

### 17.5 发布草稿
```
POST /api/drafts/{draftId}/publish
Authorization: Bearer <token>
```
**说明：** 将草稿内容发布为正式帖子，发布成功后自动删除草稿

---

## 18. 群聊消息模块

**基础路径：** `/api/group-messages`

### 18.1 发送群聊消息
```
POST /api/group-messages
Authorization: Bearer <token>
```
**请求体：**
```json
{
  "channelId": 1,
  "content": "消息文字内容",
  "mediaUrl": "媒体URL（图片/视频时填写）",
  "msgType": 1
}
```
**msgType 类型说明：**
| 值 | 说明 |
|----|------|
| 1 | 文字消息 |
| 2 | 图片消息 |
| 3 | 视频消息 |

### 18.2 获取频道群聊消息
```
GET /api/group-messages/{channelId}?page=1&size=50
```
**响应：** 返回该频道的群聊消息列表（分页），每条消息包含 `username`、`avatar` 字段

### 18.3 撤回群聊消息
```
DELETE /api/group-messages/{messageId}
Authorization: Bearer <token>
```
**说明：** 仅发送者可撤回自己的消息，撤回后 `status` 变为 2（已撤回）

---

## 19. 关注模块

**基础路径：** `/api/follow`

### 19.1 关注/取消关注用户
```
POST /api/follow/{userId}/toggle
Authorization: Bearer <token>
```
**响应：**
```json
{
  "code": 200,
  "message": "关注成功",
  "data": true
}
```
**说明：** `data` 为 `true` 表示已关注，`false` 表示已取消关注。切换式操作，不能关注自己

### 19.2 获取粉丝列表
```
GET /api/follow/{userId}/followers?page=1&size=20
```
**响应：** 返回粉丝列表，每项包含 `followerId`、`followerUsername`、`followerAvatar`

### 19.3 获取关注列表
```
GET /api/follow/{userId}/following?page=1&size=20
```
**响应：** 返回关注列表，每项包含 `followingId`、`username`、`avatar`

### 19.4 获取粉丝数和关注数
```
GET /api/follow/{userId}/counts
```
**响应：**
```json
{
  "code": 200,
  "data": {
    "followerCount": 10,
    "followingCount": 5
  }
}
```

### 19.5 检查是否已关注
```
GET /api/follow/{userId}/is-following
Authorization: Bearer <token>
```
**响应：** `data` 为 `true` 表示已关注，`false` 表示未关注

### 19.6 获取关注动态
```
GET /api/follow/feed?page=1&size=20
Authorization: Bearer <token>
```
**响应：** 返回当前用户关注的人的帖子列表，按时间倒序
