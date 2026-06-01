package com.gdmec.campchannel.controller;

import com.gdmec.campchannel.common.api.Result;
import com.gdmec.campchannel.security.SecurityUser;
import com.gdmec.campchannel.service.LikeService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@Tag(name = "点赞模块", description = "提供帖子点赞/取消点赞功能")
@Slf4j
@RestController
@RequestMapping("/posts/{postId}/like")
public class LikeController {

    @Autowired
    private LikeService likeService;

    @PostMapping
    @Operation(summary = "点赞/取消点赞")
    public Result<Map<String, Object>> toggleLike(
            @PathVariable Long postId,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        boolean liked = likeService.toggleLike(postId, currentUser.getId());
        
        Map<String, Object> result = new HashMap<>();
        result.put("liked", liked);
        result.put("likeCount", likeService.getLikeCount(postId));
        
        return Result.success(liked ? "点赞成功" : "已取消点赞", result);
    }

    @GetMapping("/status")
    @Operation(summary = "检查点赞状态")
    public Result<Map<String, Object>> getLikeStatus(
            @PathVariable Long postId,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        boolean hasLiked = likeService.hasLiked(postId, currentUser.getId());
        
        Map<String, Object> result = new HashMap<>();
        result.put("hasLiked", hasLiked);
        result.put("likeCount", likeService.getLikeCount(postId));
        
        return Result.success(result);
    }
}