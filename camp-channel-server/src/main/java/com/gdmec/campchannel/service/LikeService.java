package com.gdmec.campchannel.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.gdmec.campchannel.entity.PostLike;

public interface LikeService extends IService<PostLike> {

    /**
     * 点赞/取消点赞（含限流风控）
     */
    boolean toggleLike(Long postId, Long userId);

    /**
     * 检查用户是否已点赞
     */
    boolean hasLiked(Long postId, Long userId);

    /**
     * 获取帖子点赞数
     */
    int getLikeCount(Long postId);
}