package com.gdmec.campchannel.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("channel_member")
public class ChannelMember {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long channelId;

    private Long userId;

    private String role;

    /**
     * 是否禁言: 0-否, 1-是
     */
    private Integer isMuted;

    private Integer status;

    private LocalDateTime applyTime;

    private LocalDateTime approveTime;

    private Long approveUserId;

    @TableField(exist = false)
    private String channelName;

    @TableField(exist = false)
    private String username;

    @TableField(exist = false)
    private String avatar;
}