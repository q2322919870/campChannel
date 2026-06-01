package com.gdmec.campchannel.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.gdmec.campchannel.entity.Post;

import java.util.List;

public interface PostService extends IService<Post> {

    /**
     * 发布帖子（含限流风控与敏感词过滤）
     */
    Post createPost(Long channelId, Long userId, String content, List<String> images, String videoUrl, boolean isAnonymous);

    /**
     * 获取频道帖子流（按时间倒序分页）
     */
    List<Post> getChannelPosts(Long channelId, int page, int size, Long currentUserId);

    /**
     * 获取帖子详情
     */
    Post getPostById(Long postId);

    /**
     * 获取用户点赞过的帖子
     */
    List<Post> getLikedPosts(Long userId, int page, int size);

    /**
     * 获取用户发布的帖子
     */
    List<Post> getUserPosts(Long userId, int page, int size);

    /**
     * 删除帖子（仅作者可删）
     */
    void deletePost(Long postId, Long userId);

    /**
     * 增加帖子浏览量
     */
    void incrementViewCount(Long postId);

    /**
     * 编辑帖子
     */
    void updatePost(Long postId, Long userId, String content, List<String> images, String videoUrl);

    /**
     * 置顶/取消置顶帖子
     */
    java.util.Map<String, Object> togglePin(Long postId, Long userId);

    /**
     * 搜索帖子（按标题、内容、话题）
     */
    java.util.List<Post> searchPosts(String keyword, int page, int size, Long currentUserId);

    /**
     * 获取热门帖子（按热度排序）
     */
    java.util.List<Post> getHotPosts(int limit, Long currentUserId);
}