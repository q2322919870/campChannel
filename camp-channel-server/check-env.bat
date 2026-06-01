@echo off
chcp 65001 >nul
echo.
echo ===== 编译环境诊断 =====
echo.

echo [1] Java 版本检查:
java -version 2>&1

echo.
echo [2] Maven 版本检查:
where mvn >nul 2>&1
if %errorlevel% equ 0 (
    mvn -v
) else (
    echo ⚠️ Maven 未添加到系统 PATH，请检查 MAVEN_HOME 配置
)

echo.
echo [3] 当前项目 JDK 设置:
echo 预期: Java 17+

echo.
echo ===== 诊断完成 =====
echo.
pause

