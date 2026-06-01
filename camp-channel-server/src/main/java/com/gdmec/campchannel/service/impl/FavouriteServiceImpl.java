package com.gdmec.campchannel.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.gdmec.campchannel.entity.Post;
import com.gdmec.campchannel.entity.PostFavourite;
import com.gdmec.campchannel.entity.User;
import com.gdmec.campchannel.mapper.PostFavouriteMapper;
import com.gdmec.campchannel.mapper.PostMapper;
import com.gdmec.campchannel.mapper.UserMapper;
import com.gdmec.campchannel.service.FavouriteService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Slf4j
@Service
public class FavouriteServiceImpl extends ServiceImpl<PostFavouriteMapper, PostFavourite> implements FavouriteService {

    @Autowired
    private PostMapper postMapper;

    @Autowired
    private UserMapper userMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean toggleFavourite(Long postId, Long userId) {
        // 检查帖子是否存在
        Post post = postMapper.selectById(postId);
        if (post == null) {
            throw new RuntimeException("帖子不存在");
        }

        // 检查是否已收藏
        QueryWrapper<PostFavourite> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("post_id", postId).eq("user_id", userId);
        PostFavourite existing = getOne(queryWrapper);

        if (existing != null) {
            // 取消收藏
            removeById(existing.getId());
            log.info("用户 {} 取消收藏帖子 {}", userId, postId);
            return false;
        } else {
            // 收藏
            PostFavourite favourite = new PostFavourite();
            favourite.setPostId(postId);
            favourite.setUserId(userId);
            save(favourite);
            log.info("用户 {} 收藏帖子 {}", userId, postId);
            return true;
        }
    }

    @Override
    public boolean hasFavourited(Long postId, Long userId) {
        QueryWrapper<PostFavourite> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("post_id", postId).eq("user_id", userId);
        return count(queryWrapper) > 0;
    }

    @Override
    public List<Post> getUserFavourites(Long userId, int page, int size) {
        int offset = (page - 1) * size;
        
        // 查询用户收藏的帖子ID列表
        QueryWrapper<PostFavourite> favWrapper = new QueryWrapper<>();
        favWrapper.eq("user_id", userId)
                  .orderByDesc("create_time")
                  .last("LIMIT " + offset + ", " + size);
        List<PostFavourite> favourites = list(favWrapper);

        if (favourites.isEmpty()) {
            return List.of();
        }

        // 获取帖子详情
        List<Long> postIds = favourites.stream()
                .map(PostFavourite::getPostId)
                .toList();
        
        QueryWrapper<Post> postWrapper = new QueryWrapper<>();
        postWrapper.in("id", postIds)
                   .eq("status", 1);
        List<Post> posts = postMapper.selectList(postWrapper);

        // 填充用户信息
        for (Post p : posts) {
            maskAnonymousPost(p);
        }

        return posts;
    }

    @Override
    public int getFavouriteCount(Long postId) {
        QueryWrapper<PostFavourite> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("post_id", postId);
        return Math.toIntExact(count(queryWrapper));
    }

    /**
     * 匿名帖子处理（与 PostController 保持一致）
     */
    private void maskAnonymousPost(Post post) {
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
}
