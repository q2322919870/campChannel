package com.gdmec.campchannel.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.gdmec.campchannel.common.exception.BusinessException;
import com.gdmec.campchannel.entity.Channel;
import com.gdmec.campchannel.entity.PostDraft;
import com.gdmec.campchannel.mapper.ChannelMapper;
import com.gdmec.campchannel.mapper.PostDraftMapper;
import com.gdmec.campchannel.service.PostDraftService;
import com.gdmec.campchannel.service.PostService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
public class PostDraftServiceImpl extends ServiceImpl<PostDraftMapper, PostDraft> implements PostDraftService {

    @Autowired
    private ChannelMapper channelMapper;

    @Autowired
    private PostService postService;

    @Override
    public PostDraft saveDraft(Long userId, Long draftId, Long channelId, String content,
                               String images, String videoUrl, String topic, Boolean isAnonymous) {
        PostDraft draft;
        if (draftId != null) {
            // 更新已有草稿
            draft = baseMapper.selectById(draftId);
            if (draft == null || !draft.getUserId().equals(userId)) {
                throw new BusinessException("草稿不存在或无权操作");
            }
        } else {
            // 新建草稿
            draft = new PostDraft();
            draft.setUserId(userId);
        }

        draft.setChannelId(channelId);
        draft.setContent(content);
        draft.setImages(images);
        draft.setVideoUrl(videoUrl);
        draft.setTopic(topic);
        draft.setIsAnonymous(isAnonymous != null ? isAnonymous : false);

        if (draftId != null) {
            baseMapper.updateById(draft);
        } else {
            baseMapper.insert(draft);
        }
        return draft;
    }

    @Override
    public List<PostDraft> getUserDrafts(Long userId, int page, int size) {
        int offset = (page - 1) * size;
        QueryWrapper<PostDraft> wrapper = new QueryWrapper<>();
        wrapper.eq("user_id", userId)
                .orderByDesc("update_time")
                .last("LIMIT " + offset + ", " + size);
        List<PostDraft> drafts = baseMapper.selectList(wrapper);

        // 填充频道名称
        for (PostDraft draft : drafts) {
            if (draft.getChannelId() != null) {
                Channel channel = channelMapper.selectById(draft.getChannelId());
                if (channel != null) {
                    draft.setChannelName(channel.getName());
                }
            }
        }
        return drafts;
    }

    @Override
    public PostDraft getDraftById(Long draftId, Long userId) {
        PostDraft draft = baseMapper.selectById(draftId);
        if (draft == null || !draft.getUserId().equals(userId)) {
            return null;
        }
        if (draft.getChannelId() != null) {
            Channel channel = channelMapper.selectById(draft.getChannelId());
            if (channel != null) {
                draft.setChannelName(channel.getName());
            }
        }
        return draft;
    }

    @Override
    public void deleteDraft(Long draftId, Long userId) {
        PostDraft draft = baseMapper.selectById(draftId);
        if (draft == null || !draft.getUserId().equals(userId)) {
            throw new BusinessException("草稿不存在或无权操作");
        }
        baseMapper.deleteById(draftId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void publishDraft(Long draftId, Long userId) {
        PostDraft draft = baseMapper.selectById(draftId);
        if (draft == null || !draft.getUserId().equals(userId)) {
            throw new BusinessException("草稿不存在或无权操作");
        }
        if (draft.getChannelId() == null) {
            throw new BusinessException("请先选择频道");
        }
        if (draft.getContent() == null || draft.getContent().trim().isEmpty()) {
            throw new BusinessException("草稿内容为空");
        }

        // 将 images 字符串转为 List
        List<String> imageList = null;
        if (draft.getImages() != null && !draft.getImages().isEmpty()) {
            imageList = Arrays.stream(draft.getImages().split(","))
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .collect(Collectors.toList());
        }

        // 将 videoUrl 字符串转为 List
        List<String> videoUrlList = null;
        if (draft.getVideoUrl() != null && !draft.getVideoUrl().isEmpty()) {
            videoUrlList = Arrays.stream(draft.getVideoUrl().split(","))
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .collect(Collectors.toList());
        }

        // 构建完整内容（含话题和@）
        String finalContent = draft.getContent().trim();
        if (draft.getTopic() != null && !draft.getTopic().isEmpty()) {
            String t = draft.getTopic().trim();
            if (!t.startsWith("#")) t = "#" + t;
            if (!t.endsWith("#")) t = t + "#";
            finalContent += "\n" + t;
        }

        // 发布帖子
        postService.createPost(
                draft.getChannelId(),
                userId,
                finalContent,
                imageList,
                videoUrlList,
                draft.getIsAnonymous() != null ? draft.getIsAnonymous() : false
        );

        // 删除草稿
        baseMapper.deleteById(draftId);
    }
}
