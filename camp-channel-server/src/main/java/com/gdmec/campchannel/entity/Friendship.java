package com.gdmec.campchannel.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("friendship")
public class Friendship {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long userId;

    private Long friendId;

    private Integer status;

    private LocalDateTime applyTime;

    private LocalDateTime approveTime;
}