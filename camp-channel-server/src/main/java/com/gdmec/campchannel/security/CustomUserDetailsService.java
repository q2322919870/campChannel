package com.gdmec.campchannel.security;

import com.gdmec.campchannel.entity.User;
import com.gdmec.campchannel.service.UserService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

/**
 * 自定义 Spring Security 用户信息加载服务
 */
@Slf4j
@Service
public class CustomUserDetailsService implements UserDetailsService {

    @Autowired
    private UserService userService;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        log.info("Spring Security 正在加载用户: {}", username);

        // 优先按邮箱查询，如果没找到则按用户名查询
        User user = userService.getUserByEmail(username);
        if (user == null) {
            user = userService.getUserByUsername(username);
        }

        if (user != null) {
            return new SecurityUser(
                    user.getId(),
                    user.getUsername(),
                    user.getEmail(),
                    user.getPassword(),
                    user.getRole(),
                    user.getStatus(),
                    user.getAvatar()
            );
        }

        throw new UsernameNotFoundException("用户不存在: " + username);
    }
}
