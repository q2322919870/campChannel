package com.gdmec.campchannel.controller;

import com.gdmec.campchannel.common.api.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;

import java.io.File;
import java.util.*;

@Tag(name = "默认头像模块", description = "提供默认头像列表和随机分配功能")
@Slf4j
@RestController
@RequestMapping("/avatars")
public class AvatarController {

    @Value("${app.upload.local-path}")
    private String uploadPath;

    @GetMapping("/defaults")
    @Operation(summary = "获取默认头像列表")
    public Result<List<String>> getDefaultAvatars() {
        List<String> avatars = new ArrayList<>();
        File avatarsDir = new File(uploadPath, "avatars");
        if (avatarsDir.exists() && avatarsDir.isDirectory()) {
            File[] files = avatarsDir.listFiles((dir, name) -> 
                name.endsWith(".svg") || name.endsWith(".jpg") || name.endsWith(".png"));
            if (files != null) {
                Arrays.sort(files, Comparator.comparing(File::getName));
                for (File f : files) {
                    avatars.add("/uploads/avatars/" + f.getName());
                }
            }
        }
        return Result.success(avatars);
    }

    @GetMapping("/random")
    @Operation(summary = "获取随机默认头像")
    public Result<Map<String, String>> getRandomAvatar() {
        List<String> avatars = new ArrayList<>();
        File avatarsDir = new File(uploadPath, "avatars");
        if (avatarsDir.exists() && avatarsDir.isDirectory()) {
            File[] files = avatarsDir.listFiles((dir, name) -> 
                name.endsWith(".svg") || name.endsWith(".jpg") || name.endsWith(".png"));
            if (files != null) {
                for (File f : files) {
                    avatars.add("/uploads/avatars/" + f.getName());
                }
            }
        }
        Random rand = new Random();
        String url = avatars.isEmpty() ? "" : avatars.get(rand.nextInt(avatars.size()));
        Map<String, String> result = new HashMap<>();
        result.put("url", url);
        return Result.success(result);
    }
}
