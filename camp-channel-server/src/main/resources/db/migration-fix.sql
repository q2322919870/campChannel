-- Manual migration script to fix missing columns
-- Run this if the automatic schema.sql migration didn't work

-- Add channel_id to gallery table if it doesn't exist
ALTER TABLE `gallery` ADD COLUMN IF NOT EXISTS `channel_id` BIGINT DEFAULT 0 COMMENT '所属频道ID 0代表全局' AFTER `user_id`;

-- Add mentioned_users to post table for @mention notifications
ALTER TABLE `post` ADD COLUMN IF NOT EXISTS `mentioned_users` VARCHAR(500) COMMENT '@提及的用户名列表 (逗号分隔)' AFTER `topic`;

-- Verify the columns were added
SELECT COLUMN_NAME, DATA_TYPE, COLUMN_DEFAULT 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'camp_channel' 
  AND TABLE_NAME IN ('gallery', 'post')
  AND COLUMN_NAME IN ('channel_id', 'mentioned_users');
