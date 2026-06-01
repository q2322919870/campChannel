package com.gdmec.campchannel.service.impl;

import com.gdmec.campchannel.entity.User;
import com.gdmec.campchannel.mapper.UserMapper;
import com.gdmec.campchannel.service.EmailService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Slf4j
@Service
public class EmailServiceImpl implements EmailService {

    @Autowired(required = false)
    private JavaMailSender mailSender;

    @Value("${spring.mail.username:}")
    private String from;

    @Autowired
    private UserMapper userMapper;

    @Override
    public void sendEmail(String to, String subject, String content) {
        if (mailSender == null || from.isEmpty()) {
            log.warn("Mail not configured, skipping email to " + to + ": " + subject);
            return;
        }
        try {
            SimpleMailMessage msg = new SimpleMailMessage();
            msg.setFrom(from);
            msg.setTo(to);
            msg.setSubject(subject);
            msg.setText(content);
            mailSender.send(msg);
            log.info("Email sent to " + to + ": " + subject);
        } catch (Exception e) {
            log.error("Failed to send email to " + to + ": " + e.getMessage());
        }
    }

    @Override
    public void sendVerificationCode(String email, String code) {
        String subject = "Camp Channel - 注册验证码";
        String content = "您的注册验证码是: " + code + "\n\n验证码5分钟内有效，请勿泄露给他人。\n\nCamp Channel 校园社区";
        sendEmail(email, subject, content);
    }

    @Override
    public void sendEmailAlert(Long userId, String subject, String content) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            log.warn("User {} not found, cannot send email alert", userId);
            return;
        }
        if (!user.isEmailNotifyEnabled()) {
            log.debug("User {} has email notifications disabled, skipping", userId);
            return;
        }
        if (user.getEmail() == null || user.getEmail().isEmpty()) {
            log.warn("User {} has no email configured, skipping alert", userId);
            return;
        }
        sendEmail(user.getEmail(), "Camp Channel - " + subject, content);
    }
}
