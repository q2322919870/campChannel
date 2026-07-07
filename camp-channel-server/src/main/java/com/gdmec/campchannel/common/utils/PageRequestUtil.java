package com.gdmec.campchannel.common.utils;

import com.gdmec.campchannel.common.exception.BusinessException;

/**
 * 分页参数工具类，统一处理页码和页大小，防止深度分页攻击
 */
public final class PageRequestUtil {

    /** 默认页码 */
    public static final int DEFAULT_PAGE = 1;
    /** 默认每页大小 */
    public static final int DEFAULT_SIZE = 20;
    /** 最大每页大小 */
    public static final int MAX_SIZE = 100;
    /** 搜索接口最大每页大小 */
    public static final int SEARCH_MAX_SIZE = 50;
    /** 最大页码（防止深度分页攻击） */
    public static final int MAX_PAGE = 1000;

    private PageRequestUtil() {}

    /**
     * 构建分页参数（列表类接口）
     */
    public static int[] build(Integer page, Integer size) {
        return build(page, size, MAX_SIZE);
    }

    /**
     * 构建分页参数（自定义最大页大小）
     */
    public static int[] build(Integer page, Integer size, int maxSize) {
        int p = (page == null || page < 1) ? DEFAULT_PAGE : page;
        int s = (size == null || size < 1) ? DEFAULT_SIZE : Math.min(size, maxSize);

        if (p > MAX_PAGE) {
            throw new BusinessException("页码不能超过 " + MAX_PAGE);
        }
        return new int[]{p, s};
    }

    /**
     * 计算偏移量
     */
    public static int offset(int page, int size) {
        return (page - 1) * size;
    }
}
