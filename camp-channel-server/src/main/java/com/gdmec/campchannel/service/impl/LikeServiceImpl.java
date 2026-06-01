package com.gdmec.campchannel.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.gdmec.campchannel.common.api.ErrorCode;
import com.gdmec.campchannel.common.exception.BusinessException;
import com.gdmec.campchannel.common.utils.RedisUtils;
import com.gdmec.campchannel.entity.Post;
import com.gdmec.campchannel.entity.PostLike;
import com.gdmec.campchannel.entity.User;
import com.gdmec.campchannel.mapper.PostLikeMapper;
import com.gdmec.campchannel.mapper.PostMapper;
import com.gdmec.campchannel.mapper.UserMapper;
import com.gdmec.campchannel.service.BadgeService;
import com.gdmec.campchannel.service.EmailService;
import com.gdmec.campchannel.service.LikeService;
import com.gdmec.campchannel.service.NotificationService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
public class LikeServiceImpl extends ServiceImpl<PostLikeMapper, PostLike> implements LikeService {

    @Autowired
    private PostMapper postMapper;

    @Autowired
    private RedisUtils redisUtils;

    @Autowired
    private NotificationService notificationService;

    @Autowired
    private EmailService emailService;

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private BadgeService badgeService;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean toggleLike(Long postId, Long userId) {
        String rateLimitKey = "like_rate_limit:" + userId;
        boolean allowed = redisUtils.isAllowedRateLimit(rateLimitKey, 50, 60);
        if (!allowed) {
            throw new BusinessException(ErrorCode.TOO_MANY_REQUESTS, "点赞过于频繁，请1分钟后再试");
        }

        // First check if already liked to avoid unnecessary post query
        QueryWrapper<PostLike> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("post_id", postId)
                .eq("user_id", userId);
        PostLike existing = getOne(queryWrapper);

        if (existing != null) {
            // Unlike operation
            removeById(existing.getId());
            
            // Update like count atomically
            postMapper.update(null, new com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper<Post>()
                    .eq("id", postId)
                    .setSql("like_count = GREATEST(like_count - 1, 0)"));
            
            return false;
        } else {
            // Like operation - first verify post exists
            Post post = postMapper.selectById(postId);
            if (post == null) {
                throw new BusinessException(ErrorCode.BAD_REQUEST, "帖子不存在");
            }

            PostLike like = new PostLike();
            like.setPostId(postId);
            like.setUserId(userId);
            try {
                save(like);
            } catch (DuplicateKeyException e) {
                log.warn("Duplicate like, removing: post={}, user={}", postId, userId);
                remove(new QueryWrapper<PostLike>()
                        .eq("post_id", postId)
                        .eq("user_id", userId));
                return false;
            }
            
            // Update like count atomically
            postMapper.update(null, new com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper<Post>()
                    .eq("id", postId)
                    .setSql("like_count = like_count + 1"));

            // Send notification asynchronously (non-blocking)
            if (!post.getUserId().equals(userId)) {
                try {
                    notificationService.sendNotification(post.getUserId(), "like",
                            "收到点赞", "有人赞了你的帖子",
                            postId.toString());
                    
                    // Send email alert if enabled
                    User liker = userMapper.selectById(userId);
                    String likerName = liker != null ? liker.getUsername() : "某个用户";
                    String emailContent = likerName + " 赞了你的帖子\n\n帖子内容: " + 
                        (post.getContent() != null && post.getContent().length() > 100 ?
                            post.getContent().substring(0, 100) + "..." : post.getContent());
                    emailService.sendEmailAlert(post.getUserId(),
                            "收到点赞 - " + likerName,
                            emailContent);
                } catch (Exception e) {
                    log.error("Failed to send like notification: {}", e.getMessage());
                }
            }

            // Check and award badges to post author based on like count
            try {
                badgeService.checkAndAwardBadges(post.getUserId());
            } catch (Exception e) {
                log.warn("Badge award check failed: {}", e.getMessage());
            }

            return true;
        }
    }

    @Override
    public boolean hasLiked(Long postId, Long userId) {
        QueryWrapper<PostLike> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("post_id", postId)
                .eq("user_id", userId);
        return count(queryWrapper) > 0;
    }

    @Override
    public int getLikeCount(Long postId) {
        QueryWrapper<PostLike> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("post_id", postId);
        return (int) count(queryWrapper);
    }
}