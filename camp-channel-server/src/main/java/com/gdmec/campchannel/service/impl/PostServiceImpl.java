package com.gdmec.campchannel.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gdmec.campchannel.common.api.ErrorCode;
import com.gdmec.campchannel.common.exception.BusinessException;
import com.gdmec.campchannel.common.filter.SensitiveWordFilter;
import com.gdmec.campchannel.common.utils.RedisUtils;
import com.gdmec.campchannel.entity.ChannelMember;
import com.gdmec.campchannel.entity.Post;
import com.gdmec.campchannel.entity.PostLike;
import com.gdmec.campchannel.entity.User;
import com.gdmec.campchannel.mapper.ChannelMemberMapper;
import com.gdmec.campchannel.mapper.PostLikeMapper;
import com.gdmec.campchannel.mapper.PostMapper;
import com.gdmec.campchannel.mapper.UserMapper;
import com.gdmec.campchannel.service.NotificationService;
import com.gdmec.campchannel.service.PostService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import lombok.extern.slf4j.Slf4j;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Slf4j
@Service
public class PostServiceImpl extends ServiceImpl<PostMapper, Post> implements PostService {

    @Autowired
    private RedisUtils redisUtils;

    @Autowired
    private SensitiveWordFilter sensitiveWordFilter;

    @Autowired
    private ChannelMemberMapper channelMemberMapper;

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private PostLikeMapper postLikeMapper;

