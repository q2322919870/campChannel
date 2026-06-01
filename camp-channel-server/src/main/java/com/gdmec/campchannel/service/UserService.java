package com.gdmec.campchannel.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.gdmec.campchannel.entity.User;

public interface UserService extends IService<User> {
    
    /**
     * 根据邮箱查询用户
     */
    User getUserByEmail(String email);

    /**
     * 根据用户名查询用户
     */
    User getUserByUsername(String username);

    /**
     * 注册用户
     */
    User register(String email, String username, String password, String realName, String phone);
}