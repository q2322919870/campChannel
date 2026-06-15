package com.gdmec.campchannel.controller;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.gdmec.campchannel.common.api.Result;
import com.gdmec.campchannel.entity.Post;
import com.gdmec.campchannel.security.SecurityUser;
import com.gdmec.campchannel.service.PostService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@Tag(name = "树洞模块", description = "匿名树洞功能")
@Slf4j
@RestController
@RequestMapping("/tree-hole")
public class TreeHoleController {

    @Autowired
    private PostService postService;

    @GetMapping
    @Operation(summary = "获取树洞帖子列表（24小时内匿名帖子）")
    public Result<List<Post>> getTreeHolePosts(
            @AuthenticationPrincipal SecurityUser currentUser,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {

        Long userId = currentUser != null ? currentUser.getId() : null;
        if (userId == null) {
            return Result.failed(401, "未登录");
        }

        // 查询24小时内的匿名帖子
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime oneDayAgo = now.minusDays(1);

        QueryWrapper<Post> queryWrapper = new QueryWrapper<>();
        queryWrapper.isNull("channel_id")  // 树洞帖子没有频道ID
                .eq("is_anonymous", true)
                .eq("status", 1)
                .ge("create_time", oneDayAgo)
                .orderByDesc("create_time");

        Page<Post> pageParam = new Page<>(page, size);
        Page<Post> result = postService.page(pageParam, queryWrapper);

        // 设置匿名信息
        List<Post> posts = result.getRecords();
        for (Post post : posts) {
            post.setUsername("匿名");
            post.setAvatar(null);
            post.setIsAnonymous(true);
        }

        return Result.success(posts);
    }

    @PostMapping
    @Operation(summary = "发布树洞帖子（匿名，24小时后自动消失）")
    public Result<Post> createTreeHolePost(
            @RequestBody CreateTreeHoleRequest request,
            @AuthenticationPrincipal SecurityUser currentUser) {

        if (currentUser == null) {
            return Result.failed(401, "未登录");
        }

        if (request.getContent() == null || request.getContent().trim().isEmpty()) {
            return Result.failed(400, "内容不能为空");
        }

        if (request.getContent().length() > 500) {
            return Result.failed(400, "内容不能超过500字");
        }

        // 创建匿名帖子，channelId 为 null
        Post post = postService.createPost(
                null,  // channelId = null 表示树洞帖子
                currentUser.getId(),
                request.getContent(),
                null,  // images
                null,  // videoUrls
                true   // isAnonymous = true
        );

        // 设置24小时后过期
        post.setExpireTime(LocalDateTime.now().plusDays(1));
        postService.updateById(post);

        post.setUsername("匿名");
        post.setAvatar(null);

        return Result.success("发布成功", post);
    }

    @Data
    public static class CreateTreeHoleRequest {
        private String content;
    }
}
