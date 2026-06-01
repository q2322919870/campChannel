package com.gdmec.campchannel.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.gdmec.campchannel.entity.Post;
import com.gdmec.campchannel.entity.PostFavourite;

import java.util.List;

public interface FavouriteService extends IService<PostFavourite> {

    /**
     * 收藏/取消收藏帖子
     * @param postId 帖子ID
     * @param userId 用户ID
     * @return true=收藏, false=取消收藏
     */
    boolean toggleFavourite(Long postId, Long userId);

    /**
     * 检查用户是否已收藏
     */
    boolean hasFavourited(Long postId, Long userId);

    /**
     * 获取用户的收藏帖子列表
     */
    List<Post> getUserFavourites(Long userId, int page, int size);

    /**
     * 获取帖子收藏数
     */
    int getFavouriteCount(Long postId);
}
