package com.gdmec.campchannel.controller;

import com.gdmec.campchannel.common.api.Result;
import com.gdmec.campchannel.entity.Friendship;
import com.gdmec.campchannel.entity.User;
import com.gdmec.campchannel.security.SecurityUser;
import com.gdmec.campchannel.service.FriendshipService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "好友系统模块", description = "提供好友搜索、申请、管理功能")
@Slf4j
@RestController
@RequestMapping("/friends")
public class FriendshipController {

    @Autowired
    private FriendshipService friendshipService;

    @GetMapping("/search")
    @Operation(summary = "搜索用户")
    public Result<List<User>> searchUsers(@RequestParam String keyword) {
        List<User> users = friendshipService.searchUsers(keyword);
        return Result.success(users);
    }

    @PostMapping("/request")
    @Operation(summary = "发送好友申请")
    public Result<Void> sendRequest(
            @RequestBody FriendRequest request,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        friendshipService.sendFriendRequest(currentUser.getId(), request.getFriendId());
        return Result.success("好友申请已发送", null);
    }

    @GetMapping("/requests/pending")
    @Operation(summary = "获取待处理的好友申请")
    public Result<List<Friendship>> getPendingRequests(
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        List<Friendship> requests = friendshipService.getPendingRequests(currentUser.getId());
        return Result.success(requests);
    }

    @PostMapping("/requests/{requestId}/approve")
    @Operation(summary = "同意好友申请")
    public Result<Void> approveRequest(
            @PathVariable Long requestId,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        friendshipService.approveFriendRequest(requestId, currentUser.getId());
        return Result.success("已同意好友申请", null);
    }

    @PostMapping("/requests/{requestId}/reject")
    @Operation(summary = "拒绝好友申请")
    public Result<Void> rejectRequest(
            @PathVariable Long requestId,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        friendshipService.rejectFriendRequest(requestId, currentUser.getId());
        return Result.success("已拒绝好友申请", null);
    }

    @GetMapping({"", "/list"})
    @Operation(summary = "获取好友列表")
    public Result<List<User>> getFriends(
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        List<User> friends = friendshipService.getFriends(currentUser.getId());
        return Result.success(friends);
    }

    @DeleteMapping("/{friendId}")
    @Operation(summary = "删除好友")
    public Result<Void> deleteFriend(
            @PathVariable Long friendId,
            @AuthenticationPrincipal SecurityUser currentUser) {

        friendshipService.deleteFriend(currentUser.getId(), friendId);
        return Result.success("已删除好友", null);
    }

    @PostMapping("/{friendId}/block")
    @Operation(summary = "屏蔽好友动态")
    public Result<Void> blockFriend(
            @PathVariable Long friendId,
            @AuthenticationPrincipal SecurityUser currentUser) {

        friendshipService.blockFriend(currentUser.getId(), friendId);
        return Result.success("已屏蔽该好友的动态", null);
    }

    @PostMapping("/{friendId}/unblock")
    @Operation(summary = "取消屏蔽好友")
    public Result<Void> unblockFriend(
            @PathVariable Long friendId,
            @AuthenticationPrincipal SecurityUser currentUser) {

        friendshipService.unblockFriend(currentUser.getId(), friendId);
        return Result.success("已取消屏蔽", null);
    }

    @Data
    public static class FriendRequest {
        private Long friendId;
    }
}