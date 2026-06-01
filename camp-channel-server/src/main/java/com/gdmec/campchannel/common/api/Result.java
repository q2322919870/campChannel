package com.gdmec.campchannel.common.api;

import lombok.Data;

import java.io.Serializable;

/**
 * 统一接口响应包装体
 *
 * @param <T> 数据实体类型
 */
@Data
public class Result<T> implements Serializable {
    private static final long serialVersionUID = 1L;

    private int code;
    private String message;
    private T data;
    private long timestamp;

    public Result() {
        this.timestamp = System.currentTimeMillis();
    }

    public Result(int code, String message, T data) {
        this.code = code;
        this.message = message;
        this.data = data;
        this.timestamp = System.currentTimeMillis();
    }

    /**
     * 成功响应
     */
    public static <T> Result<T> success() {
        return new Result<>(ErrorCode.SUCCESS.getCode(), ErrorCode.SUCCESS.getMessage(), null);
    }

    /**
     * 成功响应（带数据）
     */
    public static <T> Result<T> success(T data) {
        return new Result<>(ErrorCode.SUCCESS.getCode(), ErrorCode.SUCCESS.getMessage(), data);
    }

    /**
     * 成功响应（仅自定义提示信息）
     */
    public static Result<Void> success(String message) {
        return new Result<>(ErrorCode.SUCCESS.getCode(), message, null);
    }

    /**
     * 成功响应（带自定义提示信息和数据）
     */
    public static <T> Result<T> success(String message, T data) {
        return new Result<>(ErrorCode.SUCCESS.getCode(), message, data);
    }

    /**
     * 失败响应（使用业务错误码）
     */
    public static <T> Result<T> failed(ErrorCode errorCode) {
        return new Result<>(errorCode.getCode(), errorCode.getMessage(), null);
    }

    /**
     * 失败响应（自定义错误码和错误消息）
     */
    public static <T> Result<T> failed(int code, String message) {
        return new Result<>(code, message, null);
    }

    /**
     * 失败响应（使用业务错误码并自定义错误消息）
     */
    public static <T> Result<T> failed(ErrorCode errorCode, String message) {
        return new Result<>(errorCode.getCode(), message, null);
    }

    /**
     * 失败响应（仅自定义错误消息，使用默认系统错误码）
     */
    public static <T> Result<T> failed(String message) {
        return new Result<>(ErrorCode.SYSTEM_ERROR.getCode(), message, null);
    }
}
