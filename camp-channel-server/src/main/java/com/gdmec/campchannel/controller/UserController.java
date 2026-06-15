package com.gdmec.campchannel.controller;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.gdmec.campchannel.common.api.ErrorCode;
import com.gdmec.campchannel.common.api.Result;
import com.gdmec.campchannel.common.utils.RedisUtils;
import com.gdmec.campchannel.entity.*;
import com.gdmec.campchannel.mapper.*;
import com.gdmec.campchannel.security.SecurityUser;
import com.gdmec.campchannel.service.*;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.*;
import java.util.stream.Collectors;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@Tag(name = "用户中心模块", description = "提供个人信息管理、密码修改、远程下线功能")
@Slf4j
@RestController
@RequestMapping("/users")
public class UserController {

    @Autowired
    private UserService userService;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private RedisUtils redisUtils;

    @Autowired
    private LoginDeviceMapper loginDeviceMapper;

    @Autowired
    private PostService postService;

    @Autowired
    private FriendshipService friendshipService;

    @Autowired
    private ChannelMemberMapper channelMemberMapper;

    @Autowired
    private ChannelMapper channelMapper;

    @Value("${app.upload.local-path}")
    private String uploadPath;

    @GetMapping("/me")
    @Operation(summary = "获取当前用户信息")
    public Result<User> getCurrentUser(@AuthenticationPrincipal SecurityUser currentUser) {
        User user = userService.getById(currentUser.getId());
        if (user != null) {
            user.setPassword(null);
        }
        return Result.success(user);
    }

    @GetMapping("/profile")
    @Operation(summary = "获取当前用户个人资料（含发帖数、好友数）")
    public Result<Map<String, Object>> getProfile(@AuthenticationPrincipal SecurityUser currentUser) {
        User user = userService.getById(currentUser.getId());
        if (user == null) {
            return Result.failed(ErrorCode.UNAUTHORIZED);
        }
        user.setPassword(null);

        int postCount = (int) postService.count(new QueryWrapper<com.gdmec.campchannel.entity.Post>()
                .eq("user_id", currentUser.getId())
                .in("status", 0, 1));
        
        int friendCount = (int) friendshipService.count(new QueryWrapper<Friendship>()
                .eq("user_id", currentUser.getId())
                .eq("status", 1));

        Map<String, Object> result = new HashMap<>();
        result.put("id", user.getId());
        result.put("username", user.getUsername());
        result.put("email", user.getEmail());
        result.put("avatar", user.getAvatar());
        result.put("role", user.getRole());
        result.put("emailNotify", user.getEmailNotify());
        result.put("postCount", postCount);
        result.put("friendCount", friendCount);
        return Result.success(result);
    }

    @GetMapping("/{userId}")
    @Operation(summary = "根据ID获取用户信息")
    public Result<User> getUserById(@PathVariable Long userId) {
        User user = userService.getById(userId);
        if (user == null) {
            return Result.failed(ErrorCode.BAD_REQUEST, "用户不存在");
        }
        user.setPassword(null);
        return Result.success(user);
    }

