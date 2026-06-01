package com.gdmec.campchannel.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("group_message")
public class GroupMessage {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long channelId;

    private Long senderId;

    private String content;

    private String mediaUrl;

    private Integer msgType;

    private Integer status;

    private LocalDateTime createTime;

    @TableField(exist = false)
    private String username;

    @TableField(exist = false)
    private String avatar;
}
