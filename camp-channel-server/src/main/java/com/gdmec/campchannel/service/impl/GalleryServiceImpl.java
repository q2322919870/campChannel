package com.gdmec.campchannel.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.gdmec.campchannel.common.api.ErrorCode;
import com.gdmec.campchannel.common.exception.BusinessException;
import com.gdmec.campchannel.entity.Gallery;
import com.gdmec.campchannel.entity.GalleryLike;
import com.gdmec.campchannel.entity.GalleryComment;
import com.gdmec.campchannel.entity.User;
import com.gdmec.campchannel.mapper.GalleryMapper;
import com.gdmec.campchannel.mapper.GalleryLikeMapper;
import com.gdmec.campchannel.mapper.GalleryCommentMapper;
import com.gdmec.campchannel.mapper.UserMapper;
import com.gdmec.campchannel.service.GalleryService;
import com.gdmec.campchannel.service.NotificationService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
public class GalleryServiceImpl extends ServiceImpl<GalleryMapper, Gallery> implements GalleryService {

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private NotificationService notificationService;

    @Autowired
    private GalleryLikeMapper galleryLikeMapper;

    @Autowired
    private GalleryCommentMapper galleryCommentMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Gallery addGallery(Long userId, String imageUrl, String videoUrl, Integer mediaType, String title, String description, Long channelId) {
        Gallery gallery = new Gallery();
        gallery.setUserId(userId);
        gallery.setImageUrl(imageUrl);
        gallery.setVideoUrl(videoUrl);
        gallery.setMediaType(mediaType != null ? mediaType : 1);
        gallery.setTitle(title);
        gallery.setDescription(description);
        gallery.setChannelId(channelId);
        gallery.setStatus(1);
        save(gallery);

        User user = userMapper.selectById(userId);
        if (user != null) {
            gallery.setUsername(user.getUsername());
            gallery.setAvatar(user.getAvatar());
        }
        return gallery;
    }