    @GetMapping("/{userId}/profile")
    @Operation(summary = "获取用户名片信息(含帖子及好友关系)")
    public Result<Map<String, Object>> getUserProfile(
            @PathVariable Long userId,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        User user = userService.getById(userId);
        if (user == null) {
            return Result.failed(ErrorCode.BAD_REQUEST, "用户不存在");
        }
        user.setPassword(null);

        Map<String, Object> result = new HashMap<>();
        result.put("id", user.getId());
        result.put("username", user.getUsername());
        result.put("avatar", user.getAvatar());
        result.put("email", user.getEmail());

        Long myId = currentUser != null ? currentUser.getId() : null;
        result.put("isFriend", false);
        if (myId != null && !myId.equals(userId)) {
            QueryWrapper<Friendship> fw = new QueryWrapper<>();
            fw.eq("status", 1)
                    .and(w -> w
                            .and(w2 -> w2.eq("user_id", myId).eq("friend_id", userId))
                            .or(w2 -> w2.eq("user_id", userId).eq("friend_id", myId))
                    );
            result.put("isFriend", friendshipService.count(fw) > 0);
        }

        // Get posts: public channels + shared private channels (if friends)
        Set<Long> allowedChannelIds = new HashSet<>();
        // Public channels
        List<Channel> publicChannels = channelMemberMapper.selectList(
                new QueryWrapper<ChannelMember>()
                        .eq("user_id", userId)
                        .eq("status", 1)
        ).stream().map(cm -> {
            Channel c = new Channel();
            c.setId(cm.getChannelId());
            c.setType(1); // default public
            return c;
        }).collect(Collectors.toList());
        
        // Get actual channel types
        List<Long> userChannelIds = channelMemberMapper.selectList(
                new QueryWrapper<ChannelMember>()
                        .eq("user_id", userId)
                        .eq("status", 1)
        ).stream().map(ChannelMember::getChannelId).collect(Collectors.toList());
        
        if (!userChannelIds.isEmpty()) {
            // Get channel types using ChannelMapper
            List<Channel> channels = channelMapper.selectBatchIds(userChannelIds);
            
            for (Channel channel : channels) {
                if (channel.getType() == 1) {
                    allowedChannelIds.add(channel.getId());
                } else if (channel.getType() == 2 && (boolean)result.get("isFriend")) {
                    // Only show private channel posts if friends
                    // Check if current user is also a member
                    if (myId != null) {
                        ChannelMember myMembership = channelMemberMapper.selectOne(
                                new QueryWrapper<ChannelMember>()
                                        .eq("channel_id", channel.getId())
                                        .eq("user_id", myId)
                                        .eq("status", 1));
                        if (myMembership != null) {
                            allowedChannelIds.add(channel.getId());
                        }
                    }
                }
            }
        }

        List<Map<String, Object>> postsList = new ArrayList<>();
        if (!allowedChannelIds.isEmpty()) {
            QueryWrapper<com.gdmec.campchannel.entity.Post> pw = new QueryWrapper<>();
            pw.in("channel_id", allowedChannelIds)
                    .eq("user_id", userId)
                    .eq("status", 1)
                    .orderByDesc("create_time")
                    .last("LIMIT 20");
            
            List<com.gdmec.campchannel.entity.Post> posts = postService.list(pw);
            for (com.gdmec.campchannel.entity.Post p : posts) {
                Map<String, Object> pm = new HashMap<>();
                pm.put("id", p.getId());
                pm.put("content", p.getContent());
                pm.put("createTime", p.getCreateTime());
                // Parse images
                List<String> images = new ArrayList<>();
                if (p.getImages() != null && !p.getImages().isEmpty()) {
                    try {
                        com.fasterxml.jackson.databind.ObjectMapper om = new com.fasterxml.jackson.databind.ObjectMapper();
                        List<String> imgList = om.readValue(p.getImages(), List.class);
                        for (String url : imgList) {
                            if (url.startsWith("http") || url.startsWith("/")) {
                                images.add(url);
                            } else {
                                images.add("/uploads/images/" + url);
                            }
                        }
                    } catch (Exception e) {
                        log.warn("Failed to parse images for post {}: {}", p.getId(), e.getMessage());
                    }
                }
                pm.put("images", images);
                postsList.add(pm);
            }
        }
        result.put("posts", postsList);

        return Result.success(result);
    }

    @PostMapping("/avatar")
    @Operation(summary = "上传并更新头像（自动去重：相同图片只存一份）")
    public Result<Map<String, String>> uploadAvatar(
            @RequestParam("file") MultipartFile file,
            @AuthenticationPrincipal SecurityUser currentUser) {

        if (file == null || file.isEmpty()) {
            return Result.failed(ErrorCode.BAD_REQUEST, "文件不能为空");
        }

        try {
            String originalFilename = file.getOriginalFilename();
            String extension = "";
            if (originalFilename != null && originalFilename.contains(".")) {
                extension = originalFilename.substring(originalFilename.lastIndexOf("."));
            }

            // 计算文件 MD5 哈希，用于去重
            byte[] fileBytes = file.getBytes();
            java.security.MessageDigest md = java.security.MessageDigest.getInstance("MD5");
            byte[] digest = md.digest(fileBytes);
            StringBuilder sb = new StringBuilder();
            for (byte b : digest) {
                sb.append(String.format("%02x", b & 0xff));
            }
            String fileHash = sb.toString();

            Path baseDir = Paths.get(uploadPath).toAbsolutePath().normalize();
            Path uploadDir = baseDir.resolve("avatars");
            Files.createDirectories(uploadDir);

            // 检查是否已存在相同哈希的文件
            String newFilename = fileHash + extension;
            Path filePath = uploadDir.resolve(newFilename);

            if (!Files.exists(filePath)) {
                // 只有新文件才写入磁盘
                file.transferTo(filePath.toFile());
                log.info("头像文件已保存: {} hash={}", newFilename, fileHash);
            } else {
                log.info("头像文件已存在(去重): {} hash={}", newFilename, fileHash);
            }

            String fileUrl = "/uploads/avatars/" + newFilename;

            User user = userService.getById(currentUser.getId());
            if (user != null) {
                user.setAvatar(fileUrl);
                userService.updateById(user);
            }

            Map<String, String> result = new HashMap<>();
            result.put("url", fileUrl);
            log.info("头像更新成功: {} userId={}", fileUrl, currentUser.getId());
            return Result.success("头像更新成功", result);

        } catch (Exception e) {
            log.error("头像上传失败 userId={}: {}", currentUser.getId(), e.getMessage());
            return Result.failed(ErrorCode.SYSTEM_ERROR, "上传失败: " + e.getMessage());
        }
    }

