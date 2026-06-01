package com.gdmec.campchannel.service;

public interface EmailService {
    void sendEmail(String to, String subject, String content);
    void sendVerificationCode(String email, String code);
    /**
     * Send email alert to a user, respecting their emailNotify preference
     */
    void sendEmailAlert(Long userId, String subject, String content);
}
