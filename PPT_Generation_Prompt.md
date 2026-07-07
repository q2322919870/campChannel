# AI Agent PPT 生成提示词

## 角色设定
你是一位资深的技术演讲专家和PPT设计师，擅长将复杂的技术项目转化为清晰、有吸引力的演示内容。

## 任务目标
阅读 Camp Channel 校园频道系统的完整项目代码，生成一份专业的技术演讲PPT，重点介绍**微信小程序端（UniApp）**和**服务器端（Spring Boot）**的实现。

## 项目背景
- **项目名称**: Camp Channel 校园频道系统
- **项目定位**: 校园社交平台，支持频道、帖子、聊天、好友等功能
- **技术栈**: 
  - 后端: Spring Boot + MyBatis-Plus + MySQL + Redis + WebSocket
  - 前端: Vue 3 + TypeScript + UniApp (微信小程序)
  - 其他端: PC端(Vue 3)、Flutter移动端
- **版本**: V1.0-V3.0

## PPT内容要求

### 第一部分：项目概览（2-3页）
1. **封面页**
   - 项目名称、演讲主题、日期
   - 简洁的视觉设计

2. **项目介绍**
   - 项目目标和定位
   - 核心功能模块（频道、帖子、聊天、好友、通知等）
   - 技术架构总览图

3. **版本演进**
   - V1.0: 基础社交平台
   - V2.0: 深度社交 + 内容运营
   - V3.0: 体验升级 + 社交增强

### 第二部分：服务器端实现（5-7页）

4. **技术栈选型**
   - Spring Boot 3.x + Java 26
   - MyBatis-Plus ORM框架
   - MySQL 9.7 数据库
   - Redis 缓存 + 限流
   - WebSocket (STOMP) 实时通信
   - Spring Security + JWT 认证

5. **核心架构设计**
   - 分层架构: Controller → Service → Mapper
   - 统一响应封装 Result<T>
   - 全局异常处理
   - 敏感词过滤机制
   - 限流策略（Redis + 令牌桶）

6. **数据库设计亮点**
   - 核心表结构（user, channel, post, message, comment等）
   - 索引优化策略
   - 软删除设计（status字段）
   - 匿名帖子设计（channel_id为NULL）

7. **实时通信实现**
   - WebSocket + STOMP协议
   - 消息推送机制（/user/queue/messages）
   - 在线状态管理（Redis + 心跳）
   - 消息撤回（2分钟限制 + 状态标记）
   - 已读回执（5级状态）

8. **安全与性能优化**
   - JWT Token认证流程
   - BCrypt密码加密
   - 敏感词检测（DFA算法）
   - Redis缓存热点数据
   - 数据库索引优化
   - N+1查询问题修复

9. **服务器端技术亮点总结**
   - ✅ 架构清晰，分层明确，易于维护和扩展
   - ✅ 统一响应格式 Result<T>，前后端协作高效
   - ✅ 完善的异常处理机制，系统稳定性强
   - ✅ WebSocket实时通信稳定可靠，支持千级并发
   - ✅ 安全防护全面（JWT认证 + BCrypt加密 + 限流）
   - ✅ 性能优化到位（Redis缓存 + 数据库索引 + N+1修复）

### 第三部分：微信小程序端实现（6-8页）

11. **技术栈选型**
    - UniApp + Vue 3 + TypeScript
    - Pinia 状态管理
    - 微信原生API集成
    - WebSocket实时通信

12. **项目结构设计**
    - 页面结构（pages/）
    - 组件设计（components/）
    - 状态管理（stores/）
    - 工具函数（utils/）
    - API封装（request.ts）

13. **核心功能实现**
    - 频道信息流（下拉刷新 + 无限滚动）
    - 帖子发布（图片/视频上传 + 话题 + @提及）
    - 实时聊天（WebSocket + 多媒体消息）
    - 群聊功能（频道群聊 + 禁言 + 撤回）
    - 树洞匿名帖子（24小时过期 + 迷雾效果）
    - 深色模式（CSS变量 + 主题切换）

14. **跨端技术迁移**
    - **PC端技术 → 小程序端**
      - Vue 3 Composition API → UniApp setup语法
      - Pinia状态管理 → 跨平台状态同步
      - WebSocket通信 → 小程序WebSocket API适配
      - 文件上传 → uni.uploadFile封装
    
    - **Flutter端技术 → 小程序端**
      - Material Design → 自定义UI组件
      - 原生分享 → 微信原生分享API
      - 本地存储 → uni.setStorageSync
      - 路由管理 → pages.json配置

15. **微信小程序特性集成**
    - 微信原生分享（onShareAppMessage + onShareTimeline）
    - TabBar角标通知（setTabBarBadge）
    - 深色模式适配（setTabBarStyle）
    - 图片预览（uni.previewImage）
    - 下拉刷新（enablePullDownRefresh）

