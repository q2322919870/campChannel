package com.gdmec.campchannel.controller;

import com.gdmec.campchannel.common.api.ErrorCode;
import com.gdmec.campchannel.common.api.Result;
import com.gdmec.campchannel.common.utils.JwtUtils;
import com.gdmec.campchannel.common.utils.RedisUtils;
import com.gdmec.campchannel.entity.LoginDevice;
import com.gdmec.campchannel.mapper.LoginDeviceMapper;
import com.gdmec.campchannel.security.SecurityUser;
import com.gdmec.campchannel.entity.User;
import com.gdmec.campchannel.service.EmailService;
import com.gdmec.campchannel.service.UserService;
import jakarta.servlet.http.HttpServletRequest;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;

/**
 * 身份认证控制器
 */
@Tag(name = "身份认证模块", description = "提供用户登录与会话初始化接口")
@Slf4j
@RestController
@RequestMapping("/auth")
public class AuthController {

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private JwtUtils jwtUtils;

    @Autowired
    private RedisUtils redisUtils;

    @Autowired
    private UserService userService;

    @Autowired
    private EmailService emailService;

    @Autowired
    private LoginDeviceMapper loginDeviceMapper;

    @PostMapping("/send-code")
    @Operation(summary = "发送注册验证码")
    public Result<Void> sendVerificationCode(@RequestBody SendCodeRequest request) {
        if (!StringUtils.hasText(request.getEmail())) {
            return Result.failed(ErrorCode.BAD_REQUEST, "邮箱不能为空");
        }
        if (!request.getEmail().endsWith("@stu.gdmec.edu.cn")) {
            return Result.failed(ErrorCode.INVALID_EMAIL_SUFFIX);
        }

        if (userService.getUserByEmail(request.getEmail()) != null) {
            return Result.failed(ErrorCode.BAD_REQUEST, "该邮箱已被注册");
        }

        String rateLimitKey = "verify_code_rate:" + request.getEmail();
        if (redisUtils.hasKey(rateLimitKey)) {
            return Result.failed(ErrorCode.TOO_MANY_REQUESTS, "验证码已发送，请60秒后再试");
        }

        String code = String.format("%06d", new Random().nextInt(1000000));

        String codeKey = "verify_code:" + request.getEmail();
        redisUtils.set(codeKey, code, 300);

        redisUtils.set(rateLimitKey, "1", 60);

        emailService.sendVerificationCode(request.getEmail(), code);
        log.info("验证码已发送至: {}, code: {}", request.getEmail(), code);

        return Result.success("验证码已发送至您的邮箱", null);
    }

    @PostMapping("/register")
    @Operation(summary = "用户注册（需先发送验证码）")
    public Result<User> register(@RequestBody RegisterRequest registerRequest) {
        log.info("用户尝试注册: {}", registerRequest.getEmail());

        if (!StringUtils.hasText(registerRequest.getEmail()) || !StringUtils.hasText(registerRequest.getPassword()) || !StringUtils.hasText(registerRequest.getUsername()) || !StringUtils.hasText(registerRequest.getCode())) {
            return Result.failed(ErrorCode.BAD_REQUEST, "邮箱、用户名、密码和验证码不能为空");
        }

        String codeKey = "verify_code:" + registerRequest.getEmail();
        String savedCode = (String) redisUtils.get(codeKey);
        if (savedCode == null) {
            return Result.failed(ErrorCode.BAD_REQUEST, "验证码已过期，请重新发送");
        }
        if (!savedCode.equals(registerRequest.getCode())) {
            return Result.failed(ErrorCode.BAD_REQUEST, "验证码错误");
        }

        redisUtils.del(codeKey);

        User user = userService.register(
                registerRequest.getEmail(),
                registerRequest.getUsername(),
                registerRequest.getPassword(),
                registerRequest.getRealName(),
                registerRequest.getPhone()
        );
        user.setPassword(null);
        return Result.success("注册成功", user);
    }