    @PutMapping("/me")
    @Operation(summary = "更新个人信息（兼容旧路径）")
    public Result<User> updateProfile(
            @RequestBody UpdateProfileRequest request,
            @AuthenticationPrincipal SecurityUser currentUser) {
        return updateProfileV3(request, currentUser);
    }

    @PutMapping("/profile")
    @Operation(summary = "更新个人资料（API文档定义的标准Path）")
    public Result<User> updateProfileV3(
            @RequestBody UpdateProfileRequest request,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        User user = userService.getById(currentUser.getId());
        if (user == null) {
            return Result.failed(ErrorCode.UNAUTHORIZED);
        }

        if (StringUtils.hasText(request.getUsername())) {
            user.setUsername(request.getUsername());
        }
        if (StringUtils.hasText(request.getRealName())) {
            user.setRealName(request.getRealName());
        }
        if (StringUtils.hasText(request.getPhone())) {
            user.setPhone(request.getPhone());
        }

        userService.updateById(user);
        user.setPassword(null);
        return Result.success("更新成功", user);
    }

    @PutMapping("/password")
    @Operation(summary = "修改密码")
    public Result<Void> changePassword(
            @RequestBody ChangePasswordRequest request,
            @AuthenticationPrincipal SecurityUser currentUser) {

        if (!StringUtils.hasText(request.getOldPassword()) || !StringUtils.hasText(request.getNewPassword())) {
            return Result.failed(ErrorCode.BAD_REQUEST, "旧密码和新密码不能为空");
        }

        User user = userService.getById(currentUser.getId());
        if (user == null) {
            return Result.failed(ErrorCode.UNAUTHORIZED);
        }

        if (!passwordEncoder.matches(request.getOldPassword(), user.getPassword())) {
            return Result.failed(ErrorCode.PASSWORD_ERROR, "旧密码错误");
        }

        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        userService.updateById(user);

        String activeTokenKey = "active_token:" + user.getUsername();
        redisUtils.del(activeTokenKey);

        return Result.success("密码修改成功，请重新登录", null);
    }

    @PostMapping("/logout-all")
    @Operation(summary = "远程所有设备下线（兼容旧路径）")
    public Result<Void> logoutAllDevices(@AuthenticationPrincipal SecurityUser currentUser) {
        String activeTokenKey = "active_token:" + currentUser.getUsername();
        redisUtils.del(activeTokenKey);
        return Result.success("已强制所有设备下线", null);
    }

    @GetMapping("/devices")
    @Operation(summary = "获取登录设备列表")
    public Result<List<LoginDevice>> getDevices(@AuthenticationPrincipal SecurityUser currentUser) {
        QueryWrapper<LoginDevice> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("user_id", currentUser.getId())
                .orderByDesc("login_time");
        List<LoginDevice> devices = loginDeviceMapper.selectList(queryWrapper);
        return Result.success(devices);
    }

    @DeleteMapping("/devices/{deviceId}")
    @Operation(summary = "远程下线指定设备（API文档定义的标准Path）")
    public Result<Void> logoutDeviceByDeviceId(
            @PathVariable Long deviceId,
            @AuthenticationPrincipal SecurityUser currentUser) {

        LoginDevice device = loginDeviceMapper.selectById(deviceId);
        if (device == null || !device.getUserId().equals(currentUser.getId())) {
            return Result.failed(ErrorCode.BAD_REQUEST, "设备记录不存在");
        }
        loginDeviceMapper.deleteById(deviceId);
        return Result.success("已强制该设备下线", null);
    }

    @PostMapping("/devices/{deviceId}/logout")
    @Operation(summary = "远程下线指定设备（兼容旧路径）")
    public Result<Void> logoutDeviceByIdLegacy(
            @PathVariable Long deviceId,
            @AuthenticationPrincipal SecurityUser currentUser) {
        return logoutDeviceByDeviceId(deviceId, currentUser);
    }

    @Data
    public static class UpdateProfileRequest {
        private String username;
        private String realName;
        private String phone;
    }

    @Data
    public static class ChangePasswordRequest {
        private String oldPassword;
        private String newPassword;
    }
}