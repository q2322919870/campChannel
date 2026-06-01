package com.gdmec.campchannel.common.exception;

import com.gdmec.campchannel.common.api.ErrorCode;
import com.gdmec.campchannel.common.api.Result;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.validation.BindException;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.util.Objects;

/**
 * 全局异常捕获处理器
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    /**
     * 处理自定义业务异常
     */
    @ExceptionHandler(BusinessException.class)
    public Result<?> handleBusinessException(BusinessException e) {
        log.warn("业务异常: code={}, message={}", e.getErrorCode().getCode(), e.getMessage());
        return Result.failed(e.getErrorCode(), e.getMessage());
    }

    /**
     * 处理 JSR303 属性验证异常 (RequestBody)
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public Result<?> handleValidationException(MethodArgumentNotValidException e) {
        BindingResult bindingResult = e.getBindingResult();
        String message = null;
        if (bindingResult.hasErrors()) {
            FieldError fieldError = bindingResult.getFieldError();
            if (fieldError != null) {
                message = fieldError.getField() + fieldError.getDefaultMessage();
            }
        }
        log.warn("参数校验异常: {}", message);
        return Result.failed(ErrorCode.BAD_REQUEST, message != null ? message : "请求参数不合法");
    }

    /**
     * 处理 JSR303 属性绑定异常 (Form表单/RequestParam)
     */
    @ExceptionHandler(BindException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public Result<?> handleBindException(BindException e) {
        BindingResult bindingResult = e.getBindingResult();
        String message = null;
        if (bindingResult.hasErrors()) {
            FieldError fieldError = bindingResult.getFieldError();
            if (fieldError != null) {
                message = fieldError.getField() + fieldError.getDefaultMessage();
            }
        }
        log.warn("参数绑定异常: {}", message);
        return Result.failed(ErrorCode.BAD_REQUEST, message != null ? message : "参数解析失败");
    }

    /**
     * 处理 Spring Security 权限访问拒绝异常
     */
    @ExceptionHandler(AccessDeniedException.class)
    @ResponseStatus(HttpStatus.FORBIDDEN)
    public Result<?> handleAccessDeniedException(AccessDeniedException e) {
        log.warn("权限不足拒绝访问: {}", e.getMessage());
        return Result.failed(ErrorCode.FORBIDDEN);
    }

    /**
     * 处理 Spring Security 认证异常
     */
    @ExceptionHandler(AuthenticationException.class)
    @ResponseStatus(HttpStatus.UNAUTHORIZED)
    public Result<?> handleAuthenticationException(AuthenticationException e) {
        log.warn("认证失败异常: {}", e.getMessage());
        return Result.failed(ErrorCode.UNAUTHORIZED, e.getMessage());
    }

    /**
     * 处理请求方法不支持异常
     */
    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    @ResponseStatus(HttpStatus.METHOD_NOT_ALLOWED)
    public Result<?> handleMethodNotSupported(HttpRequestMethodNotSupportedException e) {
        log.warn("方法不支持: {}", e.getMessage());
        return Result.failed(ErrorCode.METHOD_NOT_ALLOWED);
    }

    /**
     * 处理 404 资源未找到异常
     */
    @ExceptionHandler({NoResourceFoundException.class})
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public Result<?> handleNotFoundException(Exception e) {
        log.warn("资源未找到: {}", e.getMessage());
        return Result.failed(ErrorCode.NOT_FOUND);
    }

    /**
     * 处理未知兜底异常
     */
    @ExceptionHandler(Exception.class)
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    public Result<?> handleException(Exception e) {
        log.error("系统未知异常: ", e);
        return Result.failed(ErrorCode.SYSTEM_ERROR);
    }
}
