package com.gdmec.campchannel.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.gdmec.campchannel.entity.Notification;

import java.util.List;

public interface NotificationService extends IService<Notification> {

    /**
     * 发送系统通知
     */
    void sendNotification(Long userId, String type, String title, String content, String relatedId);

    /**
     * 获取用户未读通知列表
     */
    List<Notification> getUnreadNotifications(Long userId);

    /**
     * 标记通知为已读
     */
    void markAsRead(Long notificationId, Long userId);

    /**
     * 标记所有通知为已读
     */
    void markAllAsRead(Long userId);

    /**
     * 获取通知历史（分页，包含已读和未读）
     */
    List<Notification> getNotificationHistory(Long userId, int page, int size);

    /**
     * 获取通知历史（分页，支持按分类过滤）
     */
    List<Notification> getNotificationHistoryByCategory(Long userId, String category, int page, int size);
}