package com.gdmec.campchannel.config;

import com.gdmec.campchannel.common.utils.JwtUtils;
import com.gdmec.campchannel.common.utils.WebSocketRateLimiter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.stereotype.Component;

import java.util.List;

@Slf4j
@Component
public class WebSocketAuthInterceptor implements ChannelInterceptor {

    @Autowired
    private JwtUtils jwtUtils;

    @Autowired
    private WebSocketRateLimiter rateLimiter;

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);

        if (accessor != null && StompCommand.CONNECT.equals(accessor.getCommand())) {
            List<String> authHeaders = accessor.getNativeHeader("Authorization");
            if (authHeaders != null && !authHeaders.isEmpty()) {
                String token = authHeaders.get(0);
                if (token != null && !token.isEmpty()) {
                    try {
                        String rawToken = token.replace("Bearer ", "");
                        Long userId = jwtUtils.getClaimFromToken(rawToken, claims -> claims.get("userId", Long.class));
                        if (userId != null) {
                            final Long finalUserId = userId;
                            accessor.setUser(() -> finalUserId.toString());
                        }
                    } catch (Exception e) {
                        // Token invalid, connection will proceed without Principal
                    }
                }
            }
        }

        // 对 SEND 命令进行限流检查
        if (accessor != null && StompCommand.SEND.equals(accessor.getCommand())
                && accessor.getUser() != null) {
            try {
                Long userId = Long.parseLong(accessor.getUser().getName());
                if (!rateLimiter.allowSend(userId)) {
                    log.warn("WebSocket 消息被限流: userId={}", userId);
                    return null; // 丢弃消息
                }
            } catch (NumberFormatException ignored) {
            }
        }
        return message;
    }
}
