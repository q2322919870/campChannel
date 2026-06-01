package com.gdmec.campchannel.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.gdmec.campchannel.common.api.ErrorCode;
import com.gdmec.campchannel.common.exception.BusinessException;
import com.gdmec.campchannel.entity.Channel;
import com.gdmec.campchannel.entity.ChannelMember;
import com.gdmec.campchannel.mapper.ChannelMapper;
import com.gdmec.campchannel.mapper.ChannelMemberMapper;
import com.gdmec.campchannel.service.ChannelService;
import com.gdmec.campchannel.mapper.UserMapper;
import com.gdmec.campchannel.service.NotificationService;
import org.springframework.beans.factory.annotation.Autowired;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Random;

@Service
public class ChannelServiceImpl extends ServiceImpl<ChannelMapper, Channel> implements ChannelService {

    @Autowired
    private ChannelMemberMapper channelMemberMapper;

    @Autowired
    private NotificationService notificationService;

    @Autowired
    private UserMapper userMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Channel createChannel(String name, String description, Long creatorId) {
        if (!StringUtils.hasText(name)) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "频道名称不能为空");
        }

        Channel channel = new Channel();
        channel.setName(name);
        channel.setDescription(description);
        channel.setType(2);
        channel.setStatus(1);
        channel.setCreatorId(creatorId);
        channel.setChannelCode(generateChannelCode());

        save(channel);

        ChannelMember member = new ChannelMember();
        member.setChannelId(channel.getId());
        member.setUserId(creatorId);
        member.setRole("owner");
        member.setStatus(1);
        member.setApplyTime(LocalDateTime.now());
        member.setApproveTime(LocalDateTime.now());
        member.setApproveUserId(creatorId);
        channelMemberMapper.insert(member);

        return channel;
    }

    @Override
    public List<Channel> searchChannels(String keyword) {
        QueryWrapper<Channel> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("status", 1);
        
        if (StringUtils.hasText(keyword)) {
            queryWrapper.and(wrapper -> wrapper
                    .like("channel_code", keyword)
                    .or()
                    .like("name", keyword)
            );
        }
        
        queryWrapper.orderByDesc("create_time");
        return list(queryWrapper);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void applyJoinChannel(Long channelId, Long userId) {
        Channel channel = getById(channelId);
        if (channel == null || channel.getStatus() != 1) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "频道不存在或已禁用");
        }

        QueryWrapper<ChannelMember> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("channel_id", channelId)
                .eq("user_id", userId);
        ChannelMember existing = channelMemberMapper.selectOne(queryWrapper);
        
        if (existing != null) {
            if (existing.getStatus() == 1) {
                throw new BusinessException(ErrorCode.BAD_REQUEST, "您已经是该频道成员");
            } else if (existing.getStatus() == 0) {
                throw new BusinessException(ErrorCode.BAD_REQUEST, "您的加入申请正在审核中");
            }
        }

        ChannelMember member = new ChannelMember();
        member.setChannelId(channelId);
        member.setUserId(userId);
        member.setRole("member");
        member.setStatus(channel.getType() == 1 ? 1 : 0);
        member.setApplyTime(LocalDateTime.now());
        
        if (channel.getType() == 1) {
            member.setApproveTime(LocalDateTime.now());
            member.setApproveUserId(userId);
        }
        
        channelMemberMapper.insert(member);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void approveJoinApplication(Long applicationId, Long approveUserId, boolean approved) {
        ChannelMember application = channelMemberMapper.selectById(applicationId);
        if (application == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "申请记录不存在");
        }
        
        if (application.getStatus() != 0) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "该申请已处理");
        }

        QueryWrapper<ChannelMember> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("channel_id", application.getChannelId())
                .eq("user_id", approveUserId)
                .in("role", "owner", "admin");
        ChannelMember approver = channelMemberMapper.selectOne(queryWrapper);
        
        if (approver == null) {
            throw new BusinessException(ErrorCode.FORBIDDEN, "您没有权限审核此申请");
        }

        application.setStatus(approved ? 1 : 2);
        application.setApproveTime(LocalDateTime.now());
        application.setApproveUserId(approveUserId);
        channelMemberMapper.updateById(application);

        if (approved) {
            notificationService.sendNotification(application.getUserId(), "channel_approved",
                    "频道加入审核通过", "你申请加入的频道已通过审核",
                    application.getChannelId().toString());
        } else {
            notificationService.sendNotification(application.getUserId(), "channel_rejected",
                    "频道加入审核未通过", "你申请加入的频道已被拒绝",
                    application.getChannelId().toString());
        }
    }

    @Override
    public List<Channel> getUserChannels(Long userId) {
        QueryWrapper<ChannelMember> memberQuery = new QueryWrapper<>();
        memberQuery.eq("user_id", userId)
                .eq("status", 1);
        List<ChannelMember> members = channelMemberMapper.selectList(memberQuery);
        
        if (members.isEmpty()) {
            return List.of();
        }
        
        List<Long> channelIds = members.stream()
                .map(ChannelMember::getChannelId)
                .toList();
        
        return listByIds(channelIds);
    }

    @Override
    public List<ChannelMember> getPendingApplications(Long channelId) {
        QueryWrapper<ChannelMember> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("channel_id", channelId)
                .eq("status", 0)
                .orderByAsc("apply_time");
        return channelMemberMapper.selectList(queryWrapper);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void leaveChannel(Long channelId, Long userId) {
        Channel channel = getById(channelId);
        if (channel == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "频道不存在");
        }

        QueryWrapper<ChannelMember> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("channel_id", channelId)
                .eq("user_id", userId);
        ChannelMember member = channelMemberMapper.selectOne(queryWrapper);

        if (member == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "您不是该频道成员");
        }

        if ("owner".equals(member.getRole())) {
            throw new BusinessException(ErrorCode.FORBIDDEN, "频道创建者不能退出频道，请先转让管理员权限");
        }

        channelMemberMapper.deleteById(member.getId());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateChannel(Long channelId, String name, String description, Long userId) {
        Channel channel = getById(channelId);
        if (channel == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "频道不存在");
        }

        QueryWrapper<ChannelMember> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("channel_id", channelId)
                .eq("user_id", userId)
                .in("role", "owner", "admin");
        ChannelMember member = channelMemberMapper.selectOne(queryWrapper);

        if (member == null) {
            throw new BusinessException(ErrorCode.FORBIDDEN, "您没有权限编辑此频道");
        }

        if (name != null) {
            channel.setName(name);
        }
        if (description != null) {
            channel.setDescription(description);
        }
        updateById(channel);
    }

    @Override
    public List<ChannelMember> getChannelMembers(Long channelId) {
        QueryWrapper<ChannelMember> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("channel_id", channelId)
                .eq("status", 1);
        List<ChannelMember> members = channelMemberMapper.selectList(queryWrapper);

        List<Long> userIds = members.stream()
                .map(ChannelMember::getUserId)
                .distinct()
                .collect(Collectors.toList());

        if (!userIds.isEmpty()) {
            List<com.gdmec.campchannel.entity.User> users = userMapper.selectBatchIds(userIds);
            Map<Long, com.gdmec.campchannel.entity.User> userMap = users.stream()
                    .collect(Collectors.toMap(com.gdmec.campchannel.entity.User::getId, u -> u, (a, b) -> a));

            for (ChannelMember member : members) {
                com.gdmec.campchannel.entity.User u = userMap.get(member.getUserId());
                if (u != null) {
                    member.setUsername(u.getUsername());
                    member.setAvatar(u.getAvatar());
                }
            }
        }

        return members;
    }

    @Override
    public int getPendingApplicationCount(Long userId) {
        QueryWrapper<ChannelMember> ownerQuery = new QueryWrapper<>();
        ownerQuery.eq("user_id", userId)
                .in("role", "owner", "admin")
                .eq("status", 1);
        List<ChannelMember> myMemberships = channelMemberMapper.selectList(ownerQuery);

        if (myMemberships.isEmpty()) return 0;

        List<Long> myChannelIds = myMemberships.stream()
                .map(ChannelMember::getChannelId)
                .collect(Collectors.toList());

        QueryWrapper<ChannelMember> pendingQuery = new QueryWrapper<>();
        pendingQuery.in("channel_id", myChannelIds)
                .eq("status", 0);

        return channelMemberMapper.selectCount(pendingQuery).intValue();
    }

    @Override
    public List<ChannelMember> getPendingApplicationsForOwner(Long userId) {
        QueryWrapper<ChannelMember> ownerQuery = new QueryWrapper<>();
        ownerQuery.eq("user_id", userId)
                .in("role", "owner", "admin")
                .eq("status", 1);
        List<ChannelMember> myMemberships = channelMemberMapper.selectList(ownerQuery);

        if (myMemberships.isEmpty()) return List.of();

        List<Long> myChannelIds = myMemberships.stream()
                .map(ChannelMember::getChannelId)
                .collect(Collectors.toList());

        QueryWrapper<ChannelMember> pendingQuery = new QueryWrapper<>();
        pendingQuery.in("channel_id", myChannelIds)
                .eq("status", 0)
                .orderByAsc("apply_time");

        List<ChannelMember> pendingApps = channelMemberMapper.selectList(pendingQuery);

        Map<Long, String> channelNames = listByIds(myChannelIds).stream()
                .collect(Collectors.toMap(Channel::getId, Channel::getName, (a, b) -> a));

        for (ChannelMember app : pendingApps) {
            String channelName = channelNames.get(app.getChannelId());
            if (channelName != null) {
                app.setChannelName(channelName);
            }
        }

        return pendingApps;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void removeMember(Long channelId, Long targetUserId, Long operatorId) {
        Channel channel = getById(channelId);
        if (channel == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "频道不存在");
        }

        QueryWrapper<ChannelMember> operatorQuery = new QueryWrapper<>();
        operatorQuery.eq("channel_id", channelId)
                .eq("user_id", operatorId)
                .in("role", "owner", "admin");
        ChannelMember operator = channelMemberMapper.selectOne(operatorQuery);
        if (operator == null) {
            throw new BusinessException(ErrorCode.FORBIDDEN, "您没有权限管理频道成员");
        }

        QueryWrapper<ChannelMember> targetQuery = new QueryWrapper<>();
        targetQuery.eq("channel_id", channelId)
                .eq("user_id", targetUserId);
        ChannelMember target = channelMemberMapper.selectOne(targetQuery);
        if (target == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "该用户不是频道成员");
        }

        if ("owner".equals(target.getRole())) {
            throw new BusinessException(ErrorCode.FORBIDDEN, "无法移除频道创建者");
        }

        channelMemberMapper.deleteById(target.getId());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void setMemberRole(Long channelId, Long targetUserId, Long operatorId, String role) {
        Channel channel = getById(channelId);
        if (channel == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "频道不存在");
        }

        QueryWrapper<ChannelMember> operatorQuery = new QueryWrapper<>();
        operatorQuery.eq("channel_id", channelId)
                .eq("user_id", operatorId)
                .in("role", "owner");
        ChannelMember operator = channelMemberMapper.selectOne(operatorQuery);
        if (operator == null) {
            throw new BusinessException(ErrorCode.FORBIDDEN, "只有频道创建者可以设置管理员");
        }

        QueryWrapper<ChannelMember> targetQuery = new QueryWrapper<>();
        targetQuery.eq("channel_id", channelId)
                .eq("user_id", targetUserId);
        ChannelMember target = channelMemberMapper.selectOne(targetQuery);
        if (target == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "该用户不是频道成员");
        }

        if ("owner".equals(target.getRole())) {
            throw new BusinessException(ErrorCode.FORBIDDEN, "无法修改创建者角色");
        }

        target.setRole(role);
        channelMemberMapper.updateById(target);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void muteMember(Long channelId, Long targetUserId, Long operatorId, boolean muted) {
        Channel channel = getById(channelId);
        if (channel == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "频道不存在");
        }

        // Check if operator is owner or admin
        QueryWrapper<ChannelMember> operatorQuery = new QueryWrapper<>();
        operatorQuery.eq("channel_id", channelId)
                .eq("user_id", operatorId)
                .in("role", "owner", "admin");
        ChannelMember operator = channelMemberMapper.selectOne(operatorQuery);
        if (operator == null) {
            throw new BusinessException(ErrorCode.FORBIDDEN, "只有频道主或管理员可以禁言成员");
        }

        QueryWrapper<ChannelMember> targetQuery = new QueryWrapper<>();
        targetQuery.eq("channel_id", channelId)
                .eq("user_id", targetUserId);
        ChannelMember target = channelMemberMapper.selectOne(targetQuery);
        if (target == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "该用户不是频道成员");
        }

        if ("owner".equals(target.getRole())) {
            throw new BusinessException(ErrorCode.FORBIDDEN, "无法禁言频道创建者");
        }

        target.setIsMuted(muted ? 1 : 0);
        channelMemberMapper.updateById(target);
    }

    private String generateChannelCode() {
        String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        Random random = new Random();
        StringBuilder code = new StringBuilder("CH-");
        
        for (int i = 0; i < 4; i++) {
            code.append(chars.charAt(random.nextInt(chars.length())));
        }
        code.append("-");
        for (int i = 0; i < 3; i++) {
            code.append(chars.charAt(random.nextInt(chars.length())));
        }
        
        QueryWrapper<Channel> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("channel_code", code.toString());
        if (count(queryWrapper) > 0) {
            return generateChannelCode();
        }
        
        return code.toString();
    }
}