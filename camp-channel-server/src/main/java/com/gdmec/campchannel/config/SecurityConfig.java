package com.gdmec.campchannel.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gdmec.campchannel.common.api.ErrorCode;
import com.gdmec.campchannel.common.api.Result;
import com.gdmec.campchannel.security.JwtAuthenticationFilter;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import org.springframework.http.HttpMethod;
import java.io.IOException;
import java.util.Collections;
import java.util.List;

/**
 * Spring Security 6.x 安全配置类
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity // 启用方法级权限控制 (@PreAuthorize)
public class SecurityConfig {

    @Autowired
    private JwtAuthenticationFilter jwtAuthenticationFilter;

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration authenticationConfiguration) throws Exception {
        return authenticationConfiguration.getAuthenticationManager();
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                // 1. 关闭 CSRF 跨站防护（因为使用无状态的 JWT）
                .csrf(AbstractHttpConfigurer::disable)
                // 2. 启用 CORS 跨域支持
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                // 3. 配置端点访问权限约束
                .authorizeHttpRequests(auth -> auth
                        // 放行所有 OPTIONS 预检请求（解决跨域预检 401 拦截问题）
                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                        // 登录、注册等公开接口放行
                        .requestMatchers(
                                "/auth/login",
                                "/auth/register",
                                "/auth/send-code",
                                "/auth/refresh",
                                "/api/auth/login",
                                "/api/auth/register",
                                "/api/auth/send-code",
                                "/api/auth/refresh"
                        ).permitAll()
                        // WebSocket 端点放行（SockJS 会发起 HTTP 请求）
                        .requestMatchers("/ws/**", "/ws", "/api/ws/**").permitAll()
                        // 静态资源与本地文件服务放行（为本地模拟 OSS 预览使用）
                        .requestMatchers("/uploads/**", "/api/uploads/**").permitAll()
                        // 健康检查端点放行
                        .requestMatchers("/actuator/health", "/api/actuator/health").permitAll()
                        // Swagger-UI / OpenAPI 接口文档放行
                        .requestMatchers(
                                "/swagger-ui.html",
                                "/swagger-ui/**",
                                "/v3/api-docs/**",
                                "/api/swagger-ui.html",
                                "/api/swagger-ui/**",
                                "/api/v3/api-docs/**"
                        ).permitAll()
                        // 其他请求一律需要认证
                        .anyRequest().authenticated()
                )
                // 4. 将 Session 设置为无状态（Stateless）
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                // 5. 自定义异常处理逻辑，输出统一响应结构
                .exceptionHandling(exceptions -> exceptions
                        // 未登录或 Token 失效
                        .authenticationEntryPoint((request, response, authException) ->
                                writeErrorResponse(response, HttpServletResponse.SC_UNAUTHORIZED, ErrorCode.UNAUTHORIZED)
                        )
                        // 登录了但无对应角色权限
                        .accessDeniedHandler((request, response, accessDeniedException) ->
                                writeErrorResponse(response, HttpServletResponse.SC_FORBIDDEN, ErrorCode.FORBIDDEN)
                        )
                )
                // 6. 注册 JWT 拦截过滤器
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    /**
     * 跨域配置源
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        // 生产环境应明确指定允许的域名来源，例如：
        // config.setAllowedOriginPatterns(Collections.singletonList("https://yourdomain.com"));
        config.setAllowedOriginPatterns(Collections.singletonList("*")); // 开发环境允许所有来源
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"));
        config.setAllowedHeaders(List.of("*"));
        config.setAllowCredentials(true); // 允许携带 Cookie/Credentials
        config.setMaxAge(3600L); // 预检请求有效期（秒）

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }

    /**
     * 辅助向客户端写入 JSON 错误响应
     */
    private void writeErrorResponse(HttpServletResponse response, int httpStatus, ErrorCode errorCode) throws IOException {
        response.setStatus(httpStatus);
        response.setContentType("application/json;charset=UTF-8");
        Result<?> result = Result.failed(errorCode);
        ObjectMapper mapper = new ObjectMapper();
        response.getWriter().write(mapper.writeValueAsString(result));
    }
}
