package com.gdmec.campchannel.config;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.gdmec.campchannel.entity.Channel;
import com.gdmec.campchannel.entity.ChannelMember;
import com.gdmec.campchannel.entity.User;
import com.gdmec.campchannel.mapper.ChannelMemberMapper;
import com.gdmec.campchannel.service.ChannelService;
import com.gdmec.campchannel.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

@Component
public class DataInitializer implements CommandLineRunner {

    @Autowired
    private UserService userService;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private ChannelService channelService;

    @Autowired
    private ChannelMemberMapper channelMemberMapper;

    @Override
    public void run(String... args) {
        // 确保默认头像目录存在
        try {
            java.io.File avatarsDir = new java.io.File("uploads/avatars");
            if (!avatarsDir.exists()) {
                avatarsDir.mkdirs();
            }
        } catch (Exception e) {}

        Channel publicChannel = null;
        try {
            publicChannel = channelService.getOne(
                new QueryWrapper<Channel>().eq("channel_code", "CH-PUBLIC-001")
            );
        } catch (Exception e) {}

        if (publicChannel == null) {
            publicChannel = new Channel();
            publicChannel.setChannelCode("CH-PUBLIC-001");
            publicChannel.setName("公共频道");
            publicChannel.setDescription("所有注册用户自动加入的默认频道");
            publicChannel.setType(1);
            publicChannel.setStatus(1);
            publicChannel.setCreatorId(0L);
            channelService.save(publicChannel);
            System.out.println("===== 公共频道已创建 ===== 频道编号: CH-PUBLIC-001");
        }

        if (userService.getUserByUsername("admin") == null) {
            User admin = new User();
            admin.setEmail("admin@stu.gdmec.edu.cn");
            admin.setUsername("admin");
            admin.setPassword(passwordEncoder.encode("admin123"));
            admin.setRole("sys_admin");
            admin.setStatus(1);
            userService.save(admin);
            System.out.println("===== 默认管理员账号已创建 =====");
            System.out.println("  用户名: admin");
            System.out.println("  密码:   admin123");
            System.out.println("  邮箱:   admin@stu.gdmec.edu.cn");
            System.out.println("  角色:   sys_admin");
            System.out.println("================================");
            addToPublicChannel(publicChannel.getId(), admin.getId());
        }

        if (userService.getUserByUsername("testuser") == null) {
            User testUser = new User();
            testUser.setEmail("test@stu.gdmec.edu.cn");
            testUser.setUsername("testuser");
            testUser.setPassword(passwordEncoder.encode("test1234"));
            testUser.setRole("user");
            testUser.setStatus(1);
            userService.save(testUser);
            System.out.println("===== 默认测试用户已创建 =====");
            System.out.println("  用户名: testuser");
            System.out.println("  密码:   test1234");
            System.out.println("================================");
            addToPublicChannel(publicChannel.getId(), testUser.getId());
        }
    }

    private void addToPublicChannel(Long channelId, Long userId) {
        ChannelMember member = new ChannelMember();
        member.setChannelId(channelId);
        member.setUserId(userId);
        member.setRole("member");
        member.setStatus(1);
        member.setApplyTime(LocalDateTime.now());
        member.setApproveTime(LocalDateTime.now());
        channelMemberMapper.insert(member);
    }
}
