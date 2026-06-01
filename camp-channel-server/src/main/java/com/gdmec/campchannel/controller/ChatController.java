package com.gdmec.campchannel.controller;

import com.gdmec.campchannel.common.api.Result;
import com.gdmec.campchannel.common.utils.RedisUtils;
import com.gdmec.campchannel.config.RawWebSocketHandler;
import com.gdmec.campchannel.config.WebSocketEventListener;
import com.gdmec.campchannel.entity.Message;
import com.gdmec.campchannel.security.SecurityUser;
import com.gdmec.campchannel.service.MessageService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import org.springframework.messaging.simp.SimpMessagingTemplate;

import java.util.*;

@Tag(name = "聊天模块", description = "提供单对单实时聊天功能")
@Slf4j
@RestController
@RequestMapping("/chat")
public class ChatController {

    @Autowired
    private MessageService messageService;

    @Autowired
    private RedisUtils redisUtils;

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @GetMapping("/online/{userId}")
    @Operation(summary = "查询用户是否在线")
    public Result<Boolean> isUserOnline(@PathVariable Long userId) {
        return Result.success(WebSocketEventListener.isUserOnline(redisUtils, userId));
    }

    @GetMapping("/online/batch")
    @Operation(summary = "批量查询用户在线状态")
    public Result<Map<Long, Boolean>> getOnlineStatus(
            @RequestParam String userIds,
            @AuthenticationPrincipal SecurityUser currentUser) {
        Map<Long, Boolean> result = new HashMap<>();
        String[] ids = userIds.split(",");
        for (String id : ids) {
            try {
                Long uid = Long.parseLong(id.trim());
                result.put(uid, WebSocketEventListener.isUserOnline(redisUtils, uid));
            } catch (NumberFormatException ignored) {}
        }
        return Result.success(result);
    }

    @PostMapping("/messages/send")
    @Operation(summary = "发送消息（REST API）")
    public Result<Message> sendMessageRest(
            @RequestBody ChatMessage chatMessage,
            @AuthenticationPrincipal SecurityUser currentUser) {

        Message msg = messageService.sendMessage(
                currentUser.getId(),
                chatMessage.getReceiverId(),
                chatMessage.getContent(),
                chatMessage.getType()
        );
        return Result.success("发送成功", msg);
    }

    @GetMapping("/history/{friendId}")
    @Operation(summary = "获取聊天记录")
    public Result<List<Message>> getChatHistory(
            @PathVariable Long friendId,
            @AuthenticationPrincipal SecurityUser currentUser,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {

        List<Message> messages = messageService.getChatHistory(currentUser.getId(), friendId, page, size);
        return Result.success(messages);
    }

    @PostMapping("/messages/{messageId}/recall")
    @Operation(summary = "撤回消息")
    public Result<Void> recallMessage(
            @PathVariable Long messageId,
            @AuthenticationPrincipal SecurityUser currentUser) {

        messageService.recallMessage(messageId, currentUser.getId());
        return Result.success("消息已撤回", null);
    }

    @GetMapping("/conversations")
    @Operation(summary = "获取会话列表")
    public Result<List<Message>> getConversations(
            @AuthenticationPrincipal SecurityUser currentUser) {

        List<Message> conversations = messageService.getConversations(currentUser.getId());
        return Result.success(conversations);
    }

    @GetMapping("/conversations/with-unread")
    @Operation(summary = "获取会话列表(含未读计数)")
    public Result<List<Map<String, Object>>> getConversationsWithUnread(
            @AuthenticationPrincipal SecurityUser currentUser) {

        List<Message> conversations = messageService.getConversations(currentUser.getId());
        List<Map<String, Object>> result = new ArrayList<>();
        for (Message msg : conversations) {
            Map<String, Object> item = new HashMap<>();
            Long otherId = msg.getSenderId().equals(currentUser.getId()) ? msg.getReceiverId() : msg.getSenderId();
            item.put("id", otherId);
            item.put("username", msg.getUsername());
            item.put("avatar", msg.getAvatar());
            item.put("lastMsg", msg.getContent());
            item.put("createTime", msg.getCreateTime());
            item.put("senderId", msg.getSenderId());
            item.put("isRead", msg.getIsRead());
            int unread = messageService.getUnreadCount(currentUser.getId(), otherId);
            item.put("unread", unread);
            item.put("online", WebSocketEventListener.isUserOnline(redisUtils, otherId));
            result.add(item);
        }
        return Result.success(result);
    }

    @GetMapping("/unread/{friendId}")
    @Operation(summary = "获取与某好友的未读消息数")
    public Result<Integer> getUnreadCount(
            @PathVariable Long friendId,
            @AuthenticationPrincipal SecurityUser currentUser) {

        int count = messageService.getUnreadCount(currentUser.getId(), friendId);
        return Result.success(count);
    }

    @PostMapping("/read-all/{friendId}")
    @Operation(summary = "标记与某好友的所有消息为已读")
    public Result<Void> markAllAsRead(
            @PathVariable Long friendId,
            @AuthenticationPrincipal SecurityUser currentUser) {

        messageService.markAllAsRead(currentUser.getId(), friendId);

        // Push read receipt to the message sender via both Raw WebSocket and STOMP
        try {
            Map<String, Object> receipt = new HashMap<>();
            receipt.put("type", "message_read");
            receipt.put("messageId", null);
            receipt.put("friendId", currentUser.getId());
            receipt.put("friendName", currentUser.getUsername());
            // Raw WebSocket (for Flutter)
            RawWebSocketHandler.pushToUser(friendId, receipt);
            // STOMP (for PC web client)
            messagingTemplate.convertAndSendToUser(
                    friendId.toString(), "/queue/read-receipts", receipt);
        } catch (Exception e) {
            log.warn("Failed to push read receipt: {}", e.getMessage());
        }

        return Result.success();
    }

    @PostMapping("/messages/{messageId}/read")
    @Operation(summary = "标记单条消息为已读")
    public Result<Void> markMessageAsRead(
            @PathVariable Long messageId,
            @AuthenticationPrincipal SecurityUser currentUser) {

        messageService.markAsRead(messageId, currentUser.getId());
        return Result.success();
    }

    @Data
    public static class ChatMessage {
        private Long senderId;
        private Long receiverId;
        private String content;
        private Integer type;
    }
}
