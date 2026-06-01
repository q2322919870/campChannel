package com.gdmec.campchannel.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.gdmec.campchannel.entity.Message;

import java.util.List;

public interface MessageService extends IService<Message> {

    /**
     * 发送消息（WebSocket 实时推送 + 云端持久化）
     */
    Message sendMessage(Long senderId, Long receiverId, String content, Integer type);

    /**
     * 获取聊天记录（分页）
     */
    List<Message> getChatHistory(Long userId, Long friendId, int page, int size);

    /**
     * 撤回消息（2分钟内）
     */
    void recallMessage(Long messageId, Long userId);

    /**
     * 获取用户会话列表（每个好友最近一条消息）
     */
    List<com.gdmec.campchannel.entity.Message> getConversations(Long userId);

    /**
     * 获取与某好友的未读消息数
     */
    int getUnreadCount(Long userId, Long friendId);

    /**
     * 标记单条消息为已读
     */
    void markAsRead(Long messageId, Long userId);

    /**
     * 标记与某好友的所有消息为已读
     */
    void markAllAsRead(Long userId, Long friendId);
}