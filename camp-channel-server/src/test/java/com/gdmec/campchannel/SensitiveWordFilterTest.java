package com.gdmec.campchannel;

import com.gdmec.campchannel.common.filter.SensitiveWordFilter;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;
import org.springframework.test.util.ReflectionTestUtils;

/**
 * 敏感词过滤器纯单元测试：不启动 SpringBoot 上下文，避免数据库、Redis、Security 等依赖影响测试。
 */
public class SensitiveWordFilterTest {

    private SensitiveWordFilter sensitiveWordFilter;

    @BeforeEach
    void setUp() {
        sensitiveWordFilter = new SensitiveWordFilter();
        ReflectionTestUtils.setField(
                sensitiveWordFilter,
                "sensitiveWordsResource",
                new ClassPathResource("sensitive_words.txt")
        );
        sensitiveWordFilter.init();
    }

    @Test
    void testContainsSensitiveWord() {
        String text1 = "这是一段包含敏感词1的文本";
        String text2 = "这是一段健康的绿色文字，没有任何违禁内容";

        Assertions.assertTrue(sensitiveWordFilter.contains(text1));
        Assertions.assertFalse(sensitiveWordFilter.contains(text2));
    }

    @Test
    void testFilterSensitiveWord() {
        String text = "这是一段包含敏感词1和敏感词2的测试句子";
        String filteredText = sensitiveWordFilter.filter(text);

        System.out.println("过滤前：" + text);
        System.out.println("过滤后：" + filteredText);

        Assertions.assertNotNull(filteredText);
        Assertions.assertTrue(filteredText.contains("****"));
        Assertions.assertFalse(filteredText.contains("敏感词1"));
        Assertions.assertFalse(filteredText.contains("敏感词2"));
    }
}
