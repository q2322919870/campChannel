package com.gdmec.campchannel.controller;

import com.gdmec.campchannel.common.api.Result;
import com.gdmec.campchannel.entity.Follow;
import com.gdmec.campchannel.security.SecurityUser;
import com.gdmec.campchannel.service.FollowService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Tag(name = "关注模块", description = "提供用户关注、粉丝列表与关注动态功能")
@Slf4j
@RestController
@RequestMapping("/follow")
public class FollowController {

    @Autowired
    private FollowService followService;

    @PostMapping("/{userId}/toggle")
    @Operation(summary = "关注/取消关注用户")
    public Result<Boolean> toggleFollow(
            @PathVariable Long userId,
            @AuthenticationPrincipal SecurityUser currentUser) {
        boolean followed = followService.toggleFollow(currentUser.getId(), userId);
        return Result.success(followed ? "关注成功" : "取消关注成功", followed);
    }

    @GetMapping("/{userId}/followers")
    @Operation(summary = "获取用户粉丝列表")
    public Result<List<Follow>> getFollowers(
            @PathVariable Long userId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        List<Follow> followers = followService.getFollowers(userId, page, size);
        return Result.success(followers);
    }

    @GetMapping("/{userId}/following")
    @Operation(summary = "获取用户关注列表")
    public Result<List<Follow>> getFollowing(
            @PathVariable Long userId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        List<Follow> following = followService.getFollowing(userId, page, size);
        return Result.success(following);
    }

    @GetMapping("/{userId}/counts")
    @Operation(summary = "获取用户粉丝数和关注数")
    public Result<Map<String, Integer>> getFollowCounts(@PathVariable Long userId) {
        Map<String, Integer> counts = new HashMap<>();
        counts.put("followerCount", followService.getFollowerCount(userId));
        counts.put("followingCount", followService.getFollowingCount(userId));
        return Result.success(counts);
    }

    @GetMapping("/{userId}/is-following")
    @Operation(summary = "检查是否已关注某用户")
    public Result<Boolean> isFollowing(
            @PathVariable Long userId,
            @AuthenticationPrincipal SecurityUser currentUser) {
        boolean following = followService.isFollowing(currentUser.getId(), userId);
        return Result.success(following);
    }

    @GetMapping("/feed")
    @Operation(summary = "获取关注动态（关注用户的帖子）")
    public Result<?> getFollowingFeed(
            @AuthenticationPrincipal SecurityUser currentUser,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        List<?> feed = followService.getFollowingFeed(currentUser.getId(), page, size);
        return Result.success(feed);
    }
}
