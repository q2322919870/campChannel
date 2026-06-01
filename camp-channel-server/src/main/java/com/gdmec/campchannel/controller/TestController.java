package com.gdmec.campchannel.controller;

import com.gdmec.campchannel.common.api.ErrorCode;
import com.gdmec.campchannel.common.api.Result;
import com.gdmec.campchannel.common.filter.SensitiveWordFilter;
import com.gdmec.campchannel.common.utils.RedisUtils;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

/**
 * 骨架功能集成测试控制器
 */
@Tag(name = "骨架功能验证测试", description = "用于验证 JWT 鉴权、Redis 限流和 DFA 敏感词过滤")
@RestController
@RequestMapping("/test")
public class TestController {

    @Autowired
    private SensitiveWordFilter sensitiveWordFilter;

    @Autowired
    private RedisUtils redisUtils;

    @GetMapping("/hello")
    @Operation(summary = "测试已受保护的凭证接口")
    public Result<Map<String, Object>> hello() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        Map<String, Object> data = new HashMap<>();
        data.put("username", authentication.getName());
        data.put("authorities", authentication.getAuthorities());
        data.put("status", "JWT 校验通过！后端骨架通信正常。");
        return Result.success(data);
    }

    @GetMapping("/rate-limit")
    @Operation(summary = "测试滑动窗口限流风控接口")
    public Result<Void> rateLimit(@RequestParam(defaultValue = "test_user") String userId) {
        String limitKey = "rate_limit:test:" + userId;
        // 限制：10秒内最多调用3次
        boolean allowed = redisUtils.isAllowedRateLimit(limitKey, 3, 10);
        if (!allowed) {
            return Result.failed(ErrorCode.TOO_MANY_REQUESTS, "触发滑动窗口限流：10秒内最多允许访问3次！");
        }
        return Result.success("访问成功！您在10秒内的" +
                "请求计数已被记录。");
    }

    @GetMapping("/sensitive-word")
    @Operation(summary = "测试敏感词 DFA 过滤接口")
    public Result<Map<String, Object>> filterSensitive(@RequestParam String text) {
        Map<String, Object> result = new HashMap<>();
        boolean contains = sensitiveWordFilter.contains(text);
        String filteredText = sensitiveWordFilter.filter(text);

        result.put("originalText", text);
        result.put("containsSensitiveWord", contains);
        result.put("filteredText", filteredText);

        return Result.success(result);
    }
}
