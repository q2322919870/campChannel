package com.gdmec.campchannel.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("gallery_like")
public class GalleryLike {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long galleryId;
    private Long userId;
    private LocalDateTime createTime;
}
