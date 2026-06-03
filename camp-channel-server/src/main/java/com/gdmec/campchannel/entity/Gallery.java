package com.gdmec.campchannel.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("gallery")
public class Gallery {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long userId;

    private String imageUrl;

    /**
     * 媒体类型: 1-图片, 2-视频
     */
    private Integer mediaType;

    private String videoUrl;

    private String title;

    private String description;

    private Long channelId;

    private Integer status;

    private LocalDateTime createTime;

    @TableField(exist = false)
    private String username;

    @TableField(exist = false)
    private String avatar;
}
