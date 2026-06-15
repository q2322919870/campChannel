package com.gdmec.campchannel.controller;

import com.gdmec.campchannel.common.api.ErrorCode;
import com.gdmec.campchannel.common.api.Result;
import com.gdmec.campchannel.entity.*;
import com.gdmec.campchannel.mapper.UserMapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.gdmec.campchannel.security.SecurityUser;
import com.gdmec.campchannel.service.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Tag(name = "管理员后台模块", description = "提供用户管理、频道审核、内容审核、操作日志功能")
@Slf4j
@RestController
@RequestMapping("/admin")
public class AdminController {

    @Autowired
    private UserService userService;

    @Autowired
    private ChannelService channelService;

    @Autowired
    private PostService postService;

    @Autowired
    private CommentService commentService;

    @Autowired
    private OperationLogService operationLogService;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private NotificationService notificationService;

    @Autowired
    private UserMapper userMapper;

    @GetMapping("/stats")
    @Operation(summary = "后台首页统计数据")
    public Result<Map<String, Object>> getStats(
            @AuthenticationPrincipal SecurityUser currentUser) {
        if (!"sys_admin".equals(currentUser.getRole())) {
            return Result.failed(ErrorCode.FORBIDDEN);
        }
        Map<String, Object> stats = new HashMap<>();
        stats.put("totalUsers", userService.count());
        long postCount = postService.count();
        stats.put("totalPosts", postCount);
        long commentCount = commentService.count();
        stats.put("totalComments", commentCount);
        com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<Channel> chQ = new com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<>();
        stats.put("totalChannels", channelService.count(chQ));
        com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<Post> pendPw = new com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<>();
        pendPw.eq("status", 0);
        stats.put("pendingPosts", postService.count(pendPw));
        com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<Channel> pendCw = new com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<>();
        pendCw.eq("status", 0);
        stats.put("pendingChannels", channelService.count(pendCw));
        return Result.success(stats);
    }

    @GetMapping("/users")
    @Operation(summary = "获取用户列表")
    public Result<List<User>> getUsers(
            @AuthenticationPrincipal SecurityUser currentUser,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        if (!"sys_admin".equals(currentUser.getRole())) {
            return Result.failed(ErrorCode.FORBIDDEN);
        }

        List<User> users = userService.page(
                new com.baomidou.mybatisplus.extension.plugins.pagination.Page<>(page, size)
        ).getRecords();
        
        users.forEach(u -> u.setPassword(null));
        return Result.success(users);
    }

    @PostMapping("/users/{userId}/status")
    @Operation(summary = "禁用/启用用户（API文档定义的标准Path）")
    public Result<Void> updateUserStatus(
            @PathVariable Long userId,
            @RequestBody StatusUpdateRequest request,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        if (!"sys_admin".equals(currentUser.getRole())) {
            return Result.failed(ErrorCode.FORBIDDEN);
        }

        User user = userService.getById(userId);
        if (user == null) {
            return Result.failed(ErrorCode.BAD_REQUEST, "用户不存在");
        }

        user.setStatus(request.getStatus());
        userService.updateById(user);

        operationLogService.log(currentUser.getId(), "用户管理", 
                request.getStatus() == 0 ? "禁用用户" : "启用用户",
                "操作用户ID: " + userId, "POST", "/admin/users/" + userId + "/status", null);

        return Result.success(request.getStatus() == 0 ? "已禁用用户" : "已启用用户");
    }

    @PostMapping("/users/{userId}/reset-password")
    @Operation(summary = "重置用户密码")
    public Result<Void> resetPassword(
            @PathVariable Long userId,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        if (!"sys_admin".equals(currentUser.getRole())) {
            return Result.failed(ErrorCode.FORBIDDEN);
        }

        User user = userService.getById(userId);
        if (user == null) {
            return Result.failed(ErrorCode.BAD_REQUEST, "用户不存在");
        }

        String defaultPassword = "123456";
        user.setPassword(passwordEncoder.encode(defaultPassword));
        userService.updateById(user);

        operationLogService.log(currentUser.getId(), "用户管理", "重置密码",
                "重置用户ID: " + userId + " 的密码为默认密码", "POST", "/admin/users/" + userId + "/reset-password", null);

        return Result.success("密码已重置为默认密码: " + defaultPassword, null);
    }

    @DeleteMapping("/users/{userId}")
    @Operation(summary = "删除用户")
    public Result<Void> deleteUser(
            @PathVariable Long userId,
            @AuthenticationPrincipal SecurityUser currentUser) {

        if (!"sys_admin".equals(currentUser.getRole())) {
            return Result.failed(ErrorCode.FORBIDDEN);
        }

        User user = userService.getById(userId);
        if (user == null) {
            return Result.failed(ErrorCode.BAD_REQUEST, "用户不存在");
        }

        if (user.getId().equals(currentUser.getId())) {
            return Result.failed(ErrorCode.BAD_REQUEST, "不能删除自己");
        }

        userService.removeById(userId);

        operationLogService.log(currentUser.getId(), "用户管理", "删除用户",
                "删除用户ID: " + userId, "DELETE", "/admin/users/" + userId, null);

        return Result.success("用户已删除", null);
    }

