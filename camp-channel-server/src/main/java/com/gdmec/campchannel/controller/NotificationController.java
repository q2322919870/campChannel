package com.gdmec.campchannel.controller;

import com.gdmec.campchannel.common.api.Result;
import com.gdmec.campchannel.entity.Notification;
import com.gdmec.campchannel.security.SecurityUser;
import com.gdmec.campchannel.service.NotificationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "系统通知模块", description = "提供应用内实时通知功能")
@Slf4j
@RestController
@RequestMapping("/notifications")
public class NotificationController {

    @Autowired
    private NotificationService notificationService;

    @GetMapping("/unread")
    @Operation(summary = "获取未读通知列表")
    public Result<List<Notification>> getUnreadNotifications(
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        List<Notification> notifications = notificationService.getUnreadNotifications(currentUser.getId());
        return Result.success(notifications);
    }

    @GetMapping("/unread/count")
    @Operation(summary = "获取未读通知数量")
    public Result<Integer> getUnreadCount(
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        List<Notification> notifications = notificationService.getUnreadNotifications(currentUser.getId());
        return Result.success(notifications.size());
    }

    @PostMapping("/{notificationId}/read")
    @Operation(summary = "标记通知为已读")
    public Result<Void> markAsRead(
            @PathVariable Long notificationId,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        notificationService.markAsRead(notificationId, currentUser.getId());
        return Result.success();
    }

    @PostMapping("/read-all")
    @Operation(summary = "标记所有通知为已读")
    public Result<Void> markAllAsRead(
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        notificationService.markAllAsRead(currentUser.getId());
        return Result.success();
    }

    @GetMapping("/history")
    @Operation(summary = "获取通知历史（分页）")
    public Result<List<Notification>> getNotificationHistory(
            @AuthenticationPrincipal SecurityUser currentUser,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String category) {

        List<Notification> notifications;
        if (category != null && !category.isEmpty()) {
            notifications = notificationService.getNotificationHistoryByCategory(
                    currentUser.getId(), category, page, size);
        } else {
            notifications = notificationService.getNotificationHistory(
                    currentUser.getId(), page, size);
        }
        return Result.success(notifications);
    }
}