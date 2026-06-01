package com.gdmec.campchannel.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.gdmec.campchannel.entity.OperationLog;

import java.util.List;

public interface OperationLogService extends IService<OperationLog> {

    /**
     * 记录操作日志
     */
    void log(Long userId, String module, String action, String description, String requestMethod, String requestUrl, String ipAddress);

    /**
     * 获取操作日志列表（分页）
     */
    List<OperationLog> getLogs(int page, int size, Long userId, String module);
}