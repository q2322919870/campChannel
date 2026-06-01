package com.gdmec.campchannel.controller;

import com.gdmec.campchannel.common.api.Result;
import com.gdmec.campchannel.entity.Channel;
import com.gdmec.campchannel.entity.ChannelMember;
import com.gdmec.campchannel.security.SecurityUser;
import com.gdmec.campchannel.service.ChannelService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "频道管理模块", description = "提供频道创建、搜索、加入、审核等功能")
@Slf4j
@RestController
@RequestMapping("/channels")
public class ChannelController {

    @Autowired
    private ChannelService channelService;

    @PostMapping
    @Operation(summary = "创建频道")
    public Result<Channel> createChannel(
            @RequestBody CreateChannelRequest request,
            @AuthenticationPrincipal SecurityUser currentUser) {

        Channel channel = channelService.createChannel(
                request.getName(),
                request.getDescription(),
                currentUser.getId()
        );
        return Result.success("频道创建成功", channel);
    }

    @GetMapping("/search")
    @Operation(summary = "搜索频道")
    public Result<List<Channel>> searchChannels(@RequestParam(required = false) String keyword) {
        List<Channel> channels = channelService.searchChannels(keyword);
        return Result.success(channels);
    }

    @GetMapping("/my")
    @Operation(summary = "获取我的频道列表")
    public Result<List<Channel>> getMyChannels(@AuthenticationPrincipal SecurityUser currentUser) {
        List<Channel> channels = channelService.getUserChannels(currentUser.getId());
        // 确保公共频道始终在列表中
        channelService.ensurePublicChannelJoined(currentUser.getId(), channels);
        return Result.success(channels);
    }

    @PostMapping("/{channelId}/join")
    @Operation(summary = "申请加入频道")
    public Result<Void> joinChannel(
            @PathVariable Long channelId,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        channelService.applyJoinChannel(channelId, currentUser.getId());
        return Result.success("申请成功", null);
    }

    @GetMapping("/{channelId}/applications")
    @Operation(summary = "获取频道待审核申请列表")
    public Result<List<ChannelMember>> getPendingApplications(
            @PathVariable Long channelId,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        List<ChannelMember> applications = channelService.getPendingApplications(channelId);
        return Result.success(applications);
    }

    @PostMapping("/applications/{applicationId}/approve")
    @Operation(summary = "审核加入申请")
    public Result<Void> approveApplication(
            @PathVariable Long applicationId,
            @RequestBody ApproveRequest request,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        channelService.approveJoinApplication(applicationId, currentUser.getId(), request.isApproved());
        return Result.success(request.isApproved() ? "已同意加入" : "已拒绝加入", null);
    }

    @PostMapping("/{channelId}/leave")
    @Operation(summary = "退出频道")
    public Result<Void> leaveChannel(
            @PathVariable Long channelId,
            @AuthenticationPrincipal SecurityUser currentUser) {

        channelService.leaveChannel(channelId, currentUser.getId());
        return Result.success("已退出频道", null);
    }

    @PutMapping("/{channelId}")
    @Operation(summary = "编辑频道信息")
    public Result<Void> updateChannel(
            @PathVariable Long channelId,
            @RequestBody CreateChannelRequest request,
            @AuthenticationPrincipal SecurityUser currentUser) {

        channelService.updateChannel(channelId, request.getName(), request.getDescription(), currentUser.getId());
        return Result.success("频道信息已更新", null);
    }

    @GetMapping("/{channelId}/members")
    @Operation(summary = "获取频道成员列表")
    public Result<List<ChannelMember>> getChannelMembers(
            @PathVariable Long channelId) {

        List<ChannelMember> members = channelService.getChannelMembers(channelId);
        return Result.success(members);
    }

    @PostMapping("/{channelId}/members/{userId}/remove")
    @Operation(summary = "移除频道成员")
    public Result<Void> removeMember(
            @PathVariable Long channelId,
            @PathVariable Long userId,
            @AuthenticationPrincipal SecurityUser currentUser) {

        channelService.removeMember(channelId, userId, currentUser.getId());
        return Result.success("已移除该成员", null);
    }

    @PostMapping("/{channelId}/members/{userId}/role")
    @Operation(summary = "设置频道成员角色")
    public Result<Void> setMemberRole(
            @PathVariable Long channelId,
            @PathVariable Long userId,
            @RequestBody RoleRequest request,
            @AuthenticationPrincipal SecurityUser currentUser) {

        channelService.setMemberRole(channelId, userId, currentUser.getId(), request.getRole());
        return Result.success("角色已更新", null);
    }

    @GetMapping("/applications/pending/count")
    @Operation(summary = "获取我的频道待审核申请总数")
    public Result<Integer> getPendingApplicationCount(@AuthenticationPrincipal SecurityUser currentUser) {
        int count = channelService.getPendingApplicationCount(currentUser.getId());
        return Result.success(count);
    }

    @GetMapping("/applications/pending")
    @Operation(summary = "获取我的频道待审核申请列表")
    public Result<List<ChannelMember>> getPendingApplications(@AuthenticationPrincipal SecurityUser currentUser) {
        List<ChannelMember> list = channelService.getPendingApplicationsForOwner(currentUser.getId());
        return Result.success(list);
    }

    @Data
    public static class CreateChannelRequest {
        private String name;
        private String description;
    }

    @Data
    public static class ApproveRequest {
        private boolean approved;
    }

    @Data
    public static class RoleRequest {
        private String role;
    }

    @Data
    public static class MuteRequest {
        private boolean muted;
    }

    @PostMapping("/{channelId}/members/{userId}/mute")
    @Operation(summary = "禁言/取消禁言频道成员")
    public Result<Void> muteMember(
            @PathVariable Long channelId,
            @PathVariable Long userId,
            @RequestBody MuteRequest request,
            @AuthenticationPrincipal SecurityUser currentUser) {

        channelService.muteMember(channelId, userId, currentUser.getId(), request.isMuted());
        return Result.success(request.isMuted() ? "已禁言" : "已取消禁言", null);
    }
}