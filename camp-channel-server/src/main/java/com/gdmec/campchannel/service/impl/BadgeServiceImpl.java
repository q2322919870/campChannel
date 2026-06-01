package com.gdmec.campchannel.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.gdmec.campchannel.entity.Badge;
import com.gdmec.campchannel.entity.Post;
import com.gdmec.campchannel.entity.UserBadge;
import com.gdmec.campchannel.mapper.BadgeMapper;
import com.gdmec.campchannel.mapper.PostMapper;
import com.gdmec.campchannel.mapper.UserBadgeMapper;
import com.gdmec.campchannel.service.BadgeService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Slf4j
@Service
public class BadgeServiceImpl extends ServiceImpl<UserBadgeMapper, UserBadge> implements BadgeService {

    @Autowired
    private BadgeMapper badgeMapper;

    @Autowired
    private PostMapper postMapper;

    @Override
    public List<UserBadge> getMyBadges(Long userId) {
        List<UserBadge> earned = list(
                new QueryWrapper<UserBadge>()
                        .eq("user_id", userId)
                        .orderByDesc("earned_at"));

        // Attach badge details
        List<Badge> allBadges = badgeMapper.selectList(null);
        for (UserBadge ub : earned) {
            allBadges.stream()
                    .filter(b -> b.getId().equals(ub.getBadgeId()))
                    .findFirst()
                    .ifPresent(b -> {
                        ub.setBadgeName(b.getName());
                        ub.setBadgeIcon(b.getIcon());
                        ub.setBadgeDescription(b.getDescription());
                    });
        }
        return earned;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void checkAndAwardBadges(Long userId) {
        try {
            // Calculate total likes received by this user
            List<Post> userPosts = postMapper.selectList(
                    new QueryWrapper<Post>().eq("user_id", userId).eq("status", 1));
            int totalLikes = userPosts.stream()
                    .mapToInt(p -> p.getLikeCount() != null ? p.getLikeCount() : 0)
                    .sum();
            int postCount = userPosts.size();

            // Get all badges
            List<Badge> allBadges = badgeMapper.selectList(null);

            // Get already earned badges
            Set<Long> earnedBadgeIds = list(
                    new QueryWrapper<UserBadge>().eq("user_id", userId))
                    .stream().map(UserBadge::getBadgeId).collect(Collectors.toSet());

            for (Badge badge : allBadges) {
                if (earnedBadgeIds.contains(badge.getId())) continue;

                boolean shouldAward = false;
                if ("like_count".equals(badge.getConditionType()) && totalLikes >= badge.getConditionValue()) {
                    shouldAward = true;
                } else if ("post_count".equals(badge.getConditionType()) && postCount >= badge.getConditionValue()) {
                    shouldAward = true;
                }

                if (shouldAward) {
                    UserBadge ub = new UserBadge();
                    ub.setUserId(userId);
                    ub.setBadgeId(badge.getId());
                    ub.setEarnedAt(LocalDateTime.now());
                    save(ub);
                    log.info("User {} earned badge: {}", userId, badge.getName());
                }
            }
        } catch (Exception e) {
            log.warn("Badge check failed for user {}: {}", userId, e.getMessage());
        }
    }
}
