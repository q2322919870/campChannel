package com.gdmec.campchannel.common.filter;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

/**
 * 基于 DFA (确定有穷自动机) 算法的敏感词过滤器
 */
@Slf4j
@Component
public class SensitiveWordFilter {

    @Value("${app.word-filter.file-path}")
    private Resource sensitiveWordsResource;

    // DFA 敏感词树根节点
    @SuppressWarnings("rawtypes")
    private final Map sensitiveWordMap = new HashMap();

    // 默认替换字符
    private static final char REPLACE_CHAR = '*';

    // 最小匹配规则
    public static final int MIN_MATCH_TYPE = 1;
    // 最大匹配规则
    public static final int MAX_MATCH_TYPE = 2;

    /**
     * 系统启动时初始化加载词库
     */
    @PostConstruct
    public void init() {
        try {
            log.info("开始加载系统敏感词库...");
            if (sensitiveWordsResource == null || !sensitiveWordsResource.exists()) {
                log.warn("未发现敏感词字典文件，敏感词过滤功能暂未生效。");
                return;
            }
            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(sensitiveWordsResource.getInputStream(), StandardCharsets.UTF_8))) {
                String line;
                int count = 0;
                while ((line = reader.readLine()) != null) {
                    line = line.trim();
                    if (!line.isEmpty()) {
                        addSensitiveWord(line);
                        count++;
                    }
                }
                log.info("系统敏感词库加载成功，共加载 {} 个敏感词。", count);
            }
        } catch (Exception e) {
            log.error("加载敏感词词库异常：", e);
        }
    }

    /**
     * 添加敏感词到树结构中
     */
    @SuppressWarnings({ "unchecked", "rawtypes" })
    private void addSensitiveWord(String word) {
        Map currentMap = sensitiveWordMap;
        for (int i = 0; i < word.length(); i++) {
            char keyChar = word.charAt(i);
            Object wordMap = currentMap.get(keyChar);

            if (wordMap != null) {
                currentMap = (Map) wordMap;
            } else {
                Map newWordMap = new HashMap();
                newWordMap.put("isEnd", "0");
                currentMap.put(keyChar, newWordMap);
                currentMap = newWordMap;
            }

            if (i == word.length() - 1) {
                currentMap.put("isEnd", "1");
            }
        }
    }

    /**
     * 判断文本中是否包含敏感词
     */
    public boolean contains(String text) {
        if (text == null || text.trim().isEmpty()) {
            return false;
        }
        for (int i = 0; i < text.length(); i++) {
            int matchLength = checkSensitiveWord(text, i, MIN_MATCH_TYPE);
            if (matchLength > 0) {
                return true;
            }
        }
        return false;
    }

    /**
     * 过滤并替换文本中的敏感词，用星号(*)代替
     */
    public String filter(String text) {
        if (text == null || text.trim().isEmpty()) {
            return text;
        }
        StringBuilder result = new StringBuilder(text);
        for (int i = 0; i < text.length(); i++) {
            int matchLength = checkSensitiveWord(text, i, MAX_MATCH_TYPE);
            if (matchLength > 0) {
                // 找到敏感词，进行替换
                for (int j = i; j < i + matchLength; j++) {
                    result.setCharAt(j, REPLACE_CHAR);
                }
                // 偏移指针到敏感词后
                i = i + matchLength - 1;
            }
        }
        return result.toString();
    }

    /**
     * 检查从指定起始位置开始的文字是否属于敏感词
     *
     * @param text       输入文本
     * @param beginIndex 起始搜索下标
     * @param matchType  匹配规则：1 = 最小匹配，2 = 最大匹配
     * @return 如果找到敏感词，返回敏感词长度；否则返回0
     */
    @SuppressWarnings("rawtypes")
    private int checkSensitiveWord(String text, int beginIndex, int matchType) {
        Map currentMap = sensitiveWordMap;
        int matchLength = 0;
        boolean flag = false;

        for (int i = beginIndex; i < text.length(); i++) {
            char keyChar = text.charAt(i);
            currentMap = (Map) currentMap.get(keyChar);

            if (currentMap == null) {
                break;
            } else {
                matchLength++;
                if ("1".equals(currentMap.get("isEnd"))) {
                    flag = true;
                    if (MIN_MATCH_TYPE == matchType) {
                        break;
                    }
                }
            }
        }

        if (matchLength < 2 && !flag) {
            return 0; // 敏感词最小长度应为2或已经是完整词
        }
        return flag ? matchLength : 0;
    }
}
