package com.gdmec.campchannel.controller;

import com.gdmec.campchannel.common.api.Result;
import com.gdmec.campchannel.entity.Announcement;
import com.gdmec.campchannel.security.SecurityUser;
import com.gdmec.campchannel.service.AnnouncementService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "公告模块", description = "刮刮乐/盲盒校园公告")
@Slf4j
@RestController
@RequestMapping("/announcements")
public class AnnouncementController {

    @Autowired
    private AnnouncementService announcementService;

    @GetMapping
    @Operation(summary = "获取活跃公告列表")
    public Result<List<Announcement>> getActiveAnnouncements() {
        return Result.success(announcementService.getActiveAnnouncements());
    }

    @PostMapping
    @Operation(summary = "创建公告（管理员）")
    public Result<Announcement> createAnnouncement(
            @RequestBody CreateAnnouncementRequest request,
            @AuthenticationPrincipal SecurityUser currentUser) {
        if (!"sys_admin".equals(currentUser.getRole())) {
            return Result.failed(com.gdmec.campchannel.common.api.ErrorCode.FORBIDDEN);
        }
        Announcement a = announcementService.createAnnouncement(
                request.getTitle(), request.getContent(), request.getType(),
                request.getCoverImage(), currentUser.getId(), request.getChannelId());
        return Result.success("创建成功", a);
    }

    @Data
    public static class CreateAnnouncementRequest {
        private String title;
        private String content;
        private String type;
        private String coverImage;
        private Long channelId;
    }
}
