package com.gdmec.campchannel.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.gdmec.campchannel.entity.Gallery;

import java.util.List;
import java.util.Map;

public interface GalleryService extends IService<Gallery> {

    Gallery addGallery(Long userId, String imageUrl, String videoUrl, Integer mediaType, String title, String description, Long channelId);

    List<Gallery> getGalleryList(int page, int size, Long channelId);

    void deleteGallery(Long galleryId, Long userId);

    void adminDeleteGallery(Long galleryId);

    List<Gallery> getMyGallery(Long userId);

    List<Gallery> getPendingGalleries();

    void approveGallery(Long galleryId, boolean approved);

    boolean toggleLike(Long galleryId, Long userId);

    boolean hasLiked(Long galleryId, Long userId);

    int getLikeCount(Long galleryId);

    Map<String, Object> addComment(Long galleryId, Long userId, String content);

    List<Map<String, Object>> getComments(Long galleryId);

    void shareGallery(Long galleryId, Long userId, Long targetUserId);
}