    @PostMapping("/login")
    @Operation(summary = "用户登录")
    public Result<Map<String, Object>> login(@RequestBody LoginRequest loginRequest, HttpServletRequest request) {
        String principal = StringUtils.hasText(loginRequest.getEmail()) ? loginRequest.getEmail() : loginRequest.getUsername();
        log.info("用户尝试登录: {}", principal);

        if (!StringUtils.hasText(principal)) {
            return Result.failed(ErrorCode.BAD_REQUEST, "邮箱或用户名不能为空");
        }
        if (!StringUtils.hasText(loginRequest.getPassword())) {
            return Result.failed(ErrorCode.BAD_REQUEST, "密码不能为空");
        }

        // 广东机电职业技术学院邮箱后缀强校验
        if (StringUtils.hasText(loginRequest.getEmail()) && !loginRequest.getEmail().endsWith("@stu.gdmec.edu.cn")) {
            return Result.failed(ErrorCode.INVALID_EMAIL_SUFFIX);
        }

        // 检查密码错误次数限制 (风控逻辑)
        String errorCountKey = "pwd_err_count:" + principal;
        Integer errCount = (Integer) redisUtils.get(errorCountKey);
        if (errCount != null && errCount >= 5) {
            return Result.failed(ErrorCode.FORBIDDEN, "密码错误次数过多，账号已锁定，请30分钟后再试");
        }

        // 使用 Spring Security 进行凭证检验
        // 注意：此处传入邮箱或用户名作为 Username 用于 Security 校验
        UsernamePasswordAuthenticationToken authenticationToken =
                new UsernamePasswordAuthenticationToken(principal, loginRequest.getPassword());

        SecurityUser securityUser;
        try {
            Authentication authentication = authenticationManager.authenticate(authenticationToken);
            securityUser = (SecurityUser) authentication.getPrincipal();
            // 登录成功，清除错误次数
            redisUtils.del(errorCountKey);
        } catch (AuthenticationException e) {
            // 登录失败，增加错误次数，锁定 30 分钟 (1800 秒)
            if (errCount == null) {
                redisUtils.set(errorCountKey, 1, 1800);
            } else {
                redisUtils.set(errorCountKey, errCount + 1, 1800);
            }
            log.warn("用户登录失败: {}, 原因: {}", principal, e.getMessage());
            return Result.failed(ErrorCode.PASSWORD_ERROR, "邮箱/用户名或密码错误，连续错误5次将锁定账号30分钟");
        }

        // 1. 生成 JWT 令牌 (携带userId)
        Map<String, Object> claims = new HashMap<>();
        claims.put("userId", securityUser.getId());
        String token = jwtUtils.generateToken(securityUser.getUsername(), claims);

        // 2. 实现单设备登录互踢逻辑
        // 将当前用户的最新 Token 写入 Redis 缓存。新登录 Token 将覆盖旧 Token，原设备再次请求时将因为 Token 不一致被下线
        String activeTokenKey = "active_token:" + securityUser.getUsername();
        redisUtils.set(activeTokenKey, token, jwtUtils.getExpiration());

        // 3. 构建返回数据
        Map<String, Object> responseData = new HashMap<>();
        responseData.put("token", jwtUtils.getTokenStartWith() + token);
        responseData.put("accessToken", jwtUtils.getTokenStartWith() + token);
        responseData.put("userId", securityUser.getId());
        responseData.put("username", securityUser.getUsername());
        responseData.put("email", securityUser.getEmail());
        responseData.put("role", securityUser.getRole());
        responseData.put("avatar", securityUser.getAvatar());

        // 记录登录设备
        try {
            LoginDevice device = new LoginDevice();
            device.setUserId(securityUser.getId());
            device.setDeviceName(request.getHeader("User-Agent") != null ?
                    request.getHeader("User-Agent").substring(0, Math.min(request.getHeader("User-Agent").length(), 100)) : "未知设备");
            device.setIpAddress(request.getRemoteAddr());
            device.setLoginTime(LocalDateTime.now());
            device.setLastActiveTime(LocalDateTime.now());
            loginDeviceMapper.insert(device);
        } catch (Exception e) {
            log.warn("记录登录设备失败", e);
        }

        log.info("用户 [{}] 登录成功，Token 已生成", securityUser.getUsername());
        return Result.success("登录成功", responseData);
    }

    /**
     * 登录请求体 DTO
     */
    @Data
    public static class LoginRequest {
        private String email;

        private String username;

        private String password;
    }

    /**
     * 发送验证码请求体 DTO
     */
    @Data
    public static class SendCodeRequest {
        private String email;
    }

    /**
     * 注册请求体 DTO
     */
    @Data
    public static class RegisterRequest {
        private String email;

        private String username;

        private String password;

        private String code;

        private String realName;

        private String phone;
    }
}
