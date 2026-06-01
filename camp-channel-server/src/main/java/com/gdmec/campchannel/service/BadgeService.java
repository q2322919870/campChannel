package com.gdmec.campchannel.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.gdmec.campchannel.entity.UserBadge;

import java.util.List;

public interface BadgeService extends IService<UserBadge> {

    /** Get all badges with earned status for a user */
    List<UserBadge> getMyBadges(Long userId);

    /** Check and award badges based on user's like count */
    void checkAndAwardBadges(Long userId);
}
