package com.gdmec.campchannel.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("announcement")
public class Announcement {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String title;

    private String content;

    /** Type: scratch (scratch card), blindbox (blind box) */
    private String type;

    private String coverImage;

    private Long createdBy;

    private Long channelId;

    /** Status: 0=pending, 1=active, 2=expired */
    private Integer status;

    private LocalDateTime createdAt;
}
