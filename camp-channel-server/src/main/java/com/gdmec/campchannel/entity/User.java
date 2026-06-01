package com.gdmec.campchannel.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("`user`")
public class User {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String username;

    private String realName;

    private String phone;

    private String email;

    private String password;

    private String role;

    private Integer status;

    private String avatar;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;

    private Integer emailNotify;

    public boolean isEmailNotifyEnabled() {
        return emailNotify == null || emailNotify == 1;
    }
}