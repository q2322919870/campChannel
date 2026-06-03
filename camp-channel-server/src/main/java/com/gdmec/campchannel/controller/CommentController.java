package com.gdmec.campchannel.controller;

import com.gdmec.campchannel.common.api.Result;
import com.gdmec.campchannel.entity.Comment;
import com.gdmec.campchannel.security.SecurityUser;
import com.gdmec.campchannel.service.CommentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "评论模块", description = "提供帖子评论与二级回复功能")
@Slf4j
@RestController
@RequestMapping("/posts/{postId}/comments")
public class CommentController {

    @Autowired
    private CommentService commentService;

    @PostMapping
    @Operation(summary = "发表评论")
    public Result<Comment> createComment(
            @PathVariable Long postId,
            @RequestBody CreateCommentRequest request,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        Comment comment = commentService.createComment(
                postId,
                currentUser.getId(),
                request.getContent(),
                request.getParentId()
        );
        return Result.success("评论成功", comment);
    }

    @GetMapping
    @Operation(summary = "获取帖子评论列表")
    public Result<List<Comment>> getComments(
            @PathVariable Long postId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        Long currentUserId = currentUser != null ? currentUser.getId() : null;
        List<Comment> comments = commentService.getPostComments(postId, page, size, currentUserId);
        return Result.success(comments);
    }

    @DeleteMapping("/{commentId}")
    @Operation(summary = "删除评论")
    public Result<Void> deleteComment(
            @PathVariable Long postId,
            @PathVariable Long commentId,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        commentService.deleteComment(commentId, currentUser.getId());
        return Result.success("删除成功", null);
    }

    @PostMapping("/{commentId}/like")
    @Operation(summary = "评论点赞/取消点赞")
    public Result<Boolean> toggleCommentLike(
            @PathVariable Long postId,
            @PathVariable Long commentId,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        boolean liked = commentService.toggleCommentLike(commentId, currentUser.getId());
        return Result.success(liked ? "点赞成功" : "取消点赞成功", liked);
    }

    @Data
    public static class CreateCommentRequest {
        private String content;
        private Long parentId;
    }
}