package com.gdmec.campchannel.controller;

import com.gdmec.campchannel.common.api.Result;
import com.gdmec.campchannel.entity.Gallery;
import com.gdmec.campchannel.security.SecurityUser;
import com.gdmec.campchannel.service.GalleryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@Tag(name = "画廊模块", description = "提供画廊画的增删查功能")
@Slf4j
@RestController
@RequestMapping("/gallery")
public class GalleryController {

    @Autowired
    private GalleryService galleryService;

    @PostMapping
    @Operation(summary = "添加画作")
    public Result<Gallery> addGallery(@RequestBody AddGalleryRequest request,
                                       @AuthenticationPrincipal SecurityUser currentUser) {
        Gallery g = galleryService.addGallery(currentUser.getId(), request.getImageUrl(), request.getTitle(), request.getDescription(), request.getChannelId());
        return Result.success("添加成功", g);
    }

    @GetMapping
    @Operation(summary = "获取画廊列表")
    public Result<List<Gallery>> getGalleryList(@RequestParam(defaultValue = "1") int page,
                                                 @RequestParam(defaultValue = "20") int size,
                                                 @RequestParam(required = false) Long channelId) {
        return Result.success(galleryService.getGalleryList(page, size, channelId));
    }

    @GetMapping("/my")
    @Operation(summary = "获取我的画作")
    public Result<List<Gallery>> getMyGallery(@AuthenticationPrincipal SecurityUser currentUser) {
        return Result.success(galleryService.getMyGallery(currentUser.getId()));
    }

    @DeleteMapping("/{galleryId}")
    @Operation(summary = "删除自己的画作")
    public Result<Void> deleteGallery(@PathVariable Long galleryId,
                                       @AuthenticationPrincipal SecurityUser currentUser) {
        galleryService.deleteGallery(galleryId, currentUser.getId());
        return Result.success("已删除", null);
    }

    @GetMapping("/pending")
    @Operation(summary = "获取待审核画作（管理员）")
    public Result<List<Gallery>> getPendingGalleries(@AuthenticationPrincipal SecurityUser currentUser) {
        if (!"sys_admin".equals(currentUser.getRole())) {
            return com.gdmec.campchannel.common.api.Result.failed(com.gdmec.campchannel.common.api.ErrorCode.FORBIDDEN);
        }
        return Result.success(galleryService.getPendingGalleries());
    }

    @PostMapping("/{galleryId}/approve")
    @Operation(summary = "审核画作（管理员）")
    public Result<Void> approveGallery(@PathVariable Long galleryId, @RequestBody ApproveRequest request,
                                        @AuthenticationPrincipal SecurityUser currentUser) {
        if (!"sys_admin".equals(currentUser.getRole())) {
            return com.gdmec.campchannel.common.api.Result.failed(com.gdmec.campchannel.common.api.ErrorCode.FORBIDDEN);
        }
        galleryService.approveGallery(galleryId, request.isApproved());
        return Result.success("操作成功", null);
    }

    @DeleteMapping("/admin/{galleryId}")
    @Operation(summary = "管理员删除画作")
    public Result<Void> adminDeleteGallery(@PathVariable Long galleryId,
                                            @AuthenticationPrincipal SecurityUser currentUser) {
        if (!"sys_admin".equals(currentUser.getRole())) {
            return com.gdmec.campchannel.common.api.Result.failed(com.gdmec.campchannel.common.api.ErrorCode.FORBIDDEN);
        }
        galleryService.adminDeleteGallery(galleryId);
        return Result.success("已删除", null);
    }

    @PostMapping("/{galleryId}/like")
    @Operation(summary = "点赞/取消点赞画作")
    public Result<Map<String, Object>> toggleLike(
            @PathVariable Long galleryId,
            @AuthenticationPrincipal SecurityUser currentUser) {
        Gallery g = galleryService.getById(galleryId);
        if (g == null) return Result.failed(com.gdmec.campchannel.common.api.ErrorCode.BAD_REQUEST, "画作不存在");

        boolean liked = galleryService.toggleLike(galleryId, currentUser.getId());
        Map<String, Object> result = new java.util.HashMap<>();
        result.put("liked", liked);
        result.put("likeCount", galleryService.getLikeCount(galleryId));
        return Result.success(liked ? "点赞成功" : "已取消点赞", result);
    }

    @GetMapping("/{galleryId}/like/status")
    @Operation(summary = "检查点赞状态")
    public Result<Map<String, Object>> getLikeStatus(
            @PathVariable Long galleryId,
            @AuthenticationPrincipal SecurityUser currentUser) {
        boolean hasLiked = galleryService.hasLiked(galleryId, currentUser.getId());
        Map<String, Object> result = new java.util.HashMap<>();
        result.put("hasLiked", hasLiked);
        result.put("likeCount", galleryService.getLikeCount(galleryId));
        return Result.success(result);
    }

    @PostMapping("/{galleryId}/comment")
    @Operation(summary = "评论画作")
    public Result<Map<String, Object>> addComment(
            @PathVariable Long galleryId,
            @RequestBody Map<String, String> body,
            @AuthenticationPrincipal SecurityUser currentUser) {
        String content = body.get("content");
        if (content == null || content.trim().isEmpty()) {
            return Result.failed(com.gdmec.campchannel.common.api.ErrorCode.BAD_REQUEST, "评论内容不能为空");
        }
        Map<String, Object> comment = galleryService.addComment(galleryId, currentUser.getId(), content.trim());
        return Result.success("评论成功", comment);
    }

    @GetMapping("/{galleryId}/comments")
    @Operation(summary = "获取画作评论")
    public Result<List<Map<String, Object>>> getComments(
            @PathVariable Long galleryId) {
        return Result.success(galleryService.getComments(galleryId));
    }

    @PostMapping("/{galleryId}/share")
    @Operation(summary = "分享画作到聊天")
    public Result<Void> shareGallery(
            @PathVariable Long galleryId,
            @RequestBody Map<String, Object> body,
            @AuthenticationPrincipal SecurityUser currentUser) {
        Long targetUserId = body.get("targetUserId") != null ? Long.valueOf(body.get("targetUserId").toString()) : null;
        galleryService.shareGallery(galleryId, currentUser.getId(), targetUserId);
        return Result.success("已分享", null);
    }

    @Data
    public static class AddGalleryRequest {
        private String imageUrl;
        private String title;
        private String description;
        private Long channelId;
    }

    @Data
    public static class ApproveRequest {
        private boolean approved;
    }
}
