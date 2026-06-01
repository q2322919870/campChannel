package com.gdmec.campchannel.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.gdmec.campchannel.entity.Notification;
import com.gdmec.campchannel.mapper.NotificationMapper;
import com.gdmec.campchannel.service.NotificationService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Slf4j
@Service
public class NotificationServiceImpl extends ServiceImpl<NotificationMapper, Notification> implements NotificationService {

    private final SimpMessagingTemplate messagingTemplate;

    public NotificationServiceImpl(SimpMessagingTemplate messagingTemplate) {
        this.messagingTemplate = messagingTemplate;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void sendNotification(Long userId, String type, String title, String content, String relatedId) {
        Notification notification = new Notification();
        notification.setUserId(userId);
        notification.setType(type);
        notification.setTitle(title);
        notification.setContent(content);
        notification.setRelatedId(relatedId);
        notification.setIsRead(0);
        notification.setCreateTime(LocalDateTime.now());

        save(notification);

        // WebSocket 推送通知（如果客户端在线）
        try {
            messagingTemplate.convertAndSendToUser(
                    userId.toString(),
                    "/queue/notifications",
                    notification
            );
        } catch (Exception e) {
            log.debug("WebSocket push failed for user {}: {}", userId, e.getMessage());
        }
        // Email notifications are now handled separately by LikeService, CommentService, MessageService
    }

    @Override
    public List<Notification> getUnreadNotifications(Long userId) {
        QueryWrapper<Notification> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("user_id", userId)
                .eq("is_read", 0)
                .orderByDesc("create_time");
        return list(queryWrapper);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void markAsRead(Long notificationId, Long userId) {
        Notification notification = getById(notificationId);
        if (notification != null && notification.getUserId().equals(userId)) {
            notification.setIsRead(1);
            updateById(notification);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void markAllAsRead(Long userId) {
        QueryWrapper<Notification> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("user_id", userId)
                .eq("is_read", 0);
        
        Notification update = new Notification();
        update.setIsRead(1);
        update(update, queryWrapper);
    }

    @Override
    public List<Notification> getNotificationHistory(Long userId, int page, int size) {
        QueryWrapper<Notification> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("user_id", userId)
                .orderByDesc("create_time");
        
        int offset = (page - 1) * size;
        queryWrapper.last("LIMIT " + offset + ", " + size);
        
        return list(queryWrapper);
    }
}