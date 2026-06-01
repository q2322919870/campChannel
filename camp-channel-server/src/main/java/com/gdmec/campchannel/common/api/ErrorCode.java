package com.gdmec.campchannel.common.api;

import lombok.Getter;

/**
 * 业务错误码枚举
 */
@Getter
public enum ErrorCode {
    SUCCESS(200, "操作成功"),
    BAD_REQUEST(400, "请求参数错误"),
    UNAUTHORIZED(401, "账号未登录或登录已过期"),
    FORBIDDEN(403, "无权限进行该操作"),
    NOT_FOUND(404, "请求资源不存在"),
    METHOD_NOT_ALLOWED(405, "请求方法不允许"),
    TOO_MANY_REQUESTS(429, "操作过于频繁，请稍后再试"),
    SYSTEM_ERROR(500, "系统内部繁忙，请稍候再试"),

    // 用户/认证模块业务错误码 (1000 - 1999)
    EMAIL_ALREADY_EXISTS(1001, "该邮箱已被注册"),
    USERNAME_ALREADY_EXISTS(1002, "该用户名已被占用"),
    PHONE_ALREADY_EXISTS(1003, "该手机号已被绑定"),
    INVALID_EMAIL_SUFFIX(1004, "邮箱后缀必须为 @stu.gdmec.edu.cn"),
    USER_NOT_FOUND(1005, "用户不存在"),
    PASSWORD_ERROR(1006, "密码错误"),
    USER_DISABLED(1007, "账号已被禁用，请联系管理员"),
    USER_LOCKED(1008, "密码输入错误次数过多，账号已锁定，请30分钟后再试"),
    DEVICE_FORCE_LOGOUT(1009, "您的账号已在其他设备登录，当前设备已被下线"),
    INVALID_OLD_PASSWORD(1010, "原密码不正确"),

    // 频道模块业务错误码 (2000 - 2999)
    CHANNEL_NOT_FOUND(2001, "频道不存在"),
    CHANNEL_CODE_EXISTS(2002, "频道编号已存在"),
    NOT_CHANNEL_MEMBER(2003, "您不是该频道成员"),
    CHANNEL_MEMBER_ALREADY(2004, "您已是该频道成员或申请审核中"),
    CHANNEL_CLOSED(2005, "该频道已关闭"),

    // 帖子与内容模块业务错误码 (3000 - 3999)
    POST_NOT_FOUND(3001, "帖子不存在"),
    COMMENT_NOT_FOUND(3002, "评论不存在"),
    CONTENT_SENSITIVE(3003, "内容包含敏感词，发布失败"),
    POST_LIMIT_EXCEEDED(3004, "发帖频率超限，1分钟内最多发布3条帖子"),
    COMMENT_LIMIT_EXCEEDED(3005, "评论频率超限，1分钟内最多评论10次"),
    LIKE_LIMIT_EXCEEDED(3006, "点赞频率超限，1分钟内最多点赞50次"),

    // 好友与即时通讯模块业务错误码 (4000 - 4999)
    FRIEND_SHIP_EXISTS(4001, "你们已经是好友或已发送申请"),
    NOT_FRIENDS(4002, "你们还不是好友"),
    MESSAGE_REVOKE_TIMEOUT(4003, "消息发送已超过2分钟，无法撤回"),
    MESSAGE_NOT_FOUND(4004, "消息不存在");

    private final int code;
    private final String message;

    ErrorCode(int code, String message) {
        this.code = code;
        this.message = message;
    }
}
