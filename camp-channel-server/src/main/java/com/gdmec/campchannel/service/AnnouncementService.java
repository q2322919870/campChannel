package com.gdmec.campchannel.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.gdmec.campchannel.entity.Announcement;

import java.util.List;

public interface AnnouncementService extends IService<Announcement> {

    List<Announcement> getActiveAnnouncements();

    Announcement createAnnouncement(String title, String content, String type, String coverImage, Long createdBy, Long channelId);
}
