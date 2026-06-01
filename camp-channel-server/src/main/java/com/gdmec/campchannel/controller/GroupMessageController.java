package com.gdmec.campchannel.controller;

import com.gdmec.campchannel.common.api.Result;
import com.gdmec.campchannel.entity.GroupMessage;
import com.gdmec.campchannel.security.SecurityUser;
import com.gdmec.campchannel.service.GroupMessageService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "群聊消息模块", description = "频道内群聊消息的发送、查询、撤回功能")
@Slf4j
@RestController
@RequestMapping("/group-messages")
public class GroupMessageController {

    @Autowired
    private GroupMessageService groupMessageService;

    @PostMapping
    @Operation(summary = "发送群聊消息")
    public Result<GroupMessage> sendMessage(
            @RequestBody SendMessageRequest request,
            @AuthenticationPrincipal SecurityUser currentUser) {

        GroupMessage msg = groupMessageService.sendMessage(
                request.getChannelId(),
                currentUser.getId(),
                request.getContent(),
                request.getMediaUrl(),
                request.getMsgType()
        );
        return Result.success("发送成功", msg);
    }

    @GetMapping("/{channelId}")
    @Operation(summary = "获取频道群聊消息")
    public Result<List<GroupMessage>> getChannelMessages(
            @PathVariable Long channelId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "50") int size) {

        List<GroupMessage> messages = groupMessageService.getChannelMessages(channelId, page, size);
        return Result.success(messages);
    }

    @DeleteMapping("/{messageId}")
    @Operation(summary = "撤回群聊消息")
    public Result<Void> recallMessage(
            @PathVariable Long messageId,
            @AuthenticationPrincipal SecurityUser currentUser) {

        groupMessageService.recallMessage(messageId, currentUser.getId());
        return Result.success("已撤回", null);
    }

    @Data
    public static class SendMessageRequest {
        private Long channelId;
        private String content;
        private String mediaUrl;
        private Integer msgType;
    }
}
