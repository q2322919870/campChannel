package com.gdmec.campchannel.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.gdmec.campchannel.entity.Comment;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface CommentMapper extends BaseMapper<Comment> {
}