    @Override
    public List<Gallery> getGalleryList(int page, int size, Long channelId) {
        int offset = (page - 1) * size;
        QueryWrapper<Gallery> query = new QueryWrapper<>();
        query.eq("status", 1);
        if (channelId != null && channelId > 0) {
            // 查询指定频道的画作 AND 全局画作（channel_id=0）
            query.and(w -> w.eq("channel_id", channelId)
                          .or()
                          .eq("channel_id", 0));
        }
        query.orderByDesc("create_time").last("LIMIT " + offset + ", " + size);
        List<Gallery> list = list(query);

        // 填充用户信息
        List<Long> userIds = list.stream().map(Gallery::getUserId).distinct().toList();
        if (!userIds.isEmpty()) {
            List<User> users = userMapper.selectBatchIds(userIds);
            Map<Long, User> userMap = users.stream().collect(Collectors.toMap(User::getId, u -> u, (a, b) -> a));
            for (Gallery g : list) {
                User u = userMap.get(g.getUserId());
                if (u != null) {
                    g.setUsername(u.getUsername());
                    g.setAvatar(u.getAvatar());
                }
            }
        }
        return list;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteGallery(Long galleryId, Long userId) {
        Gallery g = getById(galleryId);
        if (g == null) throw new BusinessException(ErrorCode.BAD_REQUEST, "画不存在");
        if (!g.getUserId().equals(userId)) throw new com.gdmec.campchannel.common.exception.BusinessException(ErrorCode.FORBIDDEN, "只能删除自己的画");
        removeById(galleryId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void adminDeleteGallery(Long galleryId) {
        removeById(galleryId);
    }

    @Override
    public List<Gallery> getMyGallery(Long userId) {
        QueryWrapper<Gallery> query = new QueryWrapper<>();
        query.eq("user_id", userId).eq("status", 1).orderByDesc("create_time");
        return list(query);
    }

    @Override
    public List<Gallery> getPendingGalleries() {
        QueryWrapper<Gallery> query = new QueryWrapper<>();
        query.eq("status", 0).orderByDesc("create_time");
        List<Gallery> list = list(query);
        List<Long> userIds = list.stream().map(Gallery::getUserId).distinct().toList();
        if (!userIds.isEmpty()) {
            List<User> users = userMapper.selectBatchIds(userIds);
            Map<Long, User> userMap = users.stream().collect(Collectors.toMap(User::getId, u -> u, (a, b) -> a));
            for (Gallery g : list) {
                User u = userMap.get(g.getUserId());
                if (u != null) g.setUsername(u.getUsername());
            }
        }
        return list;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void approveGallery(Long galleryId, boolean approved) {
        Gallery g = getById(galleryId);
        if (g == null) throw new BusinessException(ErrorCode.BAD_REQUEST, "画不存在");
        g.setStatus(approved ? 1 : 2);
        updateById(g);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean toggleLike(Long galleryId, Long userId) {
        QueryWrapper<GalleryLike> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("gallery_id", galleryId).eq("user_id", userId);
        GalleryLike existing = galleryLikeMapper.selectOne(queryWrapper);

        if (existing != null) {
            galleryLikeMapper.deleteById(existing.getId());
            return false;
        } else {
            GalleryLike like = new GalleryLike();
            like.setGalleryId(galleryId);
            like.setUserId(userId);
            try {
                galleryLikeMapper.insert(like);
            } catch (DuplicateKeyException e) {
                log.warn("Duplicate gallery like, removing: gallery={}, user={}", galleryId, userId);
                galleryLikeMapper.delete(new QueryWrapper<GalleryLike>()
                        .eq("gallery_id", galleryId)
                        .eq("user_id", userId));
                return false;
            }
            return true;
        }
    }

    @Override
    public boolean hasLiked(Long galleryId, Long userId) {
        QueryWrapper<GalleryLike> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("gallery_id", galleryId).eq("user_id", userId);
        return galleryLikeMapper.selectCount(queryWrapper) > 0;
    }

    @Override
    public int getLikeCount(Long galleryId) {
        QueryWrapper<GalleryLike> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("gallery_id", galleryId);
        return galleryLikeMapper.selectCount(queryWrapper).intValue();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Map<String, Object> addComment(Long galleryId, Long userId, String content) {
        Gallery g = getById(galleryId);
        if (g == null) throw new BusinessException(ErrorCode.BAD_REQUEST, "画作不存在");

        GalleryComment comment = new GalleryComment();
        comment.setGalleryId(galleryId);
        comment.setUserId(userId);
        comment.setContent(content);
        comment.setStatus(1);
        galleryCommentMapper.insert(comment);

        Map<String, Object> result = new HashMap<>();
        result.put("id", comment.getId());
        result.put("userId", userId);
        result.put("content", content);
        result.put("createTime", comment.getCreateTime() != null ? comment.getCreateTime().toString() : "");
        
        User user = userMapper.selectById(userId);
        if (user != null) {
            result.put("username", user.getUsername());
            result.put("avatar", user.getAvatar());
        }
        return result;
    }

    @Override
    public List<Map<String, Object>> getComments(Long galleryId) {
        QueryWrapper<GalleryComment> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("gallery_id", galleryId)
                .eq("status", 1)
                .orderByDesc("create_time");
        List<GalleryComment> comments = galleryCommentMapper.selectList(queryWrapper);

        List<Map<String, Object>> result = new java.util.ArrayList<>();
        for (GalleryComment c : comments) {
            Map<String, Object> map = new HashMap<>();
            map.put("id", c.getId());
            map.put("userId", c.getUserId());
            map.put("content", c.getContent());
            map.put("createTime", c.getCreateTime() != null ? c.getCreateTime().toString() : "");
            
            User user = userMapper.selectById(c.getUserId());
            if (user != null) {
                map.put("username", user.getUsername());
                map.put("avatar", user.getAvatar());
            }
            result.add(map);
        }
        return result;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void shareGallery(Long galleryId, Long userId, Long targetUserId) {
        Gallery g = getById(galleryId);
        if (g == null) throw new BusinessException(ErrorCode.BAD_REQUEST, "画作不存在");
        User sharer = userMapper.selectById(userId);
        String sharerName = sharer != null ? sharer.getUsername() : "用户";
        if (targetUserId != null) {
            notificationService.sendNotification(targetUserId, "share",
                    sharerName + " 分享了一幅画",
                    g.getTitle() != null ? g.getTitle() : "查看画作",
                    galleryId.toString());
        }
    }
}
