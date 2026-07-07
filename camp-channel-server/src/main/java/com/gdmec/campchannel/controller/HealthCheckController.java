package com.gdmec.campchannel.controller;

import com.gdmec.campchannel.common.api.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.sql.DataSource;
import java.sql.Connection;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * 健康检查端点，用于监控和运维
 */
@Tag(name = "系统监控模块", description = "提供健康检查、状态监控功能")
@Slf4j
@RestController
@RequestMapping("/actuator")
public class HealthCheckController {

    @Autowired
    private DataSource dataSource;

    @Autowired
    private RedisTemplate<String, Object> redisTemplate;

    @GetMapping("/health")
    @Operation(summary = "健康检查")
    public Result<Map<String, Object>> health() {
        Map<String, Object> health = new HashMap<>();
        health.put("status", "UP");
        health.put("timestamp", LocalDateTime.now().toString());

        health.put("database", checkDatabase());
        health.put("redis", checkRedis());

        boolean allUp = "UP".equals(health.get("database")) && "UP".equals(health.get("redis"));
        health.put("status", allUp ? "UP" : "DEGRADED");

        return Result.success(health);
    }

    private Map<String, Object> checkDatabase() {
        Map<String, Object> db = new HashMap<>();
        try (Connection conn = dataSource.getConnection()) {
            db.put("status", conn.isValid(2) ? "UP" : "DOWN");
            db.put("product", conn.getMetaData().getDatabaseProductName());
        } catch (Exception e) {
            log.warn("数据库健康检查失败: {}", e.getMessage());
            db.put("status", "DOWN");
            db.put("error", e.getMessage());
        }
        return db;
    }

    private Map<String, Object> checkRedis() {
        Map<String, Object> redis = new HashMap<>();
        try {
            String pong = redisTemplate.getConnectionFactory().getConnection().ping();
            redis.put("status", "PONG".equalsIgnoreCase(pong) ? "UP" : "DOWN");
        } catch (Exception e) {
            log.warn("Redis 健康检查失败: {}", e.getMessage());
            redis.put("status", "DOWN");
            redis.put("error", e.getMessage());
        }
        return redis;
    }
}