    @PutMapping("/users/{userId}")
    @Operation(summary = "修改用户信息")
    public Result<Void> updateUser(
            @PathVariable Long userId,
            @RequestBody UpdateUserRequest request,
            @AuthenticationPrincipal SecurityUser currentUser) {

        if (!"sys_admin".equals(currentUser.getRole())) {
            return Result.failed(ErrorCode.FORBIDDEN);
        }

        User user = userService.getById(userId);
        if (user == null) {
            return Result.failed(ErrorCode.BAD_REQUEST, "用户不存在");
        }

        if (request.getUsername() != null && !request.getUsername().trim().isEmpty()) {
            user.setUsername(request.getUsername().trim());
        }
        if (request.getRealName() != null) {
            user.setRealName(request.getRealName().trim());
        }
        userService.updateById(user);

        operationLogService.log(currentUser.getId(), "用户管理", "修改用户信息",
                "修改用户ID: " + userId + " 的用户名/真实姓名", "PUT", "/admin/users/" + userId, null);

        return Result.success("用户信息已更新", null);
    }

    @GetMapping("/channels/pending")
    @Operation(summary = "获取待审核频道列表")
    public Result<List<Channel>> getPendingChannels(
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        if (!"sys_admin".equals(currentUser.getRole())) {
            return Result.failed(ErrorCode.FORBIDDEN);
        }

        com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<Channel> queryWrapper = 
                new com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<>();
        queryWrapper.eq("status", 0)
                .orderByDesc("create_time");
        List<Channel> channels = channelService.list(queryWrapper);
        return Result.success(channels);
    }

    @GetMapping("/channels")
    @Operation(summary = "获取所有频道列表（管理员）")
    public Result<List<java.util.Map<String, Object>>> getAllChannels(
            @AuthenticationPrincipal SecurityUser currentUser,
            @RequestParam(required = false) Integer type,
            @RequestParam(required = false) String creatorUsername) {

        if (!"sys_admin".equals(currentUser.getRole())) {
            return Result.failed(ErrorCode.FORBIDDEN);
        }

        QueryWrapper<Channel> queryWrapper = new QueryWrapper<>();
        if (type != null) {
            queryWrapper.eq("type", type);
        }
        queryWrapper.orderByDesc("create_time");
        List<Channel> channels = channelService.list(queryWrapper);

        // 填充频道主用户名
        List<java.util.Map<String, Object>> result = new java.util.ArrayList<>();
        for (Channel ch : channels) {
            java.util.Map<String, Object> map = new java.util.HashMap<>();
            map.put("id", ch.getId());
            map.put("channelCode", ch.getChannelCode());
            map.put("name", ch.getName());
            map.put("description", ch.getDescription());
            map.put("type", ch.getType());
            map.put("status", ch.getStatus());
            map.put("creatorId", ch.getCreatorId());
            map.put("createTime", ch.getCreateTime());
            map.put("updateTime", ch.getUpdateTime());

            if (ch.getCreatorId() != null && ch.getCreatorId() > 0) {
                User creator = userService.getById(ch.getCreatorId());
                map.put("creatorUsername", creator != null ? creator.getUsername() : "系统");
            } else {
                map.put("creatorUsername", "系统");
            }
            result.add(map);
        }

        // 按频道主用户名筛选
        if (creatorUsername != null && !creatorUsername.trim().isEmpty()) {
            String keyword = creatorUsername.trim().toLowerCase();
            result = result.stream()
                    .filter(m -> {
                        String name = String.valueOf(m.get("creatorUsername")).toLowerCase();
                        return name.contains(keyword);
                    })
                    .toList();
        }

        return Result.success(result);
    }

    @DeleteMapping("/channels/{channelId}")
    @Operation(summary = "删除频道")
    public Result<Void> deleteChannel(
            @PathVariable Long channelId,
            @AuthenticationPrincipal SecurityUser currentUser) {

        if (!"sys_admin".equals(currentUser.getRole())) {
            return Result.failed(ErrorCode.FORBIDDEN);
        }

        Channel channel = channelService.getById(channelId);
        if (channel == null) {
            return Result.failed(ErrorCode.BAD_REQUEST, "频道不存在");
        }

        channelService.removeById(channelId);

        operationLogService.log(currentUser.getId(), "频道管理", "删除频道",
                "删除频道ID: " + channelId + " 名称: " + channel.getName(), "DELETE",
                "/admin/channels/" + channelId, null);

        return Result.success("频道已删除", null);
    }

