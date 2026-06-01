package com.gdmec.campchannel.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.gdmec.campchannel.common.api.ErrorCode;
import com.gdmec.campchannel.common.exception.BusinessException;
import com.gdmec.campchannel.common.utils.RedisUtils;
import com.gdmec.campchannel.entity.Friendship;
import com.gdmec.campchannel.entity.User;
import com.gdmec.campchannel.mapper.FriendshipMapper;
import com.gdmec.campchannel.mapper.UserMapper;
import com.gdmec.campchannel.service.EmailService;
import com.gdmec.campchannel.service.FriendshipService;
import com.gdmec.campchannel.service.NotificationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Service
public class FriendshipServiceImpl extends ServiceImpl<FriendshipMapper, Friendship> implements FriendshipService {

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private RedisUtils redisUtils;

    @Autowired
    private NotificationService notificationService;

    @Autowired
    private EmailService emailService;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void sendFriendRequest(Long userId, Long friendId) {
        if (userId.equals(friendId)) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "不能添加自己为好友");
        }

        String dailyLimitKey = "friend_request_daily:" + userId + ":" + LocalDate.now();
        Long count = redisUtils.incr(dailyLimitKey);
        if (count == 1) {
            redisUtils.expire(dailyLimitKey, 86400);
        }
        if (count > 20) {
            throw new BusinessException(ErrorCode.TOO_MANY_REQUESTS, "每日好友申请次数已达上限（20次）");
        }

        QueryWrapper<Friendship> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("user_id", userId)
                .eq("friend_id", friendId);
        Friendship existing = getOne(queryWrapper);
        
        if (existing != null) {
            if (existing.getStatus() == 0) {
                throw new BusinessException(ErrorCode.BAD_REQUEST, "已发送好友申请，等待对方处理");
            } else if (existing.getStatus() == 1) {
                throw new BusinessException(ErrorCode.BAD_REQUEST, "你们已经是好友");
            }
        }

        Friendship friendship = new Friendship();
        friendship.setUserId(userId);
        friendship.setFriendId(friendId);
        friendship.setStatus(0);
        friendship.setApplyTime(LocalDateTime.now());
        save(friendship);

        User sender = userMapper.selectById(userId);
        String senderName = sender != null ? sender.getUsername() : "未知用户";
        notificationService.sendNotification(friendId, "friend_request",
                "好友申请", "用户 " + senderName + " 申请添加你为好友",
                userId.toString());
        
        // Send email alert
        try {
            String emailContent = senderName + " 申请添加你为好友\n\n快去处理好友申请吧！";
            emailService.sendEmailAlert(friendId,
                    "好友申请 - " + senderName,
                    emailContent);
        } catch (Exception e) {
            log.warn("Failed to send friend request email alert: " + e.getMessage());
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void approveFriendRequest(Long requestId, Long userId) {
        Friendship request = getById(requestId);
        if (request == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "申请记录不存在");
        }
        
        if (!request.getFriendId().equals(userId)) {
            throw new BusinessException(ErrorCode.FORBIDDEN, "您无权处理此申请");
        }
        
        if (request.getStatus() != 0) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "该申请已处理");
        }

        request.setStatus(1);
        request.setApproveTime(LocalDateTime.now());
        updateById(request);

        User approver = userMapper.selectById(userId);
        String approverName = approver != null ? approver.getUsername() : "未知用户";
        notificationService.sendNotification(request.getUserId(), "friend_approved",
                "好友申请通过", "用户 " + approverName + " 已同意你的好友申请",
                userId.toString());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void rejectFriendRequest(Long requestId, Long userId) {
        Friendship request = getById(requestId);
        if (request == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "申请记录不存在");
        }
        
        if (!request.getFriendId().equals(userId)) {
            throw new BusinessException(ErrorCode.FORBIDDEN, "您无权处理此申请");
        }
        
        if (request.getStatus() != 0) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "该申请已处理");
        }

        request.setStatus(2);
        request.setApproveTime(LocalDateTime.now());
        updateById(request);
    }

    @Override
    public List<Friendship> getPendingRequests(Long userId) {
        QueryWrapper<Friendship> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("friend_id", userId)
                .eq("status", 0)
                .orderByDesc("apply_time");
        return list(queryWrapper);
    }

    @Override
    public List<User> getFriends(Long userId) {
        QueryWrapper<Friendship> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("status", 1)
                .and(wrapper -> wrapper
                        .eq("user_id", userId)
                        .or()
                        .eq("friend_id", userId)
                );
        
        List<Friendship> friendships = list(queryWrapper);
        
        List<Long> friendIds = new ArrayList<>();
        for (Friendship f : friendships) {
            if (f.getUserId().equals(userId)) {
                friendIds.add(f.getFriendId());
            } else {
                friendIds.add(f.getUserId());
            }
        }
        
        if (friendIds.isEmpty()) {
            return List.of();
        }
        
        return userMapper.selectBatchIds(friendIds);
    }

    @Override
    public List<User> searchUsers(String keyword) {
        if (!StringUtils.hasText(keyword)) {
            return List.of();
        }
        
        QueryWrapper<User> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("status", 1)
                .and(wrapper -> wrapper
                        .like("email", keyword)
                        .or()
                        .like("username", keyword)
                )
                .last("LIMIT 20");
        
        return userMapper.selectList(queryWrapper);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteFriend(Long userId, Long friendId) {
        QueryWrapper<Friendship> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("status", 1)
                .and(wrapper -> wrapper
                        .and(w -> w.eq("user_id", userId).eq("friend_id", friendId))
                        .or(w -> w.eq("user_id", friendId).eq("friend_id", userId))
                );
        Friendship friendship = getOne(queryWrapper);
        if (friendship == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "你们不是好友关系");
        }
        removeById(friendship.getId());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void blockFriend(Long userId, Long friendId) {
        // Check if they are friends
        QueryWrapper<Friendship> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("status", 1)
                .and(wrapper -> wrapper
                        .and(w -> w.eq("user_id", userId).eq("friend_id", friendId))
                        .or(w -> w.eq("user_id", friendId).eq("friend_id", userId))
                );
        Friendship friendship = getOne(queryWrapper);
        if (friendship == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "你们不是好友关系");
        }
        
        // Set status to blocked (3)
        friendship.setStatus(3);
        updateById(friendship);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void unblockFriend(Long userId, Long friendId) {
        // Find the blocked friendship
        QueryWrapper<Friendship> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("status", 3)
                .and(wrapper -> wrapper
                        .and(w -> w.eq("user_id", userId).eq("friend_id", friendId))
                        .or(w -> w.eq("user_id", friendId).eq("friend_id", userId))
                );
        Friendship friendship = getOne(queryWrapper);
        if (friendship == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "未找到屏蔽记录");
        }
        
        // Restore to accepted (1)
        friendship.setStatus(1);
        updateById(friendship);
    }
}