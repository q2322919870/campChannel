package com.gdmec.campchannel.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.gdmec.campchannel.common.api.ErrorCode;
import com.gdmec.campchannel.common.exception.BusinessException;
import com.gdmec.campchannel.entity.Post;
import com.gdmec.campchannel.entity.Report;
import com.gdmec.campchannel.mapper.PostMapper;
import com.gdmec.campchannel.mapper.ReportMapper;
import com.gdmec.campchannel.service.ReportService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Slf4j
@Service
public class ReportServiceImpl implements ReportService {

    @Autowired
    private ReportMapper reportMapper;

    @Autowired
    private PostMapper postMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Report submitReport(Long reporterId, String targetType, Long targetId, String reason) {
        // 检查是否已经举报过
        QueryWrapper<Report> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("reporter_id", reporterId)
                .eq("target_type", targetType)
                .eq("target_id", targetId);
        Long count = reportMapper.selectCount(queryWrapper);
        
        if (count > 0) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "你已经举报过该内容");
        }

        Report report = new Report();
        report.setReporterId(reporterId);
        report.setTargetType(targetType);
        report.setTargetId(targetId);
        report.setReason(reason);
        report.setStatus(0); // 待处理
        report.setCreateTime(LocalDateTime.now());

        reportMapper.insert(report);
        log.info("用户 {} 举报了 {} {}", reporterId, targetType, targetId);
        
        return report;
    }

    @Override
    public List<Report> getAllReports(Integer status, int page, int size) {
        QueryWrapper<Report> queryWrapper = new QueryWrapper<>();
        if (status != null) {
            queryWrapper.eq("status", status);
        }
        queryWrapper.orderByDesc("create_time");
        
        int offset = (page - 1) * size;
        queryWrapper.last("LIMIT " + offset + ", " + size);
        
        return reportMapper.selectList(queryWrapper);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void handleReport(Long reportId, Long handlerId, Integer status, String handleNote) {
        Report report = reportMapper.selectById(reportId);
        if (report == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "举报记录不存在");
        }

        if (report.getStatus() != 0) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "该举报已经处理过");
        }

        report.setStatus(status);
        report.setHandlerId(handlerId);
        report.setHandleNote(handleNote);
        report.setHandleTime(LocalDateTime.now());
        reportMapper.updateById(report);

        // 如果确认违规，下架目标帖子
        if (status == 1 && "post".equals(report.getTargetType())) {
            Post post = postMapper.selectById(report.getTargetId());
            if (post != null) {
                post.setStatus(2); // 已删除/下架
                postMapper.updateById(post);
                log.info("举报确认违规，下架帖子 {}", post.getId());
            }
        }

        log.info("管理员 {} 处理举报 {}，状态: {}", handlerId, reportId, status);
    }

    @Override
    public List<Report> getReportsByTarget(String targetType, Long targetId) {
        QueryWrapper<Report> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("target_type", targetType)
                .eq("target_id", targetId);
        return reportMapper.selectList(queryWrapper);
    }
}
