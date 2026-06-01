package com.gdmec.campchannel.controller;

import com.gdmec.campchannel.common.api.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Tag(name = "文件上传模块", description = "本地模拟 OSS 文件上传")
@Slf4j
@RestController
@RequestMapping("/upload")
public class UploadController {

    @Value("${app.upload.local-path}")
    private String uploadPath;

    @PostMapping("/image")
    @Operation(summary = "上传图片")
    public Result<Map<String, String>> uploadImage(@RequestParam("file") MultipartFile file) {
        return uploadFile(file, "images");
    }

    @PostMapping("/video")
    @Operation(summary = "上传视频")
    public Result<Map<String, String>> uploadVideo(@RequestParam("file") MultipartFile file) {
        return uploadFile(file, "videos");
    }

    @PostMapping("/avatar")
    @Operation(summary = "上传头像")
    public Result<Map<String, String>> uploadAvatar(@RequestParam("file") MultipartFile file) {
        return uploadFile(file, "avatars");
    }

    private Result<Map<String, String>> uploadFile(MultipartFile file, String subDir) {
        if (file == null || file.isEmpty()) {
            return Result.failed(com.gdmec.campchannel.common.api.ErrorCode.BAD_REQUEST, "文件不能为空");
        }

        try {
            String originalFilename = file.getOriginalFilename();
            String extension = "";
            if (originalFilename != null && originalFilename.contains(".")) {
                extension = originalFilename.substring(originalFilename.lastIndexOf("."));
            }

            String newFilename = UUID.randomUUID().toString().replace("-", "") + extension;

            // 使用绝对路径确保目录创建成功
            Path baseDir = Paths.get(uploadPath).toAbsolutePath().normalize();
            Path uploadDir = baseDir.resolve(subDir);

            // 确保目录存在
            Files.createDirectories(uploadDir);

            Path filePath = uploadDir.resolve(newFilename);
            file.transferTo(filePath.toFile());

            String fileUrl = "/uploads/" + subDir + "/" + newFilename;
            Map<String, String> result = new HashMap<>();
            result.put("url", fileUrl);
            result.put("filename", newFilename);

            log.info("文件上传成功: {} -> {}", fileUrl, filePath.toAbsolutePath());
            return Result.success("上传成功", result);

        } catch (IOException e) {
            log.error("文件上传失败", e);
            return Result.failed(com.gdmec.campchannel.common.api.ErrorCode.SYSTEM_ERROR, "上传失败: " + e.getMessage());
        }
    }
}
