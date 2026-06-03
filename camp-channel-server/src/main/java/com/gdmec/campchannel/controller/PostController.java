package com.gdmec.campchannel.controller;

import com.gdmec.campchannel.common.api.Result;
import com.gdmec.campchannel.entity.Channel;
import com.gdmec.campchannel.entity.ChannelMember;
import com.gdmec.campchannel.entity.Post;
import com.gdmec.campchannel.entity.User;
import com.gdmec.campchannel.mapper.ChannelMemberMapper;
import com.gdmec.campchannel.mapper.ChannelMapper;
import com.gdmec.campchannel.mapper.UserMapper;
import com.gdmec.campchannel.security.SecurityUser;
import com.gdmec.campchannel.service.PostService;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Tag(name = "帖子管理模块", description = "提供帖子发布、浏览、删除等功能")
@Slf4j
@RestController
@RequestMapping("/posts")
public class PostController {

    @GetMapping
    @Operation(summary = "获取用户所有频道帖子流（首页信息流）")
    public Result<List<Post>> getAllPosts(
            @AuthenticationPrincipal SecurityUser currentUser,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {

        Long userId = currentUser != null ? currentUser.getId() : null;
        if (userId == null) {
            return Result.failed(com.gdmec.campchannel.common.api.ErrorCode.UNAUTHORIZED);
        }

        List<ChannelMember> memberships = channelMemberMapper.selectList(
                new QueryWrapper<ChannelMember>()
                        .eq("user_id", userId)
                        .eq("status", 1));

        List<Long> channelIds = memberships.stream()
                .map(ChannelMember::getChannelId)
                .distinct()
                .collect(Collectors.toList());

        if (channelIds.isEmpty()) {
            return Result.success(List.of());
        }

        int offset = (page - 1) * size;
        QueryWrapper<Post> queryWrapper = new QueryWrapper<>();
        queryWrapper.in("channel_id", channelIds)
                .eq("status", 1)
                .orderByDesc("create_time")
                .last("LIMIT " + offset + ", " + size);

        List<Post> posts = postService.list(queryWrapper);

        // Batch populate user info and channel names (fix N+1)
        // Collect non-anonymous user IDs
        java.util.Set<Long> userIds = new java.util.HashSet<>();
        java.util.Set<Long> channelIds2 = new java.util.HashSet<>();
        for (Post post : posts) {
            if (!Boolean.TRUE.equals(post.getIsAnonymous())) {
                userIds.add(post.getUserId());
            }
            if (post.getChannelId() != null) {
                channelIds2.add(post.getChannelId());
            }
        }

        // Batch fetch users
        Map<Long, User> userMap = new HashMap<>();
        if (!userIds.isEmpty()) {
            List<User> users = userMapper.selectBatchIds(new ArrayList<>(userIds));
            userMap = users.stream().collect(Collectors.toMap(User::getId, u -> u, (a, b) -> a));
        }

        // Batch fetch channels
        Map<Long, Channel> channelMap = new HashMap<>();
        if (!channelIds2.isEmpty()) {
            List<Channel> channels = channelMapper.selectBatchIds(new ArrayList<>(channelIds2));
            channelMap = channels.stream().collect(Collectors.toMap(Channel::getId, c -> c, (a, b) -> a));
        }

        // Apply to posts
        for (Post post : posts) {
            if (Boolean.TRUE.equals(post.getIsAnonymous())) {
                post.setUsername("匿名");
                post.setAvatar(null);
            } else {
                User user = userMap.get(post.getUserId());
                if (user != null) {
                    post.setUsername(user.getUsername());
                    post.setAvatar(user.getAvatar());
                }
            }
            if (post.getChannelId() != null) {
                Channel channel = channelMap.get(post.getChannelId());
                if (channel != null) {
                    post.setChannelName(channel.getName());
                }
            }
        }

        return Result.success(posts);
    }

    @GetMapping("/tree-hole")
    @Operation(summary = "获取匿名树洞帖子流")
    public Result<List<Post>> getTreeHolePosts(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size,
            @AuthenticationPrincipal SecurityUser currentUser) {

        Long userId = currentUser != null ? currentUser.getId() : null;

        int offset = (page - 1) * size;
        QueryWrapper<Post> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("is_anonymous", 1)
                .eq("status", 1)
                // 过滤掉已过期的帖子（expire_time < now 的显示为过期）
                .and(wrapper -> wrapper.isNull("expire_time").or().gt("expire_time", java.time.LocalDateTime.now()))
                .orderByDesc("create_time")
                .last("LIMIT " + offset + ", " + size);

        List<Post> posts = postService.list(queryWrapper);

        // 查询当前用户对这批帖子的解开记录
        java.util.Set<Long> revealedPostIds = new java.util.HashSet<>();
        if (userId != null && !posts.isEmpty()) {
            java.util.List<Long> postIds = posts.stream().map(Post::getId).collect(java.util.stream.Collectors.toList());
            com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<com.gdmec.campchannel.entity.PostRevealRecord> recordWrapper = 
                new com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<>();
            recordWrapper.eq("user_id", userId)
                        .in("post_id", postIds);
            java.util.List<com.gdmec.campchannel.entity.PostRevealRecord> records = revealRecordMapper.selectList(recordWrapper);
            revealedPostIds = records.stream().map(com.gdmec.campchannel.entity.PostRevealRecord::getPostId).collect(java.util.stream.Collectors.toSet());
        }

        for (Post post : posts) {
            maskAnonymousPost(post);
            post.setChannelName("树洞");
            // 标记是否已解开
            if (revealedPostIds.contains(post.getId())) {
                post.setIsRevealed(true);
            } else {
                post.setIsRevealed(false);
            }
        }

        return Result.success(posts);
    }

    @Autowired
    private PostService postService;

    @Autowired
    private ChannelMemberMapper channelMemberMapper;

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private ChannelMapper channelMapper;
    
    @Autowired
    private com.gdmec.campchannel.mapper.PostRevealRecordMapper revealRecordMapper;

    @Autowired
    private com.gdmec.campchannel.service.FavouriteService favouriteService;

    @PostMapping
    @Operation(summary = "发布帖子")
    public Result<Post> createPost(
            @RequestBody CreatePostRequest request,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        Post post = postService.createPost(
                request.getChannelId(),
                currentUser.getId(),
                request.getContent(),
                request.getImages(),
                request.getVideoUrls(),
                request.getIsAnonymous() != null ? request.getIsAnonymous() : false
        );
        return Result.success("发布成功", post);
    }

    @GetMapping("/channel/{channelId}")
    @Operation(summary = "获取频道帖子流")
    public Result<List<Post>> getChannelPosts(
            @PathVariable Long channelId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        Long userId = currentUser != null ? currentUser.getId() : null;
        List<Post> posts = postService.getChannelPosts(channelId, page, size, userId);
        return Result.success(posts);
    }

    @GetMapping("/{postId}")
    @Operation(summary = "获取帖子详情")
    public Result<Post> getPostById(
            @PathVariable Long postId,
            @AuthenticationPrincipal SecurityUser currentUser) {
        Post post = postService.getPostById(postId, currentUser.getId());
        if (post == null) {
            return Result.failed(com.gdmec.campchannel.common.api.ErrorCode.BAD_REQUEST, "帖子不存在");
        }
        return Result.success(post);
    }

    @GetMapping("/my")
    @Operation(summary = "获取我的帖子")
    public Result<List<Post>> getMyPosts(
            @AuthenticationPrincipal SecurityUser currentUser,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {
        
        List<Post> posts = postService.getUserPosts(currentUser.getId(), page, size);
        return Result.success(posts);
    }

    @DeleteMapping("/{postId}")
    @Operation(summary = "删除帖子")
    public Result<Void> deletePost(
            @PathVariable Long postId,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        postService.deletePost(postId, currentUser.getId());
        return Result.success("删除成功", null);
    }

    @GetMapping("/{postId}/view")
    @Operation(summary = "增加帖子浏览量")
    public Result<Void> viewPost(@PathVariable Long postId) {
        postService.incrementViewCount(postId);
        return Result.success();
    }

    @PutMapping("/{postId}")
    @Operation(summary = "编辑帖子")
    public Result<Void> updatePost(
            @PathVariable Long postId,
            @RequestBody CreatePostRequest request,
            @AuthenticationPrincipal SecurityUser currentUser) {

        postService.updatePost(postId, currentUser.getId(), request.getContent(),
                request.getImages(), request.getVideoUrls());
        return Result.success("帖子已更新", null);
    }
    
    @PostMapping("/{postId}/reveal")
    @Operation(summary = "记录用户解开告白")
    public Result<Void> revealPost(
            @PathVariable Long postId,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        if (currentUser == null) {
            return Result.failed(401, "请先登录");
        }
        
        try {
            // 检查是否已经记录过
            com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<com.gdmec.campchannel.entity.PostRevealRecord> checkWrapper = 
                new com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<>();
            checkWrapper.eq("post_id", postId).eq("user_id", currentUser.getId());
            com.gdmec.campchannel.entity.PostRevealRecord existing = revealRecordMapper.selectOne(checkWrapper);
            
            if (existing == null) {
                // 插入新记录
                com.gdmec.campchannel.entity.PostRevealRecord record = new com.gdmec.campchannel.entity.PostRevealRecord();
                record.setPostId(postId);
                record.setUserId(currentUser.getId());
                record.setRevealTime(java.time.LocalDateTime.now());
                revealRecordMapper.insert(record);
            }
            
            return Result.success("已记录解开状态", null);
        } catch (Exception e) {
            return Result.failed(500, "记录失败: " + e.getMessage());
        }
    }

    @GetMapping("/user/{userId}")
    @Operation(summary = "获取指定用户的帖子")
    public Result<List<Post>> getUserPostsById(
            @PathVariable Long userId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {

        List<Post> posts = postService.getUserPosts(userId, page, size);
        return Result.success(posts);
    }

    @GetMapping("/liked")
    @Operation(summary = "获取我点赞过的帖子")
    public Result<List<Post>> getLikedPosts(
            @AuthenticationPrincipal SecurityUser currentUser,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        List<Post> posts = postService.getLikedPosts(currentUser.getId(), page, size);
        return Result.success(posts);
    }

    @PostMapping("/{id}/favourite")
    @Operation(summary = "收藏/取消收藏帖子")
    public Result<Map<String, Object>> toggleFavourite(
            @PathVariable Long id,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        boolean isFavourited = favouriteService.toggleFavourite(id, currentUser.getId());
        Map<String, Object> result = new HashMap<>();
        result.put("isFavourited", isFavourited);
        result.put("message", isFavourited ? "收藏成功" : "已取消收藏");
        return Result.success(result);
    }

    @GetMapping("/favourites")
    @Operation(summary = "获取我的收藏列表")
    public Result<List<Post>> getMyFavourites(
            @AuthenticationPrincipal SecurityUser currentUser,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        List<Post> posts = favouriteService.getUserFavourites(currentUser.getId(), page, size);
        return Result.success(posts);
    }

    @GetMapping("/{id}/favourite/status")
    @Operation(summary = "检查帖子收藏状态")
    public Result<Map<String, Object>> getFavouriteStatus(
            @PathVariable Long id,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        boolean isFavourited = favouriteService.hasFavourited(id, currentUser.getId());
        int count = favouriteService.getFavouriteCount(id);
        Map<String, Object> result = new HashMap<>();
        result.put("isFavourited", isFavourited);
        result.put("count", count);
        return Result.success(result);
    }

    @PostMapping("/{id}/pin")
    @Operation(summary = "置顶/取消置顶帖子")
    public Result<Map<String, Object>> togglePin(
            @PathVariable Long id,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        Map<String, Object> result = postService.togglePin(id, currentUser.getId());
        return Result.success(result);
    }

    @GetMapping("/search")
    @Operation(summary = "搜索帖子")
    public Result<List<Post>> searchPosts(
            @RequestParam String keyword,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        List<Post> posts = postService.searchPosts(keyword, page, size, currentUser.getId());
        return Result.success(posts);
    }

    @GetMapping("/hot")
    @Operation(summary = "获取热门帖子")
    public Result<List<Post>> getHotPosts(
            @RequestParam(defaultValue = "20") int limit,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        List<Post> posts = postService.getHotPosts(limit, currentUser.getId());
        return Result.success(posts);
    }

    /** Populate username/avatar, masking identity for anonymous posts */
    private void maskAnonymousPost(Post post) {
        if (Boolean.TRUE.equals(post.getIsAnonymous())) {
            post.setUsername("匿名");
            post.setAvatar(null);
        } else {
            User user = userMapper.selectById(post.getUserId());
            if (user != null) {
                post.setUsername(user.getUsername());
                post.setAvatar(user.getAvatar());
            }
        }
    }

    @Data
    public static class CreatePostRequest {
        private Long channelId;
        private String content;
        private List<String> images;
        private List<String> videoUrls;
        private Boolean isAnonymous;
    }
}