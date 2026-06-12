package com.gdmec.campchannel.controller;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.gdmec.campchannel.common.api.ErrorCode;
import com.gdmec.campchannel.common.api.Result;
import com.gdmec.campchannel.entity.Announcement;
import com.gdmec.campchannel.mapper.AnnouncementMapper;
import com.gdmec.campchannel.mapper.UserMapper;
import com.gdmec.campchannel.security.SecurityUser;
import com.gdmec.campchannel.service.NotificationService;
import com.gdmec.campchannel.service.OperationLogService;
import com.gdmec.campchannel.service.AnnouncementService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Sort;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Tag(name = "公告管理模块", description = "提供公告的发布、修改、删除及查询功能")
@Slf4j
@RestController
@RequestMapping("/api/notices")
public class NoticeController {

    @Autowired
    private AnnouncementService announcementService;

    @Autowired
    private AnnouncementMapper announcementMapper;

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private NotificationService notificationService;

    @Autowired
    private OperationLogService operationLogService;

    // ---------------------------------------------------------------
    // Public endpoints (any logged-in user can read)
    // ---------------------------------------------------------------

    @GetMapping
    @Operation(summary = "获取公告列表")
    public Result<List<Announcement>> getNotices(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {

        Page<Announcement> noticePage = announcementService.page(
                new Page<>(page, size),
                new QueryWrapper<Announcement>()
                        .orderByDesc("created_at"));
        return Result.success(noticePage.getRecords());
    }

    @GetMapping("/active")
    @Operation(summary = "获取所有可用公告（管理员）")
    public Result<List<Announcement>> getActiveNotices() {
        List<Announcement> notices = announcementService.getActiveAnnouncements();
        return Result.success(notices);
    }

    @GetMapping("/{id}")
    @Operation(summary = "获取单个公告详情")
    public Result<Announcement> getNoticeById(@PathVariable Long id) {
        Announcement notice = announcementService.getById(id);
        if (notice == null) {
            return Result.failed(ErrorCode.BAD_REQUEST, "公告不存在");
        }
        return Result.success(notice);
    }

    // ---------------------------------------------------------------
    // Admin-only endpoints (@PreAuthorize)
    // ---------------------------------------------------------------

    @PostMapping
    @Operation(summary = "发布公告（管理员）")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<Void> createNotice(
            @RequestBody NoticeRequest request,
            @AuthenticationPrincipal SecurityUser currentUser) {

        if (request.getTitle() == null || request.getTitle().trim().isEmpty()) {
            return Result.failed(ErrorCode.BAD_REQUEST, "公告标题不能为空");
        }
        if (request.getContent() == null || request.getContent().trim().isEmpty()) {
            return Result.failed(ErrorCode.BAD_REQUEST, "公告内容不能为空");
        }

        Announcement notice = new Announcement();
        notice.setTitle(request.getTitle().trim());
        notice.setContent(request.getContent().trim());
        notice.setType("announcement");
        notice.setCoverImage(request.getCoverImage());
        notice.setCreatedBy(currentUser.getId());
        notice.setChannelId(0L);
        notice.setStatus(1); // active
        notice.setCreatedAt(LocalDateTime.now());
        announcementService.save(notice);

        // 向所有用户推送通知
        List<Long> allUserIds = userMapper.selectList(new QueryWrapper<>())
                .stream()
                .map(u -> (Long) u.getId())
                .collect(Collectors.toList());
        for (Long uid : allUserIds) {
            notificationService.sendNotification(uid, "system",
                    notice.getTitle(), notice.getContent(), "announcement");
        }

        operationLogService.log(currentUser.getId(), "公告管理",
                "发布公告", "标题: " + notice.getTitle(),
                "POST", "/api/notices", null);

        return Result.success("公告已发布，覆盖 " + allUserIds.size() + " 个用户", null);
    }

    @PutMapping("/{id}")
    @Operation(summary = "修改公告（管理员）")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<Void> updateNotice(
            @PathVariable Long id,
            @RequestBody NoticeUpdateRequest request,
            @AuthenticationPrincipal SecurityUser currentUser) {

        Announcement notice = announcementService.getById(id);
        if (notice == null) {
            return Result.failed(ErrorCode.BAD_REQUEST, "公告不存在");
        }

        if (request.getTitle() != null && !request.getTitle().trim().isEmpty()) {
            notice.setTitle(request.getTitle().trim());
        }
        if (request.getContent() != null && !request.getContent().trim().isEmpty()) {
            notice.setContent(request.getContent().trim());
        }
        if (request.getCoverImage() != null) {
            notice.setCoverImage(request.getCoverImage());
        }
        announcementService.updateById(notice);

        operationLogService.log(currentUser.getId(), "公告管理",
                "修改公告", "公告ID: " + id + ", 标题: " + notice.getTitle(),
                "PUT", "/api/notices/" + id, null);

        return Result.success("公告已更新", null);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "删除公告（管理员）")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<Void> deleteNotice(
            @PathVariable Long id,
            @AuthenticationPrincipal SecurityUser currentUser) {

        Announcement notice = announcementService.getById(id);
        if (notice == null) {
            return Result.failed(ErrorCode.BAD_REQUEST, "公告不存在");
        }

        announcementService.removeById(id);

        operationLogService.log(currentUser.getId(), "公告管理",
                "删除公告", "公告ID: " + id + ", 标题: " + notice.getTitle(),
                "DELETE", "/api/notices/" + id, null);

        return Result.success("公告已删除", null);
    }

    @PutMapping("/{id}/status")
    @Operation(summary = "修改公告状态（管理员）")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<Void> updateNoticeStatus(
            @PathVariable Long id,
            @RequestBody StatusUpdateRequest request,
            @AuthenticationPrincipal SecurityUser currentUser) {

        Announcement notice = announcementService.getById(id);
        if (notice == null) {
            return Result.failed(ErrorCode.BAD_REQUEST, "公告不存在");
        }

        notice.setStatus(request.getStatus());
        announcementService.updateById(notice);

        operationLogService.log(currentUser.getId(), "公告管理",
                request.getStatus() == 1 ? "启用公告" : "禁用公告",
                "公告ID: " + id, "PUT", "/api/notices/" + id + "/status", null);

        return Result.success("公告状态已更新", null);
    }

    // ---------------------------------------------------------------
    // Inner request classes
    // ---------------------------------------------------------------

    @Data
    public static class NoticeRequest {
        private String title;
        private String content;
        private String coverImage;
    }

    @Data
    public static class NoticeUpdateRequest {
        private String title;
        private String content;
        private String coverImage;
    }

    @Data
    public static class StatusUpdateRequest {
        private Integer status;
    }
}
