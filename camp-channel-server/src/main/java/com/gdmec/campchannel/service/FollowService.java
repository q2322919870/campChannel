package com.gdmec.campchannel.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.gdmec.campchannel.entity.Follow;

import java.util.List;

public interface FollowService extends IService<Follow> {

    /**
     * 关注/取消关注（切换式）
     * @return true=已关注, false=已取消关注
     */
    boolean toggleFollow(Long followerId, Long followingId);

    /**
     * 检查是否已关注
     */
    boolean isFollowing(Long followerId, Long followingId);

    /**
     * 获取粉丝列表
     */
    List<Follow> getFollowers(Long userId, int page, int size);

    /**
     * 获取关注列表
     */
    List<Follow> getFollowing(Long userId, int page, int size);

    /**
     * 获取粉丝数
     */
    int getFollowerCount(Long userId);

    /**
     * 获取关注数
     */
    int getFollowingCount(Long userId);

    /**
     * 获取关注用户的帖子（关注动态Feed）
     */
    List<?> getFollowingFeed(Long userId, int page, int size);
}
