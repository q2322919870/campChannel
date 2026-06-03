-- ============================================
-- Camp Channel V3.0 数据库迁移脚本
-- 执行日期: 2026-06-03
-- 说明: 实现 V3.0 P1 功能所需的数据库变更
-- ============================================

-- 1. post 表: 帖子编辑支持 (P1-5)
ALTER TABLE `post`
ADD COLUMN `edit_count` INT DEFAULT 0 COMMENT '编辑次数' AFTER `is_pinned`;

ALTER TABLE `post`
ADD COLUMN `last_edit_time` DATETIME COMMENT '最后编辑时间' AFTER `edit_count`;

-- 2. comment 表: 评论点赞计数 (P1-6)
ALTER TABLE `comment`
ADD COLUMN `like_count` INT DEFAULT 0 COMMENT '点赞数' AFTER `status`;

-- 3. 评论点赞表 (P1-6)
CREATE TABLE IF NOT EXISTS `comment_like` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `comment_id` BIGINT NOT NULL COMMENT '评论ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '点赞时间',
    UNIQUE KEY `uk_cl_comment_user` (`comment_id`, `user_id`),
    INDEX `idx_cl_comment_id` (`comment_id`),
    INDEX `idx_cl_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='评论点赞表';

-- 4. 用户关注表 (P1-8)
CREATE TABLE IF NOT EXISTS `follow` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `follower_id` BIGINT NOT NULL COMMENT '关注者ID',
    `following_id` BIGINT NOT NULL COMMENT '被关注者ID',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '关注时间',
    UNIQUE KEY `uk_follow` (`follower_id`, `following_id`),
    INDEX `idx_follow_follower` (`follower_id`),
    INDEX `idx_follow_following` (`following_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户关注表';

-- 5. notification 表: 通知分类 (P1-9)
ALTER TABLE `notification`
ADD COLUMN `category` VARCHAR(20) DEFAULT 'interaction' COMMENT '通知分类: system, interaction, chat' AFTER `type`;

-- ============================================
-- 验证迁移结果
-- ============================================
-- SHOW COLUMNS FROM `post` LIKE 'edit_count';
-- SHOW COLUMNS FROM `post` LIKE 'last_edit_time';
-- SHOW COLUMNS FROM `comment` LIKE 'like_count';
-- SHOW TABLES LIKE 'comment_like';
-- SHOW TABLES LIKE 'follow';
-- SHOW COLUMNS FROM `notification` LIKE 'category';
