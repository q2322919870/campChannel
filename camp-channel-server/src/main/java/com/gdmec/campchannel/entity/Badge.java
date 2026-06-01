package com.gdmec.campchannel.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

@Data
@TableName("badge")
public class Badge {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String name;

    private String icon;

    private String description;

    /** Condition type: like_count, post_count, comment_count */
    private String conditionType;

    /** Threshold value for the condition */
    private Integer conditionValue;
}
