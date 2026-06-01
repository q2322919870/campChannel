package com.gdmec.campchannel.common.exception;

import com.gdmec.campchannel.common.api.ErrorCode;
import lombok.Getter;

/**
 * 自定义业务异常类
 */
@Getter
public class BusinessException extends RuntimeException {
    private final ErrorCode errorCode;

    public BusinessException(ErrorCode errorCode) {
        super(errorCode.getMessage());
        this.errorCode = errorCode;
    }

    public BusinessException(ErrorCode errorCode, String customMessage) {
        super(customMessage);
        this.errorCode = errorCode;
    }

    public BusinessException(String defaultMessage) {
        super(defaultMessage);
        this.errorCode = ErrorCode.SYSTEM_ERROR;
    }
}
