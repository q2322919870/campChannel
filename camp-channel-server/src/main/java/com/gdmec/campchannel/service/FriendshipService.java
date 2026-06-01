package com.gdmec.campchannel.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.gdmec.campchannel.entity.Friendship;
import com.gdmec.campchannel.entity.User;

import java.util.List;

public interface FriendshipService extends IService<Friendship> {

    /**
     * 发送好友申请（含每日限流）
     */
    void sendFriendRequest(Long userId, Long friendId);

    /**
     * 同意好友申请
     */
    void approveFriendRequest(Long requestId, Long userId);

    /**
     * 拒绝好友申请
     */
    void rejectFriendRequest(Long requestId, Long userId);

    /**
     * 获取待处理的好友申请列表
     */
    List<Friendship> getPendingRequests(Long userId);

    /**
     * 获取好友列表
     */
    List<User> getFriends(Long userId);

    /**
     * 搜索用户（按邮箱或用户名）
     */
    List<User> searchUsers(String keyword);

    /**
     * 删除好友
     */
    void deleteFriend(Long userId, Long friendId);

    /**
     * 屏蔽好友动态
     */
    void blockFriend(Long userId, Long friendId);

    /**
     * 取消屏蔽好友
     */
    void unblockFriend(Long userId, Long friendId);
}