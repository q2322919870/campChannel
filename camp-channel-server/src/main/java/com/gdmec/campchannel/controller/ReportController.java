package com.gdmec.campchannel.controller;

import com.gdmec.campchannel.common.api.Result;
import com.gdmec.campchannel.entity.Report;
import com.gdmec.campchannel.entity.User;
import com.gdmec.campchannel.security.SecurityUser;
import com.gdmec.campchannel.service.ReportService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "举报管理模块", description = "用户举报和管理员处理举报")
@RestController
@RequestMapping("/reports")
public class ReportController {

    @Autowired
    private ReportService reportService;

    @PostMapping
    @Operation(summary = "用户提交举报")
    public Result<Report> submitReport(
            @RequestBody SubmitReportRequest request,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        Report report = reportService.submitReport(
            currentUser.getId(),
            request.getTargetType(),
            request.getTargetId(),
            request.getReason()
        );
        
        return Result.success("举报成功，我们会尽快处理", report);
    }

    @GetMapping("/admin")
    @Operation(summary = "管理员获取所有举报")
    public Result<List<Report>> getAllReports(
            @RequestParam(required = false) Integer status,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        // 检查是否为管理员
        User user = new User();
        user.setId(currentUser.getId());
        if (!"sys_admin".equals(user.getRole())) {
            return Result.failed(403, "无权限访问");
        }

        List<Report> reports = reportService.getAllReports(status, page, size);
        return Result.success(reports);
    }

    @PutMapping("/admin/{reportId}")
    @Operation(summary = "管理员处理举报")
    public Result<Void> handleReport(
            @PathVariable Long reportId,
            @RequestBody HandleReportRequest request,
            @AuthenticationPrincipal SecurityUser currentUser) {
        
        // 检查是否为管理员
        User user = new User();
        user.setId(currentUser.getId());
        if (!"sys_admin".equals(user.getRole())) {
            return Result.failed(403, "无权限访问");
        }

        reportService.handleReport(
            reportId,
            currentUser.getId(),
            request.getStatus(),
            request.getHandleNote()
        );
        
        return Result.success("处理成功");
    }

    @Data
    public static class SubmitReportRequest {
        private String targetType; // post, comment
        private Long targetId;
        private String reason;
    }

    @Data
    public static class HandleReportRequest {
        private Integer status; // 1-确认违规, 2-驳回
        private String handleNote;
    }
}
