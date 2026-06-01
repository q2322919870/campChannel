package com.gdmec.campchannel.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.gdmec.campchannel.common.api.ErrorCode;
import com.gdmec.campchannel.common.exception.BusinessException;
import com.gdmec.campchannel.entity.Channel;
import com.gdmec.campchannel.entity.ChannelMember;
import com.gdmec.campchannel.entity.User;
import com.gdmec.campchannel.mapper.ChannelMapper;
import com.gdmec.campchannel.mapper.ChannelMemberMapper;
import com.gdmec.campchannel.mapper.UserMapper;
import com.gdmec.campchannel.service.UserService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.File;
import java.time.LocalDateTime;

@Slf4j
@Service
public class UserServiceImpl extends ServiceImpl<UserMapper, User> implements UserService {

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private ChannelMemberMapper channelMemberMapper;

    @Autowired
    private ChannelMapper channelMapper;

    @Override
    public User getUserByEmail(String email) {
        return getOne(new QueryWrapper<User>().eq("email", email));
    }

    @Override
    public User getUserByUsername(String username) {
        return getOne(new QueryWrapper<User>().eq("username", username));
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public User register(String email, String username, String password, String realName, String phone) {
        if (!email.endsWith("@stu.gdmec.edu.cn")) {
            throw new BusinessException(ErrorCode.INVALID_EMAIL_SUFFIX);
        }

        if (getUserByEmail(email) != null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "该邮箱已被注册");
        }
        if (getUserByUsername(username) != null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "该用户名已被使用");
        }

        User user = new User();
        user.setEmail(email);
        user.setUsername(username);
        user.setPassword(passwordEncoder.encode(password));
        user.setRealName(realName);
        user.setPhone(phone);
        user.setRole("user");
        user.setStatus(1);

        // 随机分配默认头像
        try {
            File avatarsDir = new File("uploads/avatars");
            if (avatarsDir.exists() && avatarsDir.isDirectory()) {
                File[] files = avatarsDir.listFiles((dir, name) -> 
                    name.endsWith(".svg") || name.endsWith(".jpg") || name.endsWith(".png"));
                if (files != null && files.length > 0) {
                    File f = files[new java.util.Random().nextInt(files.length)];
                    user.setAvatar("/uploads/avatars/" + f.getName());
                }
            }
        } catch (Exception e) {
            log.warn("分配默认头像失败", e);
        }

        save(user);

        try {
            Channel publicChannel = channelMapper.selectOne(
                new QueryWrapper<Channel>().eq("channel_code", "CH-PUBLIC-001")
            );
            if (publicChannel != null) {
                ChannelMember cm = new ChannelMember();
                cm.setChannelId(publicChannel.getId());
                cm.setUserId(user.getId());
                cm.setRole("member");
                cm.setStatus(1);
                cm.setApplyTime(LocalDateTime.now());
                cm.setApproveTime(LocalDateTime.now());
                channelMemberMapper.insert(cm);
            }
        } catch (Exception e) {
            log.warn("自动加入公共频道失败", e);
        }

        return user;
    }
}
