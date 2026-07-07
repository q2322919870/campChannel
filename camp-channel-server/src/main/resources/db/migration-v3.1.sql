-- ============================================
-- Camp Channel V3.1 数据库索引优化迁移脚本
-- 执行日期: 2026-07-06
-- 说明: 为高频查询字段添加索引，提升查询性能
-- ============================================

-- 1. post 表索引优化
-- 用户发帖查询（GET /posts/my, GET /posts/user/{userId}）
CREATE INDEX IF NOT EXISTS `idx_post_user_id` ON `post`(`user_id`);
-- 频道帖子流查询（GET /posts/channel/{channelId}）
CREATE INDEX IF NOT EXISTS `idx_post_channel_status` ON `post`(`channel_id`, `status`);
-- 帖子状态查询（管理员审核）
CREATE INDEX IF NOT EXISTS `idx_post_status_create` ON `post`(`status`, `create_time`);
-- 匿名树洞帖子查询
CREATE INDEX IF NOT EXISTS `idx_post_anonymous_status` ON `post`(`is_anonymous`, `status`);

-- 2. comment 表索引优化
-- 帖子评论查询
CREATE INDEX IF NOT EXISTS `idx_comment_post_id` ON `comment`(`post_id`);
-- 评论状态查询（管理员审核）
CREATE INDEX IF NOT EXISTS `idx_comment_status_create` ON `comment`(`status`, `create_time`);

-- 3. message 表索引优化
-- 发送方消息查询
CREATE INDEX IF NOT EXISTS `idx_message_sender` ON `message`(`sender_id`);
-- 接收方消息查询
CREATE INDEX IF NOT EXISTS `idx_message_receiver` ON `message`(`receiver_id`);
-- 会话消息查询（双向）
CREATE INDEX IF NOT EXISTS `idx_message_conversation` ON `message`(`sender_id`, `receiver_id`, `create_time`);

-- 4. friendship 表索引优化
-- 用户好友关系查询
CREATE INDEX IF NOT EXISTS `idx_friendship_user_status` ON `friendship`(`user_id`, `status`);
-- 好友申请待处理查询
CREATE INDEX IF NOT EXISTS `idx_friendship_status` ON `friendship`(`status`);

-- 5. notification 表索引优化
-- 用户通知查询
CREATE INDEX IF NOT EXISTS `idx_notification_user_read` ON `notification`(`user_id`, `is_read`);
-- 通知分类查询
CREATE INDEX IF NOT EXISTS `idx_notification_user_category` ON `notification`(`user_id`, `category`);

-- 6. login_device 表索引优化
-- 用户设备查询
CREATE INDEX IF NOT EXISTS `idx_login_device_user` ON `login_device`(`user_id`);
-- 活跃用户统计（近7天）
CREATE INDEX IF NOT EXISTS `idx_login_device_active` ON `login_device`(`last_active_time`);

-- 7. post_like 表索引优化（如果存在）
CREATE INDEX IF NOT EXISTS `idx_post_like_user` ON `post_like`(`user_id`);
CREATE INDEX IF NOT EXISTS `idx_post_like_post` ON `post_like`(`post_id`);

-- 8. post_favourite 表索引优化（如果存在）
CREATE INDEX IF NOT EXISTS `idx_post_favourite_user` ON `post_favourite`(`user_id`);
CREATE INDEX IF NOT EXISTS `idx_post_favourite_post` ON `post_favourite`(`post_id`);

-- 9. channel_member 表索引优化
CREATE INDEX IF NOT EXISTS `idx_channel_member_user_status` ON `channel_member`(`user_id`, `status`);
CREATE INDEX IF NOT EXISTS `idx_channel_member_channel` ON `channel_member`(`channel_id`);

-- 10. report 表索引优化
CREATE INDEX IF NOT EXISTS `idx_report_status` ON `report`(`status`);
CREATE INDEX IF NOT EXISTS `idx_report_target` ON `report`(`target_type`, `target_id`);

-- 11. operation_log 表索引优化
CREATE INDEX IF NOT EXISTS `idx_operation_log_user` ON `operation_log`(`user_id`);
CREATE INDEX IF NOT EXISTS `idx_operation_log_module` ON `operation_log`(`module`);

-- ============================================
-- 验证迁移结果
-- ============================================
-- SHOW INDEX FROM `post`;
-- SHOW INDEX FROM `comment`;
-- SHOW INDEX FROM `message`;
-- SHOW INDEX FROM `friendship`;
-- SHOW INDEX FROM `notification`;
