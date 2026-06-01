package com.gdmec.campchannel.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gdmec.campchannel.common.api.ErrorCode;
import com.gdmec.campchannel.common.api.Result;
import com.gdmec.campchannel.common.utils.JwtUtils;
import com.gdmec.campchannel.common.utils.RedisUtils;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.MalformedJwtException;
import io.jsonwebtoken.security.SignatureException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * JWT 请求认证拦截过滤器
 */
@Slf4j
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    @Autowired
    private JwtUtils jwtUtils;

    @Autowired
    private RedisUtils redisUtils;

    @Autowired
    private CustomUserDetailsService userDetailsService;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        // 对 OPTIONS 预检请求直接放行，避免拦截并处理 JWT
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            response.setStatus(HttpServletResponse.SC_OK);
            filterChain.doFilter(request, response);
            return;
        }

        final String requestTokenHeader = request.getHeader(jwtUtils.getHeader());

        String username = null;
        String jwtToken = null;

        // JWT Token 的格式为 "Bearer token"
        if (requestTokenHeader != null && requestTokenHeader.startsWith(jwtUtils.getTokenStartWith())) {
            jwtToken = requestTokenHeader.substring(jwtUtils.getTokenStartWith().length());
            try {
                username = jwtUtils.getUsernameFromToken(jwtToken);
            } catch (IllegalArgumentException e) {
                log.warn("无法获取 JWT Token");
            } catch (ExpiredJwtException e) {
                log.warn("JWT Token 已过期");
            } catch (MalformedJwtException | SignatureException e) {
                log.warn("JWT Token 签名或结构错误");
            }
        }

        // 成功提取用户名且当前 Security 上下文中没有认证信息
        if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {
            UserDetails userDetails = this.userDetailsService.loadUserByUsername(username);

            // 1. 校验 Token 合法性
            if (jwtUtils.validateToken(jwtToken, userDetails)) {

                // 2. 核心校验：单设备登录互踢
                // 从 Redis 中查询当前用户有效的 Token
                String activeTokenKey = "active_token:" + username;
                String activeToken = (String) redisUtils.get(activeTokenKey);

                if (activeToken != null && !activeToken.equals(jwtToken)) {
                    // 发现当前请求 Token 与 Redis 记录的最新 Token 不一致，代表已被新设备顶下线
                    log.warn("用户 [{}] 的 Token 被踢出（异地登录）", username);
                    writeErrorResponse(response, ErrorCode.DEVICE_FORCE_LOGOUT);
                    return;
                }

                // 3. 构建 Authentication 并注入 Spring Security 上下文
                UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                        userDetails, null, userDetails.getAuthorities());
                authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                SecurityContextHolder.getContext().setAuthentication(authentication);
            }
        }

        filterChain.doFilter(request, response);
    }

    /**
     * 直接向响应写入 JSON 错误信息
     */
    private void writeErrorResponse(HttpServletResponse response, ErrorCode errorCode) throws IOException {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType("application/json;charset=UTF-8");
        Result<?> result = Result.failed(errorCode);
        ObjectMapper mapper = new ObjectMapper();
        response.getWriter().write(mapper.writeValueAsString(result));
    }
}