16. **性能优化策略**
    - 图片懒加载
    - 分页加载优化
    - 组件按需加载
    - 状态管理优化（避免不必要的响应式）
    - WebSocket连接复用

17. **小程序端技术亮点总结**
    - ✅ 跨平台兼容，一套代码多端运行，开发效率高
    - ✅ 微信生态深度集成（原生分享、TabBar角标、深色模式）
    - ✅ Vue 3 Composition API + Pinia，代码组织清晰
    - ✅ 组件复用性强，维护成本低
    - ✅ WebSocket实时通信稳定，用户体验流畅
    - ✅ 性能优化到位（懒加载、分页、连接复用）

### 第四部分：技术对比与总结（2-3页）

19. **三端技术对比**
    | 特性 | PC端(Vue 3) | Flutter | 小程序(UniApp) |
    |------|-------------|---------|----------------|
    | 开发语言 | TypeScript | Dart | TypeScript |
    | 性能 | 高 | 高 | 中 |
    | 开发效率 | 高 | 中 | 高 |
    | 生态集成 | 弱 | 中 | 强 |
    | 跨平台 | 否 | 是 | 是 |
    | 包体积 | 大 | 大 | 中 |

20. **技术选型决策**
    - 为什么选择UniApp而不是原生小程序？
    - 为什么选择Spring Boot而不是其他框架？
    - 技术债务与未来规划

21. **项目成果与展望**
    - 已完成功能清单（V1.0-V3.0）
    - 核心指标（用户数、日活、消息量）
    - 未来规划（V3.1+）
    - 技术演进方向

### 第五部分：Q&A（1页）
22. **感谢页**
    - 联系方式
    - GitHub地址https://github.com/q2322919870

## 设计风格要求

### 视觉风格
- **配色方案**: 主色调 #6366F1（靛蓝），辅助色 #EC4899（粉红）
- **字体**: 标题使用粗体，正文使用常规字体
- **布局**: 简洁现代，留白充足，避免拥挤
- **图标**: 使用简洁的线性图标
- **图表**: 使用流程图、架构图、对比表格

### 内容呈现
- 每页内容不超过6个要点
- 使用项目符号（bullet points）
- 关键数据用大字号突出
- 代码片段使用等宽字体，语法高亮
- 架构图使用清晰的层次结构

### 演讲节奏
- 总页数: 22-25页
- 演讲时长: 10-15分钟
- 每页停留时间: 1-1.5分钟
- 重点页面（架构设计、核心功能）可延长至2分钟

## 输出格式

请以Markdown格式输出PPT内容，每页使用以下结构：

```markdown
# 第X页：页面标题

## 副标题（可选）

### 要点1
- 详细内容
- 详细内容

### 要点2
- 详细内容
- 详细内容

### 要点3
- 详细内容
- 详细内容

**备注**: 演讲时的补充说明（不显示在PPT上）
```

## 注意事项

1. **代码片段**: 每个技术点最多展示1个关键代码片段，不超过10行
2. **架构图**: 使用文字描述架构图的结构，标注关键组件和数据流向
3. **数据支撑**: 尽量使用具体数据（如"响应时间<100ms"、"支持1000并发"）
4. **案例说明**: 每个技术点配合实际业务场景说明
5. **对比分析**: 突出技术选型优势，展示项目亮点

## 开始执行

现在请阅读项目的以下关键文件，然后生成PPT内容：

### 服务器端关键文件
1. `camp-channel-server/src/main/java/com/gdmec/campchannel/controller/` - 所有Controller
2. `camp-channel-server/src/main/java/com/gdmec/campchannel/service/impl/` - 核心Service实现
3. `camp-channel-server/src/main/java/com/gdmec/campchannel/entity/` - 实体类
4. `camp-channel-server/src/main/resources/db/schema.sql` - 数据库表结构
5. `camp-channel-server/pom.xml` - 依赖配置

### 小程序端关键文件
1. `camp-channel-client-uniapp/src/pages/` - 所有页面
2. `camp-channel-client-uniapp/src/stores/` - 状态管理
3. `camp-channel-client-uniapp/src/utils/request.ts` - API封装
4. `camp-channel-client-uniapp/src/App.vue` - 应用入口
5. `camp-channel-client-uniapp/src/pages.json` - 页面配置
6. `camp-channel-client-uniapp/package.json` - 依赖配置

### 项目文档
1. `V3.0_升级方案.md` - 版本规划
2. `UniApp_V1-V3_开发进度.md` - 开发进度
3. `Camp Channel 校园频道系统 V1.0 需求文档.md` - 需求文档
4. `Camp Channel 校园频道系统 V2.0 需求文档.md` - 需求文档

请开始生成PPT内容。
