package com.gdmec.campchannel.controller;

import com.gdmec.campchannel.common.api.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.security.MessageDigest;
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

    private static final long MAX_VIDEO_SIZE = 5 * 1024 * 1024; // 5MB

    @PostMapping("/image")
    @Operation(summary = "上传图片")
    public Result<Map<String, String>> uploadImage(@RequestParam("file") MultipartFile file) {
        return uploadFile(file, "images", false);
    }

    @PostMapping("/video")
    @Operation(summary = "上传视频（自动去重和压缩）")
    public Result<Map<String, String>> uploadVideo(@RequestParam("file") MultipartFile file) {
        return uploadFile(file, "videos", true);
    }

    @PostMapping("/avatar")
    @Operation(summary = "上传头像")
    public Result<Map<String, String>> uploadAvatar(@RequestParam("file") MultipartFile file) {
        return uploadFile(file, "avatars", false);
    }

    @GetMapping("/video/check")
    @Operation(summary = "视频秒传校验：根据文件Hash检查是否已存在")
    public Result<Map<String, Object>> checkVideoExists(@RequestParam("hash") String hash) {
        try {
            Path baseDir = Paths.get(uploadPath).toAbsolutePath().normalize();
            Path videoDir = baseDir.resolve("videos");
            
            // 检查常见视频格式是否存在
            String[] extensions = {".mp4", ".webm", ".mov", ".avi", ".mkv"};
            for (String ext : extensions) {
                Path filePath = videoDir.resolve(hash + ext);
                if (filePath.toFile().exists()) {
                    String fileUrl = "/uploads/videos/" + hash + ext;
                    Map<String, Object> result = new HashMap<>();
                    result.put("exists", true);
                    result.put("url", fileUrl);
                    log.info("视频秒传命中: {}", hash);
                    return Result.success("文件已存在", result);
                }
            }
            
            Map<String, Object> result = new HashMap<>();
            result.put("exists", false);
            return Result.success("文件不存在", result);
        } catch (Exception e) {
            log.error("秒传校验失败", e);
            Map<String, Object> result = new HashMap<>();
            result.put("exists", false);
            return Result.success("校验失败", result);
        }
    }

    /**
     * 计算文件内容的MD5哈希值，用于去重
     */
    private String calculateFileHash(InputStream inputStream) {
        try {
            MessageDigest md = MessageDigest.getInstance("MD5");
            byte[] buffer = new byte[8192];
            int bytesRead;
            while ((bytesRead = inputStream.read(buffer)) != -1) {
                md.update(buffer, 0, bytesRead);
            }
            byte[] digest = md.digest();
            StringBuilder sb = new StringBuilder();
            for (byte b : digest) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (Exception e) {
            log.error("计算文件哈希失败", e);
            return null;
        }
    }

    /**
     * 压缩视频文件（使用FFmpeg）
     * @param sourceFile 源文件
     * @param targetFile 目标文件
     * @param maxSize 最大文件大小（字节）
     * @return 是否压缩成功
     */
    private boolean compressVideo(File sourceFile, File targetFile, long maxSize) {
        try {
            // 检查FFmpeg是否可用
            ProcessBuilder probeBuilder = new ProcessBuilder("ffmpeg", "-version");
            probeBuilder.redirectErrorStream(true);
            Process probeProcess = probeBuilder.start();
            int probeExit = probeProcess.waitFor();
            if (probeExit != 0) {
                log.warn("FFmpeg不可用，跳过视频压缩");
                return false;
            }

            // 尝试不同的压缩参数
            int[] crfValues = {28, 32, 36, 40}; // CRF值越大，压缩越强，质量越低
            
            for (int crf : crfValues) {
                ProcessBuilder pb = new ProcessBuilder(
                    "ffmpeg", "-y",
                    "-i", sourceFile.getAbsolutePath(),
                    "-c:v", "libx264",
                    "-crf", String.valueOf(crf),
                    "-preset", "fast",
                    "-c:a", "aac",
                    "-b:a", "128k",
                    "-movflags", "+faststart",
                    targetFile.getAbsolutePath()
                );
                pb.redirectErrorStream(true);
                Process process = pb.start();
                int exitCode = process.waitFor();
                
                if (exitCode == 0 && targetFile.exists()) {
                    long compressedSize = targetFile.length();
                    log.info("视频压缩完成: CRF={}, 原始大小={}KB, 压缩后大小={}KB", 
                        crf, sourceFile.length()/1024, compressedSize/1024);
                    
                    if (compressedSize <= maxSize) {
                        return true;
                    }
                    // 如果仍然超过大小限制，继续尝试更高的CRF
                    targetFile.delete();
                }
            }
            
            // 如果所有CRF值都不行，尝试降低分辨率
            ProcessBuilder pb = new ProcessBuilder(
                "ffmpeg", "-y",
                "-i", sourceFile.getAbsolutePath(),
                "-c:v", "libx264",
                "-crf", "40",
                "-preset", "fast",
                "-vf", "scale=640:-1",
                "-c:a", "aac",
                "-b:a", "96k",
                "-movflags", "+faststart",
                targetFile.getAbsolutePath()
            );
            pb.redirectErrorStream(true);
            Process process = pb.start();
            int exitCode = process.waitFor();
            
            if (exitCode == 0 && targetFile.exists()) {
                log.info("视频压缩完成（降低分辨率）: 原始大小={}KB, 压缩后大小={}KB", 
                    sourceFile.length()/1024, targetFile.length()/1024);
                return true;
            }
            
            return false;
        } catch (Exception e) {
            log.error("视频压缩失败", e);
            return false;
        }
    }

    private Result<Map<String, String>> uploadFile(MultipartFile file, String subDir, boolean isVideo) {
        if (file == null || file.isEmpty()) {
            return Result.failed(com.gdmec.campchannel.common.api.ErrorCode.BAD_REQUEST, "文件不能为空");
        }

        try {
            String originalFilename = file.getOriginalFilename();
            String extension = "";
            if (originalFilename != null && originalFilename.contains(".")) {
                extension = originalFilename.substring(originalFilename.lastIndexOf("."));
            }

            Path baseDir = Paths.get(uploadPath).toAbsolutePath().normalize();
            Path uploadDir = baseDir.resolve(subDir);
            Files.createDirectories(uploadDir);

            String newFilename;
            Path filePath;

            if (isVideo) {
                // 视频上传：去重 + 压缩
                // 1. 先保存临时文件
                String tempFilename = UUID.randomUUID().toString().replace("-", "") + extension;
                Path tempPath = uploadDir.resolve(tempFilename);
                file.transferTo(tempPath.toFile());

                File tempFile = tempPath.toFile();
                long fileSize = tempFile.length();

                // 2. 计算文件哈希用于去重
                String fileHash = null;
                try (java.io.FileInputStream fis = new java.io.FileInputStream(tempFile)) {
                    fileHash = calculateFileHash(fis);
                }
                
                if (fileHash != null) {
                    // 检查是否已存在相同文件
                    String hashFilename = fileHash + extension;
                    Path existingFile = uploadDir.resolve(hashFilename);
                    
                    if (existingFile.toFile().exists()) {
                        // 删除刚上传的临时文件
                        tempFile.delete();
                        log.info("视频已存在，跳过上传: {}", hashFilename);
                        String fileUrl = "/uploads/" + subDir + "/" + hashFilename;
                        Map<String, String> result = new HashMap<>();
                        result.put("url", fileUrl);
                        result.put("filename", hashFilename);
                        result.put("duplicated", "true");
                        return Result.success("上传成功（文件已存在）", result);
                    }
                }

                // 3. 始终尝试压缩视频到5MB以内
                log.info("视频原始大小 {}KB，开始压缩到 {}KB 以内", fileSize/1024, MAX_VIDEO_SIZE/1024);
                
                String compressedFilename = fileHash != null ? fileHash + extension : tempFilename;
                Path compressedPath = uploadDir.resolve(compressedFilename);
                File compressedFile = compressedPath.toFile();
                
                boolean compressed = compressVideo(tempFile, compressedFile, MAX_VIDEO_SIZE);
                
                if (compressed && compressedFile.exists() && compressedFile.length() <= MAX_VIDEO_SIZE) {
                    // 压缩成功且文件大小符合要求，删除临时文件
                    tempFile.delete();
                    filePath = compressedPath;
                    newFilename = compressedFilename;
                    log.info("视频压缩成功: {}KB -> {}KB", 
                        fileSize/1024, compressedFile.length()/1024);
                } else if (compressed && compressedFile.exists()) {
                    // 压缩完成但仍然超过5MB，保留压缩后的文件
                    tempFile.delete();
                    filePath = compressedPath;
                    newFilename = compressedFilename;
                    log.warn("视频压缩后仍为 {}KB，超过 {}KB 限制", 
                        compressedFile.length()/1024, MAX_VIDEO_SIZE/1024);
                } else {
                    // 压缩失败，使用原始文件（重命名为哈希值）
                    if (fileHash != null) {
                        String hashFilename = fileHash + extension;
                        Path hashPath = uploadDir.resolve(hashFilename);
                        Files.move(tempPath, hashPath, StandardCopyOption.REPLACE_EXISTING);
                        filePath = hashPath;
                        newFilename = hashFilename;
                    } else {
                        filePath = tempPath;
                        newFilename = tempFilename;
                    }
                    log.warn("视频压缩失败，使用原始文件");
                }
            } else {
                // 图片/头像：使用UUID命名
                newFilename = UUID.randomUUID().toString().replace("-", "") + extension;
                filePath = uploadDir.resolve(newFilename);
                file.transferTo(filePath.toFile());
            }

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
