package com.gdmec.campchannel.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.gdmec.campchannel.entity.Channel;
import com.gdmec.campchannel.entity.ChannelMember;

import java.util.List;

public interface ChannelService extends IService<Channel> {

    /**
     * 创建频道
     */
    Channel createChannel(String name, String description, Long creatorId);

    /**
     * 搜索频道（按编号或名称模糊搜索）
     */
    List<Channel> searchChannels(String keyword);

    /**
     * 申请加入频道
     */
    void applyJoinChannel(Long channelId, Long userId);

    /**
     * 审核加入申请
     */
    void approveJoinApplication(Long applicationId, Long approveUserId, boolean approved);

    /**
     * 获取用户已加入的频道列表
     */
    List<Channel> getUserChannels(Long userId);

    /**
     * 获取频道的待审核申请列表
     */
    List<com.gdmec.campchannel.entity.ChannelMember> getPendingApplications(Long channelId);

    /**
     * 退出频道
     */
    void leaveChannel(Long channelId, Long userId);

    /**
     * 编辑频道信息
     */
    void updateChannel(Long channelId, String name, String description, Long userId);

    /**
     * 获取频道成员列表
     */
    List<com.gdmec.campchannel.entity.ChannelMember> getChannelMembers(Long channelId);

    /**
     * 获取用户管理的频道中待审核申请的总数
     */
    int getPendingApplicationCount(Long userId);

    /**
     * 获取用户管理的频道中待审核申请列表
     */
    List<ChannelMember> getPendingApplicationsForOwner(Long userId);

    /**
     * 移除频道成员
     */
    void removeMember(Long channelId, Long targetUserId, Long operatorId);

    /**
     * 设置/取消频道管理员
     */
    void setMemberRole(Long channelId, Long targetUserId, Long operatorId, String role);

    /**
     * 禁言/取消禁言频道成员
     */
    void muteMember(Long channelId, Long targetUserId, Long operatorId, boolean muted);
}