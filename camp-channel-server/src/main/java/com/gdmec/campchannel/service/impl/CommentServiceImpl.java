package com.gdmec.campchannel.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.gdmec.campchannel.common.api.ErrorCode;
import com.gdmec.campchannel.common.exception.BusinessException;
import com.gdmec.campchannel.common.filter.SensitiveWordFilter;
import com.gdmec.campchannel.common.utils.RedisUtils;
import com.gdmec.campchannel.entity.Comment;
import com.gdmec.campchannel.entity.CommentLike;
import com.gdmec.campchannel.entity.Post;
import com.gdmec.campchannel.mapper.CommentLikeMapper;
import com.gdmec.campchannel.mapper.CommentMapper;
import com.gdmec.campchannel.mapper.PostMapper;
import com.gdmec.campchannel.entity.User;
import com.gdmec.campchannel.mapper.UserMapper;
import com.gdmec.campchannel.service.CommentService;
import com.gdmec.campchannel.service.EmailService;
import com.gdmec.campchannel.service.NotificationService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Slf4j
@Service
public class CommentServiceImpl extends ServiceImpl<CommentMapper, Comment> implements CommentService {

    @Autowired
    private PostMapper postMapper;

    @Autowired
    private RedisUtils redisUtils;

    @Autowired
    private SensitiveWordFilter sensitiveWordFilter;

    @Autowired
    private NotificationService notificationService;

