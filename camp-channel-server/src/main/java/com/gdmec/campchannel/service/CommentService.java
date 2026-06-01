package com.gdmec.campchannel.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.gdmec.campchannel.entity.Comment;

import java.util.List;

public interface CommentService extends IService<Comment> {

    /**
     * 发表评论（含限流风控）
     */
    Comment createComment(Long postId, Long userId, String content, Long parentId);

    /**
     * 获取帖子的评论列表
     */
    List<Comment> getPostComments(Long postId, int page, int size);

    /**
     * 删除评论（仅作者或帖子作者可删）
     */
    void deleteComment(Long commentId, Long userId);
}