    @PutMapping("/channels/{channelId}/status")
    @Operation(summary = "修改频道状态")
    public Result<Void> updateChannelStatus(
            @PathVariable Long channelId,
            @RequestBody StatusUpdateRequest request,
            @AuthenticationPrincipal SecurityUser currentUser) {

        if (!"sys_admin".equals(currentUser.getRole())) {
            return Result.failed(ErrorCode.FORBIDDEN);
        }

        Channel channel = channelService.getById(channelId);
        if (channel == null) {
            return Result.failed(ErrorCode.BAD_REQUEST, "频道不存在");
        }

        channel.setStatus(request.getStatus());
        channelService.updateById(channel);

        operationLogService.log(currentUser.getId(), "频道管理",
                request.getStatus() == 0 ? "禁用频道" : "启用频道",
                "频道ID: " + channelId, "PUT", "/admin/channels/" + channelId + "/status", null);

        return Result.success("频道状态已更新", null);
    }

    @GetMapping("/posts/pending")
    @Operation(summary = "获取待审核帖子列表")
    public Result<List<Post>> getPendingPosts(
            @AuthenticationPrincipal SecurityUser currentUser,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        if (!"sys_admin".equals(currentUser.getRole())) {
            return Result.failed(ErrorCode.FORBIDDEN);
        }

        com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<Post> queryWrapper = 
                new com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<>();
        queryWrapper.eq("status", 0)
                .orderByDesc("create_time");
        
        int offset = (page - 1) * size;
        queryWrapper.last("LIMIT " + offset + ", " + size);
        
        List<Post> posts = postService.list(queryWrapper);
        return Result.success(posts);
    }

    @PostMapping("/posts/{postId}/approve")
    @Operation(summary = "审核帖子")
    public Result<Void> approvePost(
            @PathVariable Long postId,
            @RequestBody ApproveRequest request,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        if (!"sys_admin".equals(currentUser.getRole())) {
            return Result.failed(ErrorCode.FORBIDDEN);
        }

        Post post = postService.getById(postId);
        if (post == null) {
            return Result.failed(ErrorCode.BAD_REQUEST, "帖子不存在");
        }

        post.setStatus(request.isApproved() ? 1 : 2);
        postService.updateById(post);

        operationLogService.log(currentUser.getId(), "内容审核", 
                request.isApproved() ? "通过帖子" : "拒绝帖子",
                "审核帖子ID: " + postId, "POST", "/admin/posts/" + postId + "/approve", null);

        return Result.success(request.isApproved() ? "已通过审核" : "已拒绝", null);
    }

    @GetMapping("/comments/pending")
    @Operation(summary = "获取待审核评论列表")
    public Result<List<Comment>> getPendingComments(
            @AuthenticationPrincipal SecurityUser currentUser,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        if (!"sys_admin".equals(currentUser.getRole())) {
            return Result.failed(ErrorCode.FORBIDDEN);
        }

        com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<Comment> queryWrapper = 
                new com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<>();
        queryWrapper.eq("status", 0)
                .orderByDesc("create_time");
        
        int offset = (page - 1) * size;
        queryWrapper.last("LIMIT " + offset + ", " + size);
        
        List<Comment> comments = commentService.list(queryWrapper);
        return Result.success(comments);
    }

    @PostMapping("/comments/{commentId}/approve")
    @Operation(summary = "审核评论")
    public Result<Void> approveComment(
            @PathVariable Long commentId,
            @RequestBody ApproveRequest request,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        if (!"sys_admin".equals(currentUser.getRole())) {
            return Result.failed(ErrorCode.FORBIDDEN);
        }

        Comment comment = commentService.getById(commentId);
        if (comment == null) {
            return Result.failed(ErrorCode.BAD_REQUEST, "评论不存在");
        }

        comment.setStatus(request.isApproved() ? 1 : 2);
        commentService.updateById(comment);

        operationLogService.log(currentUser.getId(), "内容审核", 
                request.isApproved() ? "通过评论" : "拒绝评论",
                "审核评论ID: " + commentId, "POST", "/admin/comments/" + commentId + "/approve", null);

        return Result.success(request.isApproved() ? "已通过审核" : "已拒绝", null);
    }

    @GetMapping("/logs")
    @Operation(summary = "获取操作日志列表")
    public Result<List<OperationLog>> getLogs(
            @AuthenticationPrincipal SecurityUser currentUser,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) String module) {
        
        if (!"sys_admin".equals(currentUser.getRole())) {
            return Result.failed(ErrorCode.FORBIDDEN);
        }

        List<OperationLog> logs = operationLogService.getLogs(page, size, userId, module);
        return Result.success(logs);
    }

    @Data
    public static class StatusUpdateRequest {
        private Integer status;
    }

    @Data
    public static class UpdateUserRequest {
        private String username;
        private String realName;
    }

    @Data
    public static class ApproveRequest {
        private boolean approved;
    }
}