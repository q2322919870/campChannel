package com.gdmec.campchannel.common.utils;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.TimeUnit;

/**
 * Redis 工具类，封装常用操作并实现滑动窗口限流
 */
@Component
public class RedisUtils {

    @Autowired
    private RedisTemplate<String, Object> redisTemplate;

    // ============================= Common =============================

    public boolean expire(String key, long time) {
        try {
            if (time > 0) {
                redisTemplate.expire(key, time, TimeUnit.SECONDS);
            }
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public Long getExpire(String key) {
        try {
            return redisTemplate.getExpire(key, TimeUnit.SECONDS);
        } catch (Exception e) {
            return -1L;
        }
    }

    public boolean hasKey(String key) {
        try {
            return Boolean.TRUE.equals(redisTemplate.hasKey(key));
        } catch (Exception e) {
            return false;
        }
    }

    public void del(String... key) {
        try {
            if (key != null && key.length > 0) {
                if (key.length == 1) {
                    redisTemplate.delete(key[0]);
                } else {
                    redisTemplate.delete(List.of(key));
                }
            }
        } catch (Exception e) {
            // 容错处理
        }
    }

    // ============================= String =============================

    public Object get(String key) {
        try {
            return key == null ? null : redisTemplate.opsForValue().get(key);
        } catch (Exception e) {
            return null;
        }
    }

    public boolean set(String key, Object value) {
        try {
            redisTemplate.opsForValue().set(key, value);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public boolean set(String key, Object value, long time) {
        try {
            if (time > 0) {
                redisTemplate.opsForValue().set(key, value, time, TimeUnit.SECONDS);
            } else {
                set(key, value);
            }
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public Long incr(String key) {
        try {
            return redisTemplate.opsForValue().increment(key);
        } catch (Exception e) {
            return null;
        }
    }

    // ============================= Map =============================

    public Object hget(String key, String item) {
        try {
            return redisTemplate.opsForHash().get(key, item);
        } catch (Exception e) {
            return null;
        }
    }

    public Map<Object, Object> hmget(String key) {
        try {
            return redisTemplate.opsForHash().entries(key);
        } catch (Exception e) {
            return new java.util.HashMap<>();
        }
    }

    public boolean hmset(String key, Map<String, Object> map) {
        try {
            redisTemplate.opsForHash().putAll(key, map);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    // ============================= Sliding Window Rate Limiter =============================

    /**
     * 滑动窗口限流算法
     *
     * @param key           限流唯一标识（如：rate_limit:user:123:post）
     * @param maxCount      窗口期内最大允许次数
     * @param windowSeconds 窗口期长度（秒）
     * @return 是否允许操作（true: 允许, false: 被限流）
     */
    public boolean isAllowedRateLimit(String key, int maxCount, int windowSeconds) {
        long now = System.currentTimeMillis();
        long start = now - (windowSeconds * 1000L);

        try {
            // 1. 移除窗口期之前的过期请求记录
            redisTemplate.opsForZSet().removeRangeByScore(key, 0, start);

            // 2. 统计当前窗口期内的请求数量
            Long count = redisTemplate.opsForZSet().zCard(key);

            if (count != null && count >= maxCount) {
                // 超过阈值，不予放行
                return false;
            }

            // 3. 记录本次请求
            redisTemplate.opsForZSet().add(key, now, now);

            // 4. 更新 Key 的生存时间，防冷数据长期驻留 Redis
            redisTemplate.expire(key, windowSeconds + 2, TimeUnit.SECONDS);
            return true;
        } catch (Exception e) {
            // 如果 Redis 出现异常，出于容错考虑，允许放行（或者降级报错，此处选择降级警告并放行）
            return true;
        }
    }
}
