package com.gdmec.campchannel.common.utils;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

/**
 * WebSocket 消息限流器，基于 Redis 滑动窗口算法
 * 防止恶意用户发送大量消息造成服务器压力
 */
@Slf4j
@Component
public class WebSocketRateLimiter {

    @Autowired
    private RedisUtils redisUtils;

    /** 每秒最大消息数 */
    private static final int MAX_MESSAGES_PER_SECOND = 10;

    /** 窗口期长度（秒） */
    private static final int WINDOW_SECONDS = 1;

    /**
     * 检查用户是否允许发送消息
     * @param userId 用户ID
     * @return true 允许，false 被限流
     */
    public boolean allowSend(Long userId) {
        if (userId == null) {
            return false;
        }
        String key = RedisKeyPrefix.wsRateLimit("user:" + userId);
        boolean allowed = redisUtils.isAllowedRateLimit(key, MAX_MESSAGES_PER_SECOND, WINDOW_SECONDS);
        if (!allowed) {
            log.warn("WebSocket 限流触发: userId={} 超过 {} 条/秒", userId, MAX_MESSAGES_PER_SECOND);
        }
        return allowed;
    }
}
