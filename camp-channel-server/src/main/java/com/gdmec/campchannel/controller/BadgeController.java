package com.gdmec.campchannel.controller;

import com.gdmec.campchannel.common.api.Result;
import com.gdmec.campchannel.entity.Badge;
import com.gdmec.campchannel.entity.UserBadge;
import com.gdmec.campchannel.mapper.BadgeMapper;
import com.gdmec.campchannel.security.SecurityUser;
import com.gdmec.campchannel.service.BadgeService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "徽章模块", description = "提供徽章查看和自动授予功能")
@Slf4j
@RestController
@RequestMapping("/badges")
public class BadgeController {

    @Autowired
    private BadgeService badgeService;

    @Autowired
    private BadgeMapper badgeMapper;

    @GetMapping
    @Operation(summary = "获取所有徽章定义")
    public Result<List<Badge>> getAllBadges() {
        return Result.success(badgeMapper.selectList(null));
    }

    @GetMapping("/my")
    @Operation(summary = "获取我已获得的徽章")
    public Result<List<UserBadge>> getMyBadges(@AuthenticationPrincipal SecurityUser currentUser) {
        return Result.success(badgeService.getMyBadges(currentUser.getId()));
    }
}
