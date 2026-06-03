package com.gdmec.campchannel.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.gdmec.campchannel.entity.PostDraft;

import java.util.List;

public interface PostDraftService extends IService<PostDraft> {

    /**
     * 保存草稿（新增或更新）
     */
    PostDraft saveDraft(Long userId, Long draftId, Long channelId, String content,
                        String images, String videoUrl, String topic, Boolean isAnonymous);

    /**
     * 获取用户的草稿列表
     */
    List<PostDraft> getUserDrafts(Long userId, int page, int size);

    /**
     * 获取单个草稿
     */
    PostDraft getDraftById(Long draftId, Long userId);

    /**
     * 删除草稿
     */
    void deleteDraft(Long draftId, Long userId);

    /**
     * 发布草稿（将草稿转为正式帖子并删除草稿）
     */
    void publishDraft(Long draftId, Long userId);
}
