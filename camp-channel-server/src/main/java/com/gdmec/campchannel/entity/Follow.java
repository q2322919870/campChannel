package com.gdmec.campchannel.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("follow")
public class Follow {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long followerId;

    private Long followingId;

    private LocalDateTime createTime;

    /** 被关注者的用户名（非数据库字段） */
    @TableField(exist = false)
    private String username;

    /** 被关注者的头像（非数据库字段） */
    @TableField(exist = false)
    private String avatar;

    /** 关注者的用户名（非数据库字段） */
    @TableField(exist = false)
    private String followerUsername;

    /** 关注者的头像（非数据库字段） */
    @TableField(exist = false)
    private String followerAvatar;
}
