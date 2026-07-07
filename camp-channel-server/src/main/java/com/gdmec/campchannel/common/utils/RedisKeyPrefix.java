package com.gdmec.campchannel.common.utils;

/**
 * 统一 Redis 键名前缀规范，便于管理和清理
 */
public final class RedisKeyPrefix {

    private RedisKeyPrefix() {}

    public static final String USER_PREFIX = "camp:user:";
    public static final String POST_PREFIX = "camp:post:";
    public static final String SESSION_PREFIX = "camp:session:";
    public static final String RATE_LIMIT_PREFIX = "camp:ratelimit:";
    public static final String CACHE_PREFIX = "camp:cache:";
    public static final String WS_RATE_LIMIT_PREFIX = "camp:ws:ratelimit:";
    public static final String ACTIVE_TOKEN_PREFIX = "camp:active_token:";
    public static final String SENSITIVE_WORDS = "camp:sensitive_words";

    public static String user(String suffix) { return USER_PREFIX + suffix; }
    public static String post(String suffix) { return POST_PREFIX + suffix; }
    public static String rateLimit(String suffix) { return RATE_LIMIT_PREFIX + suffix; }
    public static String wsRateLimit(String suffix) { return WS_RATE_LIMIT_PREFIX + suffix; }
    public static String activeToken(String username) { return ACTIVE_TOKEN_PREFIX + username; }
}
