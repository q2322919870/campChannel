package com.gdmec.campchannel.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.gdmec.campchannel.common.api.ErrorCode;
import com.gdmec.campchannel.common.exception.BusinessException;
import com.gdmec.campchannel.entity.Message;
import com.gdmec.campchannel.entity.User;
import com.gdmec.campchannel.config.RawWebSocketHandler;
import com.gdmec.campchannel.mapper.MessageMapper;
import com.gdmec.campchannel.mapper.UserMapper;
import com.gdmec.campchannel.service.EmailService;
import com.gdmec.campchannel.service.MessageService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
public class MessageServiceImpl extends ServiceImpl<MessageMapper, Message> implements MessageService {

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private EmailService emailService;

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Message sendMessage(Long senderId, Long receiverId, String content, Integer type) {
        Message message = new Message();
        message.setSenderId(senderId);
        message.setReceiverId(receiverId);
        message.setContent(content);
        message.setType(type != null ? type : 1);
        message.setStatus(1); // 1=已发送
        message.setIsRead(0);

        save(message);

        // Push via STOMP WebSocket to receiver
        try {
            Map<String, Object> wsMsg = new HashMap<>();
            wsMsg.put("id", message.getId());
            wsMsg.put("senderId", senderId);
            wsMsg.put("receiverId", receiverId);
            wsMsg.put("content", message.getContent());
            wsMsg.put("type", message.getType());
            wsMsg.put("status", message.getStatus());
            wsMsg.put("isRead", message.getIsRead());
            wsMsg.put("readAt", message.getReadAt());
            wsMsg.put("createTime", message.getCreateTime());
            User sender = userMapper.selectById(senderId);
            if (sender != null) {
                wsMsg.put("username", sender.getUsername());
                wsMsg.put("avatar", sender.getAvatar());
            }
            // Push via STOMP (for PC web client)
            messagingTemplate.convertAndSendToUser(
                    receiverId.toString(), "/queue/messages", wsMsg);
            // Push via Raw WebSocket (for Flutter client)
            wsMsg.put("type", "new_message");
            RawWebSocketHandler.pushToUser(receiverId, wsMsg);
        } catch (Exception e) {
            log.warn("Failed to push message via WebSocket: {}", e.getMessage());
        }

        // Send email alert to receiver if enabled
        try {
            User sender = userMapper.selectById(senderId);
            String senderName = sender != null ? sender.getUsername() : "某个用户";
            String emailContent = senderName + " 给你发送了一条私信\n\n消息内容: " + content;
            emailService.sendEmailAlert(receiverId,
                    "新私信 - " + senderName,
                    emailContent);
        } catch (Exception e) {
            log.warn("Failed to send message email alert: {}", e.getMessage());
        }

        return message;
    }

    @Override
    public List<Message> getChatHistory(Long userId, Long friendId, int page, int size) {
        QueryWrapper<Message> queryWrapper = new QueryWrapper<>();
        queryWrapper.and(wrapper -> wrapper
                        .and(w -> w.eq("sender_id", userId).eq("receiver_id", friendId))
                        .or(w -> w.eq("sender_id", friendId).eq("receiver_id", userId))
                )
                .orderByDesc("create_time");

        int offset = (page - 1) * size;
        queryWrapper.last("LIMIT " + offset + ", " + size);

        List<Message> messages = list(queryWrapper);

        // Mark messages from friend as read
        for (Message msg : messages) {
            if (msg.getReceiverId().equals(userId) && (msg.getIsRead() == null || msg.getIsRead() == 0)) {
                msg.setIsRead(1);
                msg.setStatus(3); // 3=已读
                msg.setReadTime(LocalDateTime.now());
                msg.setReadAt(LocalDateTime.now());
                updateById(msg);
            }
        }

        return messages;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void recallMessage(Long messageId, Long userId) {
        Message message = getById(messageId);
        if (message == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "消息不存在");
        }

        if (!message.getSenderId().equals(userId)) {
            throw new BusinessException(ErrorCode.FORBIDDEN, "您无权撤回此消息");
        }

        if (message.getCreateTime() != null) {
            long minutesElapsed = ChronoUnit.MINUTES.between(message.getCreateTime(), LocalDateTime.now());
            if (minutesElapsed >= 2) {
                throw new BusinessException(ErrorCode.BAD_REQUEST, "消息超过2分钟无法撤回");
            }
        }

        message.setStatus(2);
        updateById(message);
    }

    @Override
    public List<Message> getConversations(Long userId) {
        List<Message> allMessages = list(new QueryWrapper<Message>()
                .and(w -> w.eq("sender_id", userId).or().eq("receiver_id", userId))
                .orderByDesc("create_time"));

        Map<Long, Message> conversationMap = new HashMap<>();
        for (Message msg : allMessages) {
            Long otherId = msg.getSenderId().equals(userId) ? msg.getReceiverId() : msg.getSenderId();
            if (!conversationMap.containsKey(otherId)) {
                conversationMap.put(otherId, msg);
            }
        }

        List<Message> conversations = conversationMap.values().stream()
                .sorted((a, b) -> b.getCreateTime().compareTo(a.getCreateTime()))
                .collect(Collectors.toList());

        for (Message msg : conversations) {
            Long otherId = msg.getSenderId().equals(userId) ? msg.getReceiverId() : msg.getSenderId();
            com.gdmec.campchannel.entity.User user = userMapper.selectById(otherId);
            if (user != null) {
                msg.setUsername(user.getUsername());
                msg.setAvatar(user.getAvatar());
            }
        }

        return conversations;
    }

    @Override
    public int getUnreadCount(Long userId, Long friendId) {
        return (int) count(new QueryWrapper<Message>()
                .eq("sender_id", friendId)
                .eq("receiver_id", userId)
                .and(w -> w.eq("is_read", 0).or().isNull("is_read")));
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void markAsRead(Long messageId, Long userId) {
        Message message = getById(messageId);
        if (message != null && message.getReceiverId().equals(userId)) {
            message.setIsRead(1);
            message.setStatus(3); // 3=已读
            message.setReadTime(LocalDateTime.now());
            message.setReadAt(LocalDateTime.now());
            updateById(message);
            
            // Push read receipt to the message sender via both Raw WebSocket and STOMP
            try {
                Map<String, Object> receipt = new HashMap<>();
                receipt.put("type", "message_read");
                receipt.put("messageId", messageId);
                receipt.put("friendId", userId);
                // Raw WebSocket (for Flutter)
                RawWebSocketHandler.pushToUser(message.getSenderId(), receipt);
                // STOMP (for PC web client)
                messagingTemplate.convertAndSendToUser(
                        message.getSenderId().toString(), "/queue/read-receipts", receipt);
            } catch (Exception e) {
                log.debug("Failed to push read receipt: {}", e.getMessage());
            }
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void markAllAsRead(Long userId, Long friendId) {
        List<Message> unreadMessages = list(new QueryWrapper<Message>()
                .eq("sender_id", friendId)
                .eq("receiver_id", userId)
                .and(w -> w.eq("is_read", 0).or().isNull("is_read")));
        LocalDateTime now = LocalDateTime.now();
        for (Message msg : unreadMessages) {
            msg.setIsRead(1);
            msg.setStatus(3); // 3=已读
            msg.setReadTime(now);
            msg.setReadAt(now);
        }
        updateBatchById(unreadMessages);
    }
}
