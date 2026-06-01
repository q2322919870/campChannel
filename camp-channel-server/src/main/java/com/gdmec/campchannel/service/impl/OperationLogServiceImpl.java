package com.gdmec.campchannel.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.gdmec.campchannel.entity.OperationLog;
import com.gdmec.campchannel.mapper.OperationLogMapper;
import com.gdmec.campchannel.service.OperationLogService;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class OperationLogServiceImpl extends ServiceImpl<OperationLogMapper, OperationLog> implements OperationLogService {

    @Override
    public void log(Long userId, String module, String action, String description, String requestMethod, String requestUrl, String ipAddress) {
        OperationLog log = new OperationLog();
        log.setUserId(userId);
        log.setModule(module);
        log.setAction(action);
        log.setDescription(description);
        log.setRequestMethod(requestMethod);
        log.setRequestUrl(requestUrl);
        log.setIpAddress(ipAddress);
        log.setCreateTime(LocalDateTime.now());
        save(log);
    }

    @Override
    public List<OperationLog> getLogs(int page, int size, Long userId, String module) {
        QueryWrapper<OperationLog> queryWrapper = new QueryWrapper<>();
        
        if (userId != null) {
            queryWrapper.eq("user_id", userId);
        }
        if (StringUtils.hasText(module)) {
            queryWrapper.eq("module", module);
        }
        
        queryWrapper.orderByDesc("create_time");
        
        int offset = (page - 1) * size;
        queryWrapper.last("LIMIT " + offset + ", " + size);
        
        return list(queryWrapper);
    }
}