    @Autowired
    private NotificationService notificationService;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Post createPost(Long channelId, Long userId, String content, List<String> images, String videoUrl, boolean isAnonymous) {
        if (!StringUtils.hasText(content)) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "帖子内容不能为空");
        }

        // Rate limiting with fallback
        try {
            String rateLimitKey = "post_rate_limit:" + userId;
            boolean allowed = redisUtils.isAllowedRateLimit(rateLimitKey, 3, 60);
            if (!allowed) {
                throw new BusinessException(ErrorCode.TOO_MANY_REQUESTS, "发帖过于频繁，请1分钟后再试");
            }
        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            log.warn("Redis限流检查失败，跳过限流: {}", e.getMessage());
        }

        // Sensitive word check with fallback
        int status = 1;
        try {
            boolean hasSensitive = sensitiveWordFilter.contains(content);
            if (hasSensitive) status = 0;
        } catch (Exception e) {
            log.warn("敏感词检测失败，跳过审核: {}", e.getMessage());
        }

        Post post = new Post();
        post.setChannelId(channelId);
        post.setUserId(userId);
        post.setContent(content);
        
        // Serialize images safely
        if (images != null && !images.isEmpty()) {
            try {
                post.setImages(objectMapper.writeValueAsString(images));
            } catch (JsonProcessingException e) {
                log.error("图片数据序列化失败: {}", e.getMessage());
                throw new BusinessException(ErrorCode.SYSTEM_ERROR, "图片数据序列化失败");
            }
        }
        
        post.setVideoUrl(videoUrl);
        post.setIsAnonymous(isAnonymous);
        
        // 树洞告白设置24小时过期时间
        if (isAnonymous && channelId == null) {
            post.setExpireTime(LocalDateTime.now().plusHours(24));
        }
        
        // Extract topic and mentions
        try {
            String topic = extractTopic(content);
            post.setTopic(topic);
            
            String mentions = extractMentions(content);
            post.setMentionedUsers(mentions);
            
            // Send notifications to mentioned users asynchronously
            if (mentions != null && !mentions.isEmpty()) {
                String[] mentionArray = mentions.split(",");
                for (String mentionName : mentionArray) {
                    if (!mentionName.trim().isEmpty()) {
                        try {
                            // Find user by username
                            QueryWrapper<User> userQuery = new QueryWrapper<>();
                            userQuery.eq("username", mentionName.trim());
                            User mentionedUser = userMapper.selectOne(userQuery);
                            
                            if (mentionedUser != null && !mentionedUser.getId().equals(userId)) {
                                notificationService.sendNotification(
                                    mentionedUser.getId(),
                                    "mention",
                                    "有人@了你",
                                    userId + " 在帖子中提到了你",
                                    post.getId().toString()
                                );
                            }
                        } catch (Exception e) {
                            log.warn("Failed to notify mentioned user {}: {}", mentionName, e.getMessage());
                        }
                    }
                }
            }
        } catch (Exception e) {
            log.warn("话题提取或@通知失败: {}", e.getMessage());
        }
        
        post.setStatus(status);
        post.setViewCount(0);
        post.setLikeCount(0);
        post.setCommentCount(0);

        try {
            save(post);
            return post;
        } catch (Exception e) {
            log.error("保存帖子失败: {}", e.getMessage());
            throw new BusinessException(ErrorCode.SYSTEM_ERROR, "发布帖子失败，请稍后重试");
        }
    }

    @Override
    public List<Post> getChannelPosts(Long channelId, int page, int size, Long currentUserId) {
        QueryWrapper<Post> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("channel_id", channelId)
                .eq("status", 1)
                .orderByDesc("is_pinned")  // Pinned posts first
                .orderByDesc("create_time");
        
        int offset = (page - 1) * size;
        queryWrapper.last("LIMIT " + offset + ", " + size);
        
        List<Post> posts = list(queryWrapper);

        // 附加用户在频道中的角色信息
        List<ChannelMember> members = channelMemberMapper.selectList(
                new QueryWrapper<ChannelMember>()
                        .eq("channel_id", channelId)
                        .eq("status", 1));
        Map<Long, String> userRoleMap = members.stream()
                .collect(Collectors.toMap(ChannelMember::getUserId, ChannelMember::getRole, (a, b) -> a));

        for (Post post : posts) {
            String role = userRoleMap.get(post.getUserId());
            if (role == null) role = "member";
            post.setUserChannelRole(role);
            maskAnonymous(post);
        }

        // 填充当前用户点赞状态
        if (currentUserId != null) {
            List<Long> postIds = posts.stream().map(Post::getId).toList();
            if (!postIds.isEmpty()) {
                List<PostLike> likes = postLikeMapper.selectList(
                        new QueryWrapper<PostLike>()
                                .in("post_id", postIds)
                                .eq("user_id", currentUserId));
                Set<Long> likedPostIds = likes.stream().map(PostLike::getPostId).collect(Collectors.toSet());
                for (Post post : posts) {
                    post.setIsLiked(likedPostIds.contains(post.getId()));
                }
            }
        }

        return posts;
    }

    @Override
    public Post getPostById(Long postId) {
        Post post = getById(postId);
        if (post == null) return null;
        maskAnonymous(post);
        return post;
    }

    @Override
    public List<Post> getLikedPosts(Long userId, int page, int size) {
        int offset = (page - 1) * size;
        List<Long> postIds = postLikeMapper.selectList(
                new QueryWrapper<com.gdmec.campchannel.entity.PostLike>()
                        .eq("user_id", userId)
                        .orderByDesc("create_time")
                        .last("LIMIT " + offset + ", " + size)
        ).stream().map(com.gdmec.campchannel.entity.PostLike::getPostId).toList();
        if (postIds.isEmpty()) return List.of();
        QueryWrapper<Post> queryWrapper = new QueryWrapper<>();
        queryWrapper.in("id", postIds)
                .eq("status", 1)
                .orderByDesc("create_time");
        List<Post> posts = list(queryWrapper);
        for (Post post : posts) {
            maskAnonymous(post);
        }
        return posts;
    }

    @Override
    public List<Post> getUserPosts(Long userId, int page, int size) {
        QueryWrapper<Post> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("user_id", userId)
                .in("status", 0, 1)
                .orderByDesc("create_time");
        
        int offset = (page - 1) * size;
        queryWrapper.last("LIMIT " + offset + ", " + size);
        
        List<Post> posts = list(queryWrapper);

        // 附加用户在频道中的角色信息
        if (!posts.isEmpty()) {
            List<Long> channelIds = posts.stream()
                    .map(Post::getChannelId)
                    .distinct()
                    .collect(Collectors.toList());

            List<ChannelMember> members = channelMemberMapper.selectList(
                    new QueryWrapper<ChannelMember>()
                            .in("channel_id", channelIds)
                            .eq("user_id", userId)
                            .eq("status", 1));

            Map<Long, String> channelRoleMap = members.stream()
                    .collect(Collectors.toMap(ChannelMember::getChannelId, ChannelMember::getRole, (a, b) -> a));

            for (Post post : posts) {
                String role = channelRoleMap.get(post.getChannelId());
                if (role == null) role = "member";
                post.setUserChannelRole(role);
                maskAnonymous(post);
            }
        }

        return posts;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deletePost(Long postId, Long userId) {
        Post post = getById(postId);
        if (post == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "帖子不存在");
        }
        
        if (!post.getUserId().equals(userId)) {
            throw new BusinessException(ErrorCode.FORBIDDEN, "您无权删除此帖子");
        }

        post.setStatus(2);
        updateById(post);
    }

    @Override
    public void incrementViewCount(Long postId) {
        Post post = getById(postId);
        if (post != null) {
            post.setViewCount(post.getViewCount() + 1);
            updateById(post);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updatePost(Long postId, Long userId, String content, List<String> images, String videoUrl) {
        Post post = getById(postId);
        if (post == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "帖子不存在");
        }

        if (!post.getUserId().equals(userId)) {
            throw new BusinessException(ErrorCode.FORBIDDEN, "您无权编辑此帖子");
        }

        if (post.getStatus() == 2) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "已删除的帖子无法编辑");
        }

        if (StringUtils.hasText(content)) {
            int status = 1;
            boolean hasSensitive = sensitiveWordFilter.contains(content);
            if (hasSensitive) {
                status = 0;
            }
            post.setContent(content);
            post.setStatus(status);
            post.setTopic(extractTopic(content));
        }

        if (images != null) {
            try {
                post.setImages(objectMapper.writeValueAsString(images));
            } catch (JsonProcessingException e) {
                throw new BusinessException(ErrorCode.SYSTEM_ERROR, "图片数据序列化失败");
            }
        }

        if (videoUrl != null) {
            post.setVideoUrl(videoUrl);
        }

        updateById(post);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public java.util.Map<String, Object> togglePin(Long postId, Long userId) {
        Post post = getById(postId);
        if (post == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "帖子不存在");
        }

        // Check if user is channel owner or admin
        QueryWrapper<ChannelMember> memberQuery = new QueryWrapper<>();
        memberQuery.eq("channel_id", post.getChannelId())
                .eq("user_id", userId)
                .in("role", "owner", "admin");
        ChannelMember member = channelMemberMapper.selectOne(memberQuery);
        if (member == null) {
            throw new BusinessException(ErrorCode.FORBIDDEN, "只有频道主或管理员可以置顶帖子");
        }

        // Toggle pin status
        boolean isPinned = post.getIsPinned() != null && post.getIsPinned() == 1;
        post.setIsPinned(isPinned ? 0 : 1);
        updateById(post);

        java.util.Map<String, Object> result = new java.util.HashMap<>();
        result.put("isPinned", post.getIsPinned() == 1);
        result.put("message", post.getIsPinned() == 1 ? "已置顶" : "已取消置顶");
        return result;
    }

    @Override
    public java.util.List<Post> searchPosts(String keyword, int page, int size, Long currentUserId) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return new java.util.ArrayList<>();
        }

        String searchPattern = "%" + keyword.trim() + "%";
        QueryWrapper<Post> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("status", 1)
                .and(wrapper -> wrapper
                        .like("content", searchPattern)
                        .or().like("topic", searchPattern)
                        .or().like("mentioned_users", searchPattern)
                )
                .orderByDesc("is_pinned")
                .orderByDesc("create_time");

        int offset = (page - 1) * size;
        queryWrapper.last("LIMIT " + offset + ", " + size);

        java.util.List<Post> posts = list(queryWrapper);

        // Populate user info and like status
        for (Post post : posts) {
            maskAnonymous(post);
            if (currentUserId != null) {
                QueryWrapper<com.gdmec.campchannel.entity.PostLike> likeQuery = new QueryWrapper<>();
                likeQuery.eq("post_id", post.getId()).eq("user_id", currentUserId);
                post.setIsLiked(postLikeMapper.selectOne(likeQuery) != null);
            }
        }

        return posts;
    }

    @Override
    public java.util.List<Post> getHotPosts(int limit, Long currentUserId) {
        // Get posts from last 7 days
        LocalDateTime sevenDaysAgo = LocalDateTime.now().minusDays(7);
        QueryWrapper<Post> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("status", 1)
                .ge("create_time", sevenDaysAgo)
                .orderByDesc("view_count")
                .orderByDesc("like_count")
                .orderByDesc("comment_count")
                .last("LIMIT " + limit);

        java.util.List<Post> posts = list(queryWrapper);

        // Populate user info and like status
        for (Post post : posts) {
            maskAnonymous(post);
            if (currentUserId != null) {
                QueryWrapper<com.gdmec.campchannel.entity.PostLike> likeQuery = new QueryWrapper<>();
                likeQuery.eq("post_id", post.getId()).eq("user_id", currentUserId);
                post.setIsLiked(postLikeMapper.selectOne(likeQuery) != null);
            }
        }

        return posts;
    }

    /** Populate username/avatar, masking identity for anonymous posts */
    private void maskAnonymous(Post post) {
        if (Boolean.TRUE.equals(post.getIsAnonymous())) {
            post.setUsername("匿名");
            post.setAvatar(null);
        } else {
            User user = userMapper.selectById(post.getUserId());
            if (user != null) {
                post.setUsername(user.getUsername());
                post.setAvatar(user.getAvatar());
            }
        }
    }

    private String extractTopic(String content) {
        if (!StringUtils.hasText(content)) {
            return null;
        }
        
        int start = content.indexOf("#");
        if (start == -1) {
            return null;
        }
        
        int end = content.indexOf("#", start + 1);
        if (end == -1) {
            return null;
        }
        
        return content.substring(start, end + 1);
    }

    private String extractMentions(String content) {
        if (!StringUtils.hasText(content)) {
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