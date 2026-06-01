package com.gdmec.campchannel.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.gdmec.campchannel.entity.Announcement;
import com.gdmec.campchannel.mapper.AnnouncementMapper;
import com.gdmec.campchannel.service.AnnouncementService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Slf4j
@Service
public class AnnouncementServiceImpl extends ServiceImpl<AnnouncementMapper, Announcement> implements AnnouncementService {

    @Override
    public List<Announcement> getActiveAnnouncements() {
        return list(new QueryWrapper<Announcement>()
                .eq("status", 1)
                .orderByDesc("created_at"));
    }

    @Override
    public Announcement createAnnouncement(String title, String content, String type, String coverImage, Long createdBy, Long channelId) {
        Announcement a = new Announcement();
        a.setTitle(title);
        a.setContent(content);
        a.setType(type != null ? type : "scratch");
        a.setCoverImage(coverImage);
        a.setCreatedBy(createdBy);
        a.setChannelId(channelId);
        a.setStatus(1);
        a.setCreatedAt(LocalDateTime.now());
        save(a);
        return a;
    }
}
