package com.gdmec.campchannel.config;

import com.gdmec.campchannel.common.utils.RedisUtils;
import com.gdmec.campchannel.entity.User;
import com.gdmec.campchannel.service.FriendshipService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.event.EventListener;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.messaging.SessionConnectedEvent;
import org.springframework.web.socket.messaging.SessionDisconnectEvent;

import java.security.Principal;
import java.util.List;
import java.util.Map;

@Component
public class WebSocketEventListener {

    @Autowired
    private RedisUtils redisUtils;

    @Autowired
    private FriendshipService friendshipService;

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    private static final String ONLINE_PREFIX = "user_online:";

    @EventListener
    public void handleWebSocketConnectListener(SessionConnectedEvent event) {
        StompHeaderAccessor headerAccessor = StompHeaderAccessor.wrap(event.getMessage());
        Principal principal = headerAccessor.getUser();
        if (principal != null) {
            try {
                Long userId = Long.parseLong(principal.getName());
                redisUtils.set(ONLINE_PREFIX + userId, "1", 300); // 5 min TTL
                // Notify friends via raw WebSocket about online status
                notifyFriendsViaRawWs(userId, true);
            } catch (NumberFormatException e) {
                // Ignore non-numeric user names
            }
        }
    }

    @EventListener
    public void handleWebSocketDisconnectListener(SessionDisconnectEvent event) {
        StompHeaderAccessor headerAccessor = StompHeaderAccessor.wrap(event.getMessage());
        Principal principal = headerAccessor.getUser();
        if (principal != null) {
            try {
                Long userId = Long.parseLong(principal.getName());
                redisUtils.del(ONLINE_PREFIX + userId);
                // Notify friends via raw WebSocket about offline status
                notifyFriendsViaRawWs(userId, false);
            } catch (NumberFormatException e) {
                // Ignore
            }
        }
    }

    public static boolean isUserOnline(RedisUtils redis, Long userId) {
        return redis.get(ONLINE_PREFIX + userId) != null;
    }

    private void notifyFriendsViaRawWs(Long userId, boolean online) {
        try {
            List<User> friends = friendshipService.getFriends(userId);
            if (friends.isEmpty()) return;
            
            // Build payload for both raw WS and STOMP
            Map<String, Object> payload = RawWebSocketHandler.buildOnlineStatusPayload(userId, online);
            
            // Notify via raw WebSocket (for Flutter)
            for (User friend : friends) {
                RawWebSocketHandler.pushToUser(friend.getId(), payload);
            }
            
            // Notify via STOMP (for PC web) - broadcast to all friends' user queues
            for (User friend : friends) {
                messagingTemplate.convertAndSendToUser(
                    friend.getId().toString(), "/queue/online-status", payload);
            }
        } catch (Exception e) {
            // Silently ignore friend notification errors
        }
    }
}
