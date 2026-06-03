package com.gdmec.campchannel.controller;

import com.gdmec.campchannel.common.api.Result;
import com.gdmec.campchannel.entity.PostDraft;
import com.gdmec.campchannel.security.SecurityUser;
import com.gdmec.campchannel.service.PostDraftService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "帖子草稿模块", description = "草稿的保存、查询、删除、发布")
@Slf4j
@RestController
@RequestMapping("/drafts")
public class DraftController {

    @Autowired
    private PostDraftService postDraftService;

    @PostMapping
    @Operation(summary = "保存草稿（新增或更新）")
    public Result<PostDraft> saveDraft(
            @RequestBody SaveDraftRequest request,
            @AuthenticationPrincipal SecurityUser currentUser) {
        PostDraft draft = postDraftService.saveDraft(
                currentUser.getId(),
                request.getId(),
                request.getChannelId(),
                request.getContent(),
                request.getImages(),
                request.getVideoUrl(),
                request.getTopic(),
                request.getIsAnonymous()
        );
        return Result.success("草稿已保存", draft);
    }

    @GetMapping
    @Operation(summary = "获取我的草稿列表")
    public Result<List<PostDraft>> getMyDrafts(
            @AuthenticationPrincipal SecurityUser currentUser,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        List<PostDraft> drafts = postDraftService.getUserDrafts(currentUser.getId(), page, size);
        return Result.success(drafts);
    }

    @GetMapping("/{draftId}")
    @Operation(summary = "获取单个草稿详情")
    public Result<PostDraft> getDraft(
            @PathVariable Long draftId,
            @AuthenticationPrincipal SecurityUser currentUser) {
        PostDraft draft = postDraftService.getDraftById(draftId, currentUser.getId());
        if (draft == null) {
            return Result.failed(404, "草稿不存在");
        }
        return Result.success(draft);
    }

    @DeleteMapping("/{draftId}")
    @Operation(summary = "删除草稿")
    public Result<Void> deleteDraft(
            @PathVariable Long draftId,
            @AuthenticationPrincipal SecurityUser currentUser) {
        postDraftService.deleteDraft(draftId, currentUser.getId());
        return Result.success("草稿已删除", null);
    }

    @PostMapping("/{draftId}/publish")
    @Operation(summary = "发布草稿")
    public Result<Void> publishDraft(
            @PathVariable Long draftId,
            @AuthenticationPrincipal SecurityUser currentUser) {
        postDraftService.publishDraft(draftId, currentUser.getId());
        return Result.success("帖子已发布", null);
    }

    @Data
    public static class SaveDraftRequest {
        private Long id;           // 如果为 null 则新建，否则更新
        private Long channelId;
        private String content;
        private String images;     // 逗号分隔的图片 URL
        private String videoUrl;
        private String topic;
        private Boolean isAnonymous;
    }
}
