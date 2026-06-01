package com.gdmec.campchannel.security;

import lombok.AllArgsConstructor;
import lombok.Data;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.Collections;

/**
 * Spring Security 用户认证主体包装类
 */
@Data
@AllArgsConstructor
public class SecurityUser implements UserDetails {

    private Long id;
    private String username; // 实为系统唯一账号用户名，或邮箱
    private String email;
    private String password;
    private String role; // 角色，例如 student, channel_admin, sys_admin
    private Integer status; // 状态：1 = 正常, 0 = 禁用, 2 = 待审核
    private String avatar;

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        if (role == null) {
            return Collections.emptyList();
        }
        // Spring Security 角色默认需以 ROLE_ 开头
        return Collections.singletonList(new SimpleGrantedAuthority("ROLE_" + role.toUpperCase()));
    }

    @Override
    public String getPassword() {
        return password;
    }

    @Override
    public String getUsername() {
        return username;
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return status != null && status != 0; // 如果是禁用状态，则表示锁定
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return status != null && status == 1; // 仅状态为 1 (正常) 时启用
    }
}
