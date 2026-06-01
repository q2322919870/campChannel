package com.gdmec.campchannel.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.gdmec.campchannel.entity.GroupMessage;

import java.util.List;

public interface GroupMessageService extends IService<GroupMessage> {

    GroupMessage sendMessage(Long channelId, Long senderId, String content, String mediaUrl, Integer msgType);

    List<GroupMessage> getChannelMessages(Long channelId, int page, int size);

    void recallMessage(Long messageId, Long userId);
}
