package com.gdmec.campchannel.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.gdmec.campchannel.common.api.ErrorCode;
import com.gdmec.campchannel.common.exception.BusinessException;
import com.gdmec.campchannel.entity.Follow;
import com.gdmec.campchannel.entity.Post;
import com.gdmec.campchannel.entity.User;
import com.gdmec.campchannel.mapper.FollowMapper;
import com.gdmec.campchannel.mapper.PostMapper;
import com.gdmec.campchannel.mapper.UserMapper;
import com.gdmec.campchannel.service.FollowService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
public class FollowServiceImpl extends ServiceImpl<FollowMapper, Follow> implements FollowService {

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private PostMapper postMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean toggleFollow(Long followerId, Long followingId) {
        if (followerId.equals(followingId)) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "不能关注自己");
        }

        User targetUser = userMapper.selectById(followingId);
        if (targetUser == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "用户不存在");
        }

        QueryWrapper<Follow> query = new QueryWrapper<>();
        query.eq("follower_id", followerId).eq("following_id", followingId);
        Follow existing = baseMapper.selectOne(query);

        if (existing != null) {
            // Unfollow
            baseMapper.deleteById(existing.getId());
            return false;
        } else {
            // Follow
            Follow follow = new Follow();
            follow.setFollowerId(followerId);
            follow.setFollowingId(followingId);
            baseMapper.insert(follow);
            return true;
        }
    }

    @Override
    public boolean isFollowing(Long followerId, Long followingId) {
        QueryWrapper<Follow> query = new QueryWrapper<>();
        query.eq("follower_id", followerId).eq("following_id", followingId);
        return baseMapper.selectCount(query) > 0;
    }

    @Override
    public List<Follow> getFollowers(Long userId, int page, int size) {
        QueryWrapper<Follow> query = new QueryWrapper<>();
        query.eq("following_id", userId)
                .orderByDesc("create_time");
        int offset = (page - 1) * size;
        query.last("LIMIT " + offset + ", " + size);

        List<Follow> followers = baseMapper.selectList(query);
        // Populate follower user info
        for (Follow f : followers) {
            User follower = userMapper.selectById(f.getFollowerId());
            if (follower != null) {
                f.setFollowerUsername(follower.getUsername());
                f.setFollowerAvatar(follower.getAvatar());
            }
        }
        return followers;
    }

    @Override
    public List<Follow> getFollowing(Long userId, int page, int size) {
        QueryWrapper<Follow> query = new QueryWrapper<>();
        query.eq("follower_id", userId)
                .orderByDesc("create_time");
        int offset = (page - 1) * size;
        query.last("LIMIT " + offset + ", " + size);

        List<Follow> following = baseMapper.selectList(query);
        // Populate followed user info
        for (Follow f : following) {
            User followed = userMapper.selectById(f.getFollowingId());
            if (followed != null) {
                f.setUsername(followed.getUsername());
                f.setAvatar(followed.getAvatar());
            }
        }
        return following;
    }

    @Override
    public int getFollowerCount(Long userId) {
        QueryWrapper<Follow> query = new QueryWrapper<>();
        query.eq("following_id", userId);
        return baseMapper.selectCount(query).intValue();
    }

    @Override
    public int getFollowingCount(Long userId) {
        QueryWrapper<Follow> query = new QueryWrapper<>();
        query.eq("follower_id", userId);
        return baseMapper.selectCount(query).intValue();
    }

    @Override
    public List<?> getFollowingFeed(Long userId, int page, int size) {
        // Get list of followed user IDs
        QueryWrapper<Follow> followQuery = new QueryWrapper<>();
        followQuery.eq("follower_id", userId);
        List<Follow> following = baseMapper.selectList(followQuery);
        List<Long> followedUserIds = following.stream()
                .map(Follow::getFollowingId)
                .collect(Collectors.toList());

        if (followedUserIds.isEmpty()) {
            return Collections.emptyList();
        }

        // Query posts by followed users
        QueryWrapper<Post> postQuery = new QueryWrapper<>();
        postQuery.in("user_id", followedUserIds)
                .eq("status", 1)
                .orderByDesc("create_time");
        int offset = (page - 1) * size;
        postQuery.last("LIMIT " + offset + ", " + size);

        List<Post> posts = postMapper.selectList(postQuery);

        // Enrich with user info
        List<Map<String, Object>> result = new ArrayList<>();
        for (Post post : posts) {
            Map<String, Object> map = new HashMap<>();
            map.put("id", post.getId());
            map.put("content", post.getContent());
            map.put("topic", post.getTopic());
            map.put("images", post.getImages());
            map.put("likeCount", post.getLikeCount());
            map.put("commentCount", post.getCommentCount());
            map.put("createTime", post.getCreateTime());
            map.put("channelId", post.getChannelId());

            User author = userMapper.selectById(post.getUserId());
            if (author != null) {
                map.put("userId", author.getId());
                map.put("username", author.getUsername());
                map.put("avatar", author.getAvatar());
            }
            result.add(map);
        }
        return result;
    }
}
