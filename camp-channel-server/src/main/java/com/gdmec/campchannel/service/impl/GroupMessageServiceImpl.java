package com.gdmec.campchannel.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.gdmec.campchannel.common.api.ErrorCode;
import com.gdmec.campchannel.common.exception.BusinessException;
import com.gdmec.campchannel.entity.ChannelMember;
import com.gdmec.campchannel.entity.GroupMessage;
import com.gdmec.campchannel.entity.User;
import com.gdmec.campchannel.mapper.ChannelMemberMapper;
import com.gdmec.campchannel.mapper.GroupMessageMapper;
import com.gdmec.campchannel.mapper.UserMapper;
import com.gdmec.campchannel.config.RawWebSocketHandler;
import com.gdmec.campchannel.service.GroupMessageService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
public class GroupMessageServiceImpl extends ServiceImpl<GroupMessageMapper, GroupMessage> implements GroupMessageService {

    @Autowired
    private ChannelMemberMapper channelMemberMapper;

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public GroupMessage sendMessage(Long channelId, Long senderId, String content, String mediaUrl, Integer msgType) {
        QueryWrapper<ChannelMember> memberQuery = new QueryWrapper<>();
        memberQuery.eq("channel_id", channelId)
                .eq("user_id", senderId)
                .eq("status", 1);
        ChannelMember member = channelMemberMapper.selectOne(memberQuery);
        if (member == null) {
            throw new BusinessException(ErrorCode.FORBIDDEN, "您不是该频道成员");
        }

        // Check if user is muted
        if (member.getIsMuted() != null && member.getIsMuted() == 1) {
            throw new BusinessException(ErrorCode.FORBIDDEN, "您已被禁言，无法发送消息");
        }

        GroupMessage msg = new GroupMessage();
        msg.setChannelId(channelId);
        msg.setSenderId(senderId);
        msg.setContent(content);
        msg.setMediaUrl(mediaUrl);
        msg.setMsgType(msgType != null ? msgType : 1);
        msg.setStatus(1);
        save(msg);

        User sender = userMapper.selectById(senderId);
        if (sender != null) {
            msg.setUsername(sender.getUsername());
            msg.setAvatar(sender.getAvatar());
        }

        // Push via STOMP (for PC web client)
        messagingTemplate.convertAndSend("/topic/channel/" + channelId + "/messages", msg);
        
        // Push via Raw WebSocket (for Flutter client)
        try {
            Map<String, Object> wsMsg = new java.util.HashMap<>();
            wsMsg.put("type", "new_group_message");
            wsMsg.put("id", msg.getId());
            wsMsg.put("channelId", channelId);
            wsMsg.put("senderId", senderId);
            wsMsg.put("content", msg.getContent());
            wsMsg.put("mediaUrl", msg.getMediaUrl());
            wsMsg.put("msgType", msg.getMsgType());
            wsMsg.put("status", msg.getStatus());
            wsMsg.put("createTime", msg.getCreateTime());
            if (sender != null) {
                wsMsg.put("username", sender.getUsername());
                wsMsg.put("avatar", sender.getAvatar());
            }
            // Push to all channel members
            List<ChannelMember> members = channelMemberMapper.selectList(
                new QueryWrapper<ChannelMember>()
                    .eq("channel_id", channelId)
                    .eq("status", 1)
            );
            for (ChannelMember m : members) {
                if (!m.getUserId().equals(senderId)) {
                    RawWebSocketHandler.pushToUser(m.getUserId(), wsMsg);
                }
            }
        } catch (Exception e) {
            log.warn("Failed to push group message via Raw WebSocket: {}", e.getMessage());
        }

        return msg;
    }

    @Override
    public List<GroupMessage> getChannelMessages(Long channelId, int page, int size) {
        QueryWrapper<GroupMessage> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("channel_id", channelId)
                .eq("status", 1)
                .orderByDesc("create_time");

        int offset = (page - 1) * size;
        queryWrapper.last("LIMIT " + offset + ", " + size);

        List<GroupMessage> messages = list(queryWrapper);

        List<Long> userIds = messages.stream()
                .map(GroupMessage::getSenderId)
                .distinct()
                .collect(Collectors.toList());

        if (!userIds.isEmpty()) {
            List<User> users = userMapper.selectBatchIds(userIds);
            Map<Long, User> userMap = users.stream()
                    .collect(Collectors.toMap(User::getId, u -> u, (a, b) -> a));

            for (GroupMessage msg : messages) {
                User u = userMap.get(msg.getSenderId());
                if (u != null) {
                    msg.setUsername(u.getUsername());
                    msg.setAvatar(u.getAvatar());
                }
            }
        }

        return messages;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void recallMessage(Long messageId, Long userId) {
        GroupMessage msg = getById(messageId);
        if (msg == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "消息不存在");
        }

        QueryWrapper<ChannelMember> memberQuery = new QueryWrapper<>();
        memberQuery.eq("channel_id", msg.getChannelId())
                .eq("user_id", userId)
                .in("role", "owner", "admin");
        ChannelMember adminMember = channelMemberMapper.selectOne(memberQuery);

        if (!msg.getSenderId().equals(userId) && adminMember == null) {
            throw new BusinessException(ErrorCode.FORBIDDEN, "您无权撤回此消息");
        }

        msg.setStatus(2);
        updateById(msg);

        messagingTemplate.convertAndSend("/topic/channel/" + msg.getChannelId() + "/recall", messageId);
    }
}
