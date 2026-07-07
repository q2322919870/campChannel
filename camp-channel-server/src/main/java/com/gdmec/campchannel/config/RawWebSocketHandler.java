package com.gdmec.campchannel.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gdmec.campchannel.common.utils.JwtUtils;
import com.gdmec.campchannel.common.utils.RedisUtils;
import com.gdmec.campchannel.entity.User;
import com.gdmec.campchannel.service.FriendshipService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.io.IOException;
import java.net.URI;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class RawWebSocketHandler extends TextWebSocketHandler {

    private static final Logger log = LoggerFactory.getLogger(RawWebSocketHandler.class);
    private static final ConcurrentHashMap<Long, WebSocketSession> userSessions = new ConcurrentHashMap<>();
    private static final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    private JwtUtils jwtUtils;

    @Autowired
    private RedisUtils redisUtils;

    @Autowired
    private FriendshipService friendshipService;

    private static final String ONLINE_PREFIX = "user_online:";

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        URI uri = session.getUri();
        if (uri == null) {
            session.close(CloseStatus.BAD_DATA);
            return;
        }
        String query = uri.getQuery();
        if (query == null || !query.startsWith("token=")) {
            session.close(CloseStatus.POLICY_VIOLATION);
            return;
        }
        String token = query.substring(6);
        if (token.isEmpty()) {
            session.close(CloseStatus.POLICY_VIOLATION);
            return;
        }
        try {
            Long userId = jwtUtils.getClaimFromToken(token, claims -> claims.get("userId", Long.class));
            if (userId == null) {
                session.close(CloseStatus.POLICY_VIOLATION);
                return;
            }
            userSessions.put(userId, session);
            session.getAttributes().put("userId", userId);
            redisUtils.set(ONLINE_PREFIX + userId, "1", 300);
            // Notify friends that this user is online
            notifyFriendsOnlineStatus(userId, true);
            log.info("Raw WS connected: userId={}", userId);
        } catch (Exception e) {
            log.warn("Raw WS auth failed: {}", e.getMessage());
            session.close(CloseStatus.POLICY_VIOLATION);
        }
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        try {
            Long userId = (Long) session.getAttributes().get("userId");
            if (userId != null) {
                String limitKey = "ws_rate_limit:" + userId;
                // Limit to 10 messages per 10 seconds
                if (!redisUtils.isAllowedRateLimit(limitKey, 10, 10)) {
                    log.warn("WS rate limit exceeded for userId={}", userId);
                    sendJson(session, Map.of("type", "error", "message", "发送消息过于频繁，请稍后再试"));
                    return;
                }
            }
            Map<String, Object> payload = objectMapper.readValue(message.getPayload(), Map.class);
            String type = (String) payload.getOrDefault("type", "");
            if ("ping".equals(type)) {
                sendJson(session, Map.of("type", "pong"));
            }
            // Other message types can be added as needed
        } catch (Exception e) {
            log.warn("Raw WS message error: {}", e.getMessage());
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        Long userId = (Long) session.getAttributes().get("userId");
        if (userId != null) {
            userSessions.remove(userId, session);
            // Only clear online status if no more sessions for this userId
            if (!userSessions.containsKey(userId)) {
                redisUtils.del(ONLINE_PREFIX + userId);
                notifyFriendsOnlineStatus(userId, false);
            }
            log.info("Raw WS disconnected: userId={}", userId);
        }
    }

    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) {
        Long userId = (Long) session.getAttributes().get("userId");
        if (userId != null) {
            userSessions.remove(userId, session);
            if (!userSessions.containsKey(userId)) {
                redisUtils.del(ONLINE_PREFIX + userId);
                notifyFriendsOnlineStatus(userId, false);
            }
        }
    }

    /**
     * Push a JSON payload to a specific user if they have an active raw WebSocket connection.
     */
    public static void pushToUser(Long userId, Map<String, Object> payload) {
        WebSocketSession session = userSessions.get(userId);
        if (session != null && session.isOpen()) {
            try {
                String json = objectMapper.writeValueAsString(payload);
                session.sendMessage(new TextMessage(json));
            } catch (IOException e) {
                log.warn("Raw WS push failed to userId={}: {}", userId, e.getMessage());
            }
        }
    }

    /**
     * Broadcast a JSON payload to a list of user IDs.
     */
    public static void pushToUsers(List<Long> userIds, Map<String, Object> payload) {
        for (Long uid : userIds) {
            pushToUser(uid, payload);
        }
    }

    /**
     * Build an online status payload.
     */
    public static Map<String, Object> buildOnlineStatusPayload(Long userId, boolean online) {
        return Map.of(
                "type", "online_status",
                "userId", userId,
                "online", online
        );
    }

    private void notifyFriendsOnlineStatus(Long userId, boolean online) {
        try {
            List<User> friends = friendshipService.getFriends(userId);
            if (friends.isEmpty()) return;
            Map<String, Object> payload = buildOnlineStatusPayload(userId, online);
            for (User friend : friends) {
                pushToUser(friend.getId(), payload);
            }
        } catch (Exception e) {
            log.warn("Failed to notify friends online status: {}", e.getMessage());
        }
    }

    private void sendJson(WebSocketSession session, Map<String, Object> payload) throws IOException {
        String json = objectMapper.writeValueAsString(payload);
        if (session.isOpen()) {
            session.sendMessage(new TextMessage(json));
        }
    }
}
