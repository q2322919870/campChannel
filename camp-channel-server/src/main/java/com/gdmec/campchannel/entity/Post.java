package com.gdmec.campchannel.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("post")
public class Post {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long channelId;

    private Long userId;

    private String content;

    private String images;

    private String videoUrl;

    private String topic;

    private String mentionedUsers;

    private Boolean isAnonymous;
    
    // 非数据库字段，用于标记当前用户是否已解开
    @com.baomidou.mybatisplus.annotation.TableField(exist = false)
    private Boolean isRevealed;

    private Integer status;

    private Integer viewCount;

    private Integer likeCount;

    private Integer commentCount;

    /**
     * 是否置顶: 0-否, 1-是
     */
    private Integer isPinned;

    private Integer editCount;

    private LocalDateTime lastEditTime;

    private LocalDateTime createTime;

    private LocalDateTime expireTime;

    private LocalDateTime updateTime;

    @TableField(exist = false)
    private String username;

    @TableField(exist = false)
    private String avatar;

    @TableField(exist = false)
    private Boolean isLiked;

    @TableField(exist = false)
    private String userChannelRole;

    @TableField(exist = false)
    private String channelName;

    @TableField(exist = false)
    private Boolean isOwner;
}