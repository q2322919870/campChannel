-- 1. 用户表 (user)
CREATE TABLE IF NOT EXISTS `user` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `username` VARCHAR(50) NOT NULL COMMENT '用户名/昵称',
    `real_name` VARCHAR(20) COMMENT '真实姓名',
    `phone` VARCHAR(20) COMMENT '手机号',
    `email` VARCHAR(100) NOT NULL UNIQUE COMMENT '广东机电邮箱 (@stu.gdmec.edu.cn)',
    `password` VARCHAR(255) NOT NULL COMMENT 'BCrypt加密密码',
    `role` VARCHAR(20) DEFAULT 'user' COMMENT '角色: user, sys_admin',
    `status` TINYINT DEFAULT 1 COMMENT '状态: 1-正常, 0-禁用',
    `avatar` VARCHAR(255) COMMENT '头像URL',
    `email_notify` TINYINT DEFAULT 1 COMMENT '邮件通知开关: 1-开启, 0-关闭',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- 2. 频道表 (channel)
CREATE TABLE IF NOT EXISTS `channel` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `channel_code` VARCHAR(20) NOT NULL UNIQUE COMMENT '频道唯一编号 (CH-xxxx-xxx)',
    `name` VARCHAR(100) NOT NULL COMMENT '频道名称',
    `description` TEXT COMMENT '频道描述',
    `type` TINYINT DEFAULT 1 COMMENT '类型: 1-公共频道, 2-私人频道',
    `status` TINYINT DEFAULT 1 COMMENT '状态: 1-正常, 0-禁用',
    `creator_id` BIGINT NOT NULL COMMENT '创建者用户ID',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX `idx_channel_code` (`channel_code`),
    INDEX `idx_channel_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='频道表';

-- 3. 频道成员关系表 (channel_member)
CREATE TABLE IF NOT EXISTS `channel_member` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `channel_id` BIGINT NOT NULL COMMENT '频道ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `role` VARCHAR(20) DEFAULT 'member' COMMENT '角色: owner, admin, member',
    `is_muted` TINYINT DEFAULT 0 COMMENT '是否禁言: 0-否, 1-是',
    `status` TINYINT DEFAULT 1 COMMENT '状态: 1-已加入, 0-待审核, 2-已拒绝',
    `apply_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '申请时间',
    `approve_time` DATETIME COMMENT '审核时间',
    `approve_user_id` BIGINT COMMENT '审核人用户ID',
    UNIQUE KEY `uk_channel_user` (`channel_id`, `user_id`),
    INDEX `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='频道成员关系表';

-- 4. 帖子表 (post)
CREATE TABLE IF NOT EXISTS `post` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `channel_id` BIGINT NULL COMMENT '所属频道ID, 匿名树洞帖为NULL',
    `user_id` BIGINT NOT NULL COMMENT '发帖用户ID',
    `content` TEXT NOT NULL COMMENT '帖子内容',
    `images` JSON COMMENT '图片URL列表 (JSON数组)',
    `video_url` VARCHAR(500) COMMENT '视频URL',
    `topic` VARCHAR(100) COMMENT '话题 (#话题#)',
    `mentioned_users` VARCHAR(500) COMMENT '@提及的用户名列表 (逗号分隔)',
    `status` TINYINT DEFAULT 1 COMMENT '状态: 1-正常, 0-待审核, 2-已删除',
    `view_count` INT DEFAULT 0 COMMENT '浏览量',
    `like_count` INT DEFAULT 0 COMMENT '点赞数',
    `comment_count` INT DEFAULT 0 COMMENT '评论数',
    `is_pinned` TINYINT DEFAULT 0 COMMENT '是否置顶: 0-否, 1-是',
    `is_anonymous` TINYINT DEFAULT 0 COMMENT '是否匿名: 0-否, 1-是',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '发布时间',
    `expire_time` DATETIME COMMENT '过期时间, NULL表示永不过期',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX `idx_channel_id` (`channel_id`),
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_create_time` (`create_time`),
    INDEX `idx_hot_posts` (`status`, `create_time`, `like_count`, `comment_count`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='帖子表';

-- 5. 点赞表 (post_like)
CREATE TABLE IF NOT EXISTS `post_like` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `post_id` BIGINT NOT NULL COMMENT '帖子ID',
    `user_id` BIGINT NOT NULL COMMENT '点赞用户ID',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '点赞时间',
    UNIQUE KEY `uk_post_user` (`post_id`, `user_id`),
    INDEX `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='点赞表';

-- 5b. 帖子收藏表 (post_favourite)
CREATE TABLE IF NOT EXISTS `post_favourite` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `post_id` BIGINT NOT NULL COMMENT '帖子ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '收藏时间',
    UNIQUE KEY `uk_fav_post_user` (`post_id`, `user_id`),
    INDEX `idx_fav_user_id` (`user_id`),
    INDEX `idx_fav_post_id` (`post_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='帖子收藏表';

-- 6. 评论表 (comment)
CREATE TABLE IF NOT EXISTS `comment` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `post_id` BIGINT NOT NULL COMMENT '帖子ID',
    `user_id` BIGINT NOT NULL COMMENT '评论用户ID',
    `content` TEXT NOT NULL COMMENT '评论内容',
    `parent_id` BIGINT COMMENT '父评论ID (二级评论自关联)',
    `status` TINYINT DEFAULT 1 COMMENT '状态: 1-正常, 0-待审核, 2-已删除',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '评论时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX `idx_post_id` (`post_id`),
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_parent_id` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='评论表';

-- 7. 好友关系表 (friendship)
CREATE TABLE IF NOT EXISTS `friendship` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `user_id` BIGINT NOT NULL COMMENT '发起方用户ID',
    `friend_id` BIGINT NOT NULL COMMENT '接收方用户ID',
    `status` TINYINT DEFAULT 0 COMMENT '状态: 0-待处理, 1-已同意, 2-已拒绝',
    `apply_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '申请时间',
    `approve_time` DATETIME COMMENT '处理时间',
    UNIQUE KEY `uk_user_friend` (`user_id`, `friend_id`),
    INDEX `idx_friend_id` (`friend_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='好友关系表';

-- 8. 聊天消息表 (message)
CREATE TABLE IF NOT EXISTS `message` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `sender_id` BIGINT NOT NULL COMMENT '发送方用户ID',
    `receiver_id` BIGINT NOT NULL COMMENT '接收方用户ID',
    `content` TEXT NOT NULL COMMENT '消息内容',
    `type` TINYINT DEFAULT 1 COMMENT '类型: 1-文字, 2-表情, 3-图片, 4-视频',
    `status` TINYINT DEFAULT 1 COMMENT '状态: 1-正常, 2-已撤回',
    `is_read` TINYINT DEFAULT 0 COMMENT '是否已读: 0-未读, 1-已读',
    `read_time` DATETIME COMMENT '读取时间',
    `read_at` DATETIME COMMENT '已读时间',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '发送时间',
    INDEX `idx_sender_receiver` (`sender_id`, `receiver_id`),
    INDEX `idx_receiver_sender` (`receiver_id`, `sender_id`),
    INDEX `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='聊天消息表';

-- 9. 系统通知表 (notification)
CREATE TABLE IF NOT EXISTS `notification` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `user_id` BIGINT NOT NULL COMMENT '接收用户ID',
    `type` VARCHAR(50) NOT NULL COMMENT '通知类型: friend_request, friend_approved, comment, like, mention, channel_approved',
    `title` VARCHAR(100) COMMENT '通知标题',
    `content` TEXT COMMENT '通知内容',
    `related_id` VARCHAR(100) COMMENT '关联业务ID',
    `is_read` TINYINT DEFAULT 0 COMMENT '是否已读: 0-未读, 1-已读',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_is_read` (`is_read`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统通知表';

-- 10. 操作审计日志表 (operation_log)
CREATE TABLE IF NOT EXISTS `operation_log` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `user_id` BIGINT NOT NULL COMMENT '操作用户ID',
    `module` VARCHAR(50) COMMENT '操作模块',
    `action` VARCHAR(50) COMMENT '操作动作',
    `description` TEXT COMMENT '操作描述',
    `request_method` VARCHAR(10) COMMENT '请求方法',
    `request_url` VARCHAR(500) COMMENT '请求URL',
    `ip_address` VARCHAR(50) COMMENT 'IP地址',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '操作时间',
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='操作审计日志表';

-- 11. 举报表 (report)
CREATE TABLE IF NOT EXISTS `report` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `reporter_id` BIGINT NOT NULL COMMENT '举报人用户ID',
    `target_type` VARCHAR(20) NOT NULL COMMENT '举报对象类型: post, comment, message',
    `target_id` BIGINT NOT NULL COMMENT '举报对象ID',
    `reason` VARCHAR(500) COMMENT '举报原因',
    `status` TINYINT DEFAULT 0 COMMENT '处理状态: 0-待处理, 1-已通过(确认违规), 2-已驳回',
    `handler_id` BIGINT COMMENT '处理人管理员ID',
    `handle_note` VARCHAR(500) COMMENT '处理备注',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '举报时间',
    `handle_time` DATETIME COMMENT '处理时间',
    INDEX `idx_reporter_id` (`reporter_id`),
    INDEX `idx_target` (`target_type`, `target_id`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='举报表';

-- 12. 登录设备记录表 (login_device)
CREATE TABLE IF NOT EXISTS `login_device` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `device_name` VARCHAR(100) COMMENT '设备名称',
    `ip_address` VARCHAR(50) COMMENT '登录IP',
    `login_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '登录时间',
    `last_active_time` DATETIME COMMENT '最后活跃时间',
    INDEX `idx_ld_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='登录设备记录表';

-- ===================== 数据库迁移（兼容已有表结构） =====================
-- 为已存在的表补充后续版本新增的字段（continue-on-error 已开启，重复执行不报错）

ALTER TABLE `user` ADD COLUMN `real_name` VARCHAR(20) COMMENT '真实姓名' AFTER `username`;
ALTER TABLE `user` ADD COLUMN `phone` VARCHAR(20) COMMENT '手机号' AFTER `real_name`;
ALTER TABLE `post` ADD COLUMN `topic` VARCHAR(100) COMMENT '话题 (#话题#)' AFTER `video_url`;
ALTER TABLE `post` ADD COLUMN `is_pinned` TINYINT DEFAULT 0 COMMENT '是否置顶: 0-否, 1-是' AFTER `comment_count`;
ALTER TABLE `channel_member` ADD COLUMN `approve_user_id` BIGINT COMMENT '审核人用户ID' AFTER `approve_time`;
ALTER TABLE `channel_member` ADD COLUMN `is_muted` TINYINT DEFAULT 0 COMMENT '是否禁言: 0-否, 1-是' AFTER `role`;
ALTER TABLE `gallery` ADD COLUMN `channel_id` BIGINT DEFAULT 0 COMMENT '所属频道ID 0代表全局' AFTER `user_id`;
ALTER TABLE `user` ADD COLUMN `email_notify` TINYINT DEFAULT 1 COMMENT '邮件通知开关: 1-开启, 0-关闭' AFTER `avatar`;
ALTER TABLE `message` ADD COLUMN `is_read` TINYINT DEFAULT 0 COMMENT '是否已读: 0-未读, 1-已读' AFTER `status`;
ALTER TABLE `message` ADD COLUMN `read_time` DATETIME COMMENT '读取时间' AFTER `is_read`;
ALTER TABLE `message` ADD COLUMN `read_at` DATETIME COMMENT '已读时间' AFTER `read_time`;

-- 为post表添加过期时间字段（树洞告白24小时自动过期）
ALTER TABLE `post` ADD COLUMN `expire_time` DATETIME COMMENT '过期时间, NULL表示永不过期' AFTER `create_time`;

-- 为热门帖子查询添加复合索引（性能优化）
ALTER TABLE `post` ADD INDEX `idx_hot_posts` (`status`, `create_time`, `like_count`, `comment_count`);

-- 创建帖子收藏表（如果不存在）
CREATE TABLE IF NOT EXISTS `post_favourite` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `post_id` BIGINT NOT NULL COMMENT '帖子ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '收藏时间',
    UNIQUE KEY `uk_fav_post_user` (`post_id`, `user_id`),
    INDEX `idx_fav_user_id` (`user_id`),
    INDEX `idx_fav_post_id` (`post_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='帖子收藏表';

-- 创建用户告白解开记录表（用于跨平台同步解开状态）
CREATE TABLE IF NOT EXISTS `post_reveal_record` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `post_id` BIGINT NOT NULL COMMENT '帖子ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `reveal_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '解开时间',
    UNIQUE KEY `uk_post_user` (`post_id`, `user_id`),
    INDEX `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户告白解开记录表';

-- 13. 群聊消息表 (group_message)
CREATE TABLE IF NOT EXISTS `group_message` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `channel_id` BIGINT NOT NULL COMMENT '频道ID',
    `sender_id` BIGINT NOT NULL COMMENT '发送者ID',
    `content` TEXT COMMENT '文字内容',
    `media_url` VARCHAR(500) COMMENT '媒体文件URL',
    `msg_type` TINYINT DEFAULT 1 COMMENT '类型: 1-文字, 2-图片, 3-视频',
    `status` TINYINT DEFAULT 1 COMMENT '状态: 1-正常, 2-已撤回',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '发送时间',
    INDEX `idx_gm_channel_id` (`channel_id`),
    INDEX `idx_gm_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='群聊消息表';

-- 14. 画廊表 (gallery)
CREATE TABLE IF NOT EXISTS `gallery` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `user_id` BIGINT NOT NULL COMMENT '上传用户ID',
    `channel_id` BIGINT DEFAULT 0 COMMENT '所属频道ID 0代表全局',
    `image_url` VARCHAR(500) NOT NULL COMMENT '图片URL',
    `title` VARCHAR(200) DEFAULT '' COMMENT '标题',
    `description` TEXT COMMENT '描述',
    `status` TINYINT DEFAULT 1 COMMENT '状态: 1-正常, 0-待审核, 2-违规下架',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX `idx_gallery_user_id` (`user_id`),
    INDEX `idx_gallery_status` (`status`),
    INDEX `idx_gallery_channel_id` (`channel_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='画廊表';

-- 15. 画廊点赞表 (gallery_like)
CREATE TABLE IF NOT EXISTS `gallery_like` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `gallery_id` BIGINT NOT NULL COMMENT '画作ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    UNIQUE KEY `uk_gallery_user` (`gallery_id`, `user_id`),
    INDEX `idx_gallery_like_gallery_id` (`gallery_id`),
    INDEX `idx_gallery_like_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='画廊点赞表';

-- 16. 画廊评论表 (gallery_comment)
CREATE TABLE IF NOT EXISTS `gallery_comment` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `gallery_id` BIGINT NOT NULL COMMENT '画作ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `content` TEXT NOT NULL COMMENT '评论内容',
    `status` TINYINT DEFAULT 1 COMMENT '状态: 1-正常, 0-待审核, 2-已删除',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX `idx_gallery_comment_gallery_id` (`gallery_id`),
    INDEX `idx_gallery_comment_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='画廊评论表';

-- 17. 徽章定义表 (badge)
CREATE TABLE IF NOT EXISTS `badge` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `name` VARCHAR(50) NOT NULL COMMENT '徽章名称',
    `icon` VARCHAR(100) COMMENT '徽章图标 (emoji或URL)',
    `description` VARCHAR(200) COMMENT '徽章描述',
    `condition_type` VARCHAR(30) NOT NULL COMMENT '条件类型: like_count, post_count, comment_count',
    `condition_value` INT NOT NULL COMMENT '条件阈值'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='徽章定义表';

-- 18. 用户徽章关联表 (user_badge)
CREATE TABLE IF NOT EXISTS `user_badge` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `badge_id` BIGINT NOT NULL COMMENT '徽章ID',
    `earned_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '获得时间',
    UNIQUE KEY `uk_user_badge` (`user_id`, `badge_id`),
    INDEX `idx_user_badge_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户徽章关联表';

-- 19. 公告表 (announcement)
CREATE TABLE IF NOT EXISTS `announcement` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `title` VARCHAR(200) NOT NULL COMMENT '公告标题',
    `content` TEXT NOT NULL COMMENT '公告内容',
    `type` VARCHAR(20) DEFAULT 'scratch' COMMENT '类型: scratch (刮刮乐), blindbox (盲盒)',
    `cover_image` VARCHAR(255) COMMENT '封面图片URL',
    `created_by` BIGINT COMMENT '创建者用户ID',
    `channel_id` BIGINT COMMENT '关联频道ID (可选)',
    `status` TINYINT DEFAULT 1 COMMENT '状态: 0-待发布, 1-活跃, 2-已过期',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX `idx_announcement_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='公告表';

-- 初始化徽章数据
INSERT IGNORE INTO `badge` (`name`, `icon`, `description`, `condition_type`, `condition_value`) VALUES
('初出茅庐', '🌱', '发布第一篇帖子', 'post_count', 1),
('小有名气', '⭐', '累计获得10个赞', 'like_count', 10),
('热帖达人', '🔥', '累计获得100个赞', 'like_count', 100),
('社区之星', '🌟', '累计获得500个赞', 'like_count', 500),
('活跃作者', '📝', '发布10篇帖子', 'post_count', 10),
('高产达人', '📚', '发布50篇帖子', 'post_count', 50);