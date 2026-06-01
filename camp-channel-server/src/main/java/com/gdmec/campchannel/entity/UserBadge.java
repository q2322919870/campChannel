package com.gdmec.campchannel.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("user_badge")
public class UserBadge {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long userId;

    private Long badgeId;

    private LocalDateTime earnedAt;

    @TableField(exist = false)
    private String badgeName;

    @TableField(exist = false)
    private String badgeIcon;

    @TableField(exist = false)
    private String badgeDescription;
}
