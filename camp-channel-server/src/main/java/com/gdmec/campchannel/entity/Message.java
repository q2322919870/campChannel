package com.gdmec.campchannel.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("message")
public class Message {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long senderId;

    private Long receiverId;

    private String content;

    private Integer type;

    /**
     * 消息状态: 0=发送中, 1=已发送, 2=已送达, 3=已读, 5=已撤回
     */
    private Integer status;

    /**
     * 已读状态 (兼容旧字段): 0=未读, 1=已读
     */
    private Integer isRead;

    private LocalDateTime readTime;

    /**
     * 已读时间 (V2.0 统一字段)
     */
    private LocalDateTime readAt;

    private LocalDateTime createTime;

    @TableField(exist = false)
    private String username;

    @TableField(exist = false)
    private String avatar;
}
