-- ============================================
-- Camp Channel V2.0 数据库迁移脚本
-- 执行日期: 2026-05-31
-- 说明: 实现 V2.0 功能所需的数据库变更
-- ============================================

-- 1. 创建帖子收藏表 (post_favourite)
CREATE TABLE IF NOT EXISTS `post_favourite` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `post_id` BIGINT NOT NULL COMMENT '帖子ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '收藏时间',
    UNIQUE KEY `uk_fav_post_user` (`post_id`, `user_id`),
    INDEX `idx_fav_user_id` (`user_id`),
    INDEX `idx_fav_post_id` (`post_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='帖子收藏表';

-- 2. post 表增加置顶字段
ALTER TABLE `post` 
ADD COLUMN `is_pinned` TINYINT DEFAULT 0 COMMENT '是否置顶: 0-否, 1-是' AFTER `comment_count`;

-- 3. message 表增加 read_at 字段（统一字段命名）
-- 注意：如果 read_at 已存在则跳过
ALTER TABLE `message` 
ADD COLUMN `read_at` DATETIME COMMENT '已读时间' AFTER `read_time`;

-- 4. channel_member 表增加禁言字段
ALTER TABLE `channel_member` 
ADD COLUMN `is_muted` TINYINT DEFAULT 0 COMMENT '是否禁言: 0-否, 1-是' AFTER `role`;

-- 5. 为热门帖子查询添加复合索引（性能优化）
ALTER TABLE `post` 
ADD INDEX `idx_hot_posts` (`status`, `create_time`, `like_count`, `comment_count`);

-- 6. 为帖子搜索添加全文索引（如果 MySQL 版本支持）
-- 注意：全文索引仅在 InnoDB + MySQL 5.6+ 支持
ALTER TABLE `post` 
ADD FULLTEXT INDEX `ft_post_search` (`content`, `topic`) WITH PARSER ngram;

-- ============================================
-- 验证迁移结果
-- ============================================
-- 检查表是否创建成功
-- SHOW TABLES LIKE 'post_favourite';

-- 检查字段是否添加成功
-- SHOW COLUMNS FROM `post` LIKE 'is_pinned';
-- SHOW COLUMNS FROM `message` LIKE 'read_at';
-- SHOW COLUMNS FROM `channel_member` LIKE 'is_muted';

-- 检查索引是否创建成功
-- SHOW INDEX FROM `post_favourite`;
-- SHOW INDEX FROM `post`;

-- ============================================
-- 7. 创建帖子草稿表 (post_draft)
-- ============================================
CREATE TABLE IF NOT EXISTS `post_draft` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `channel_id` BIGINT COMMENT '频道ID（选填）',
    `content` TEXT COMMENT '草稿内容',
    `images` VARCHAR(2000) COMMENT '图片URL列表，逗号分隔',
    `video_url` VARCHAR(500) COMMENT '视频URL',
    `topic` VARCHAR(100) COMMENT '话题',
    `is_anonymous` TINYINT DEFAULT 0 COMMENT '是否匿名: 0-否, 1-是',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX `idx_draft_user_id` (`user_id`),
    INDEX `idx_draft_update_time` (`update_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='帖子草稿表';

-- ============================================
-- 8. 性能优化索引 (V2.0)
-- ============================================

-- 通知表: 用户未读通知复合索引
ALTER TABLE `notification`
ADD INDEX `idx_user_unread` (`user_id`, `is_read`, `create_time`);

-- 消息表: 未读消息索引
ALTER TABLE `message`
ADD INDEX `idx_unread_msg` (`receiver_id`, `is_read`);

-- 评论表: 帖子评论列表复合索引
ALTER TABLE `comment`
ADD INDEX `idx_post_comments` (`post_id`, `status`, `create_time`);

-- 帖子表: 用户发帖查询索引
ALTER TABLE `post`
ADD INDEX `idx_user_posts` (`user_id`, `status`, `create_time`);

-- 帖子表: 树洞匿名帖查询索引
ALTER TABLE `post`
ADD INDEX `idx_anonymous_posts` (`is_anonymous`, `status`, `create_time`);
