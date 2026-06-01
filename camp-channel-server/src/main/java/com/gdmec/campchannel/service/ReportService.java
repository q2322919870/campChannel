package com.gdmec.campchannel.service;

import com.gdmec.campchannel.entity.Report;

import java.util.List;

public interface ReportService {

    /**
     * 用户提交举报
     */
    Report submitReport(Long reporterId, String targetType, Long targetId, String reason);

    /**
     * 管理员获取所有举报
     */
    List<Report> getAllReports(Integer status, int page, int size);

    /**
     * 管理员处理举报
     */
    void handleReport(Long reportId, Long handlerId, Integer status, String handleNote);

    /**
     * 获取针对某个帖子的举报
     */
    List<Report> getReportsByTarget(String targetType, Long targetId);
}