    @Autowired
    private EmailService emailService;

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private CommentLikeMapper commentLikeMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Comment createComment(Long postId, Long userId, String content, Long parentId) {
        if (!StringUtils.hasText(content)) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "评论内容不能为空");
        }

        String rateLimitKey = "comment_rate_limit:" + userId;
        boolean allowed = redisUtils.isAllowedRateLimit(rateLimitKey, 10, 60);
        if (!allowed) {
            throw new BusinessException(ErrorCode.TOO_MANY_REQUESTS, "评论过于频繁，请1分钟后再试");
        }

        Post post = postMapper.selectById(postId);
        if (post == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "帖子不存在");
        }

        if (parentId != null) {
            Comment parentComment = getById(parentId);
            if (parentComment == null || !parentComment.getPostId().equals(postId)) {
                throw new BusinessException(ErrorCode.BAD_REQUEST, "父评论不存在");
            }
        }

        int status = 1;
        boolean hasSensitive = sensitiveWordFilter.contains(content);
        if (hasSensitive) {
            status = 0;
        }

        Comment comment = new Comment();
        comment.setPostId(postId);
        comment.setUserId(userId);
        comment.setContent(content);
        comment.setParentId(parentId);
        comment.setStatus(status);

        save(comment);

        // Set username/avatar for the newly created comment
        User currentUser = userMapper.selectById(userId);
        if (currentUser != null) {
            comment.setUsername(currentUser.getUsername());
            comment.setAvatar(currentUser.getAvatar());
        }

        // Update comment count atomically
        postMapper.update(null, new com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper<Post>()
                .eq("id", postId)
                .setSql("comment_count = comment_count + 1"));

        // Process mentions asynchronously
        String mentionContent = extractMentions(content);
        if (mentionContent != null) {
            try {
                String[] usernames = mentionContent.split(",");
                for (String uname : usernames) {
                    User mentionedUser = userMapper.selectOne(
                            new com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<User>()
                                    .eq("username", uname.trim()));
                    if (mentionedUser != null && !mentionedUser.getId().equals(userId)) {
                        notificationService.sendNotification(mentionedUser.getId(), "mention",
                                "有人@了你", "用户在评论中提到了你",
                                postId.toString());
                    }
                }
            } catch (Exception e) {
                log.error("Failed to process mentions: {}", e.getMessage());
            }
        }

        // Send notification to post author asynchronously
        if (!post.getUserId().equals(userId)) {
            try {
                notificationService.sendNotification(post.getUserId(), "comment",
                        "新评论", "有人评论了你的帖子",
                        postId.toString());
                        
                // Send email alert if enabled
                User commenter = userMapper.selectById(userId);
                String commenterName = commenter != null ? commenter.getUsername() : "某个用户";
                String emailContent = commenterName + " 评论了你的帖子\n\n评论内容: " + content;
                emailService.sendEmailAlert(post.getUserId(),
                        "新评论 - " + commenterName,
                        emailContent);
            } catch (Exception e) {
                log.error("Failed to send comment notification: {}", e.getMessage());
            }
        }

        return comment;
    }

    @Override
    public List<Comment> getPostComments(Long postId, int page, int size, Long currentUserId) {
        QueryWrapper<Comment> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("post_id", postId)
                .eq("status", 1)
                .isNull("parent_id")
                .orderByDesc("create_time");
        
        int offset = (page - 1) * size;
        queryWrapper.last("LIMIT " + offset + ", " + size);
        
        List<Comment> comments = list(queryWrapper);
        
        // Batch fetch liked comment ids for current user
        Set<Long> likedCommentIds = new java.util.HashSet<>();
        if (currentUserId != null && !comments.isEmpty()) {
            List<Long> commentIds = comments.stream().map(Comment::getId).collect(Collectors.toList());
            QueryWrapper<CommentLike> likeQuery = new QueryWrapper<>();
            likeQuery.eq("user_id", currentUserId).in("comment_id", commentIds);
            List<CommentLike> likes = commentLikeMapper.selectList(likeQuery);
            likedCommentIds = likes.stream().map(CommentLike::getCommentId).collect(Collectors.toSet());
        }
        
        // Populate username, avatar, likeCount, isLiked for each comment
        for (Comment comment : comments) {
            User user = userMapper.selectById(comment.getUserId());
            if (user != null) {
                comment.setUsername(user.getUsername());
                comment.setAvatar(user.getAvatar());
            }
            if (comment.getLikeCount() == null) {
                comment.setLikeCount(0);
            }
            comment.setIsLiked(likedCommentIds.contains(comment.getId()));
        }
        
        return comments;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean toggleCommentLike(Long commentId, Long userId) {
        Comment comment = getById(commentId);
        if (comment == null || comment.getStatus() != 1) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "评论不存在");
        }

        QueryWrapper<CommentLike> query = new QueryWrapper<>();
        query.eq("comment_id", commentId).eq("user_id", userId);
        CommentLike existing = commentLikeMapper.selectOne(query);

        if (existing != null) {
            // Unlike
            commentLikeMapper.deleteById(existing.getId());
            int newCount = Math.max(0, (comment.getLikeCount() != null ? comment.getLikeCount() : 0) - 1);
            comment.setLikeCount(newCount);
            updateById(comment);
            return false;
        } else {
            // Like
            CommentLike like = new CommentLike();
            like.setCommentId(commentId);
            like.setUserId(userId);
            commentLikeMapper.insert(like);
            int newCount = (comment.getLikeCount() != null ? comment.getLikeCount() : 0) + 1;
            comment.setLikeCount(newCount);
            updateById(comment);
            return true;
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteComment(Long commentId, Long userId) {
        Comment comment = getById(commentId);
        if (comment == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "评论不存在");
        }

        Post post = postMapper.selectById(comment.getPostId());
        boolean isCommentAuthor = comment.getUserId().equals(userId);
        boolean isPostAuthor = post != null && post.getUserId().equals(userId);

        if (!isCommentAuthor && !isPostAuthor) {
            throw new BusinessException(ErrorCode.FORBIDDEN, "您无权删除此评论");
        }

        comment.setStatus(2);
        updateById(comment);

        if (post != null) {
            post.setCommentCount(Math.max(0, post.getCommentCount() - 1));
            postMapper.updateById(post);
        }
    }

    private String extractMentions(String content) {
        if (!org.springframework.util.StringUtils.hasText(content)) {
            return null;
        }
        StringBuilder mentions = new StringBuilder();
        int idx = 0;
        while ((idx = content.indexOf("@", idx)) != -1) {
            int end = content.indexOf(" ", idx);
            if (end == -1) end = content.length();
            String mention = content.substring(idx + 1, end);
            if (mention.length() > 0 && mention.length() <= 20) {
                if (mentions.length() > 0) mentions.append(",");
                mentions.append(mention);
            }
            idx = end;
        }
        return mentions.length() > 0 ? mentions.toString() : null;
    }
}