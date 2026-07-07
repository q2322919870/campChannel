@echo off
chcp 65001 >nul
echo ========================================
echo   Java 26 环境变量配置脚本
echo ========================================
echo.

set JAVA_PATH=C:\Program Files\Java\latest\jdk-26

if not exist "%JAVA_PATH%" (
    echo [错误] 未找到 Java 26 安装目录: %JAVA_PATH%
    echo 请确认 Java 26 已正确安装。
    pause
    exit /b 1
)

echo [信息] 找到 Java 安装: %JAVA_PATH%
echo.

echo [1/3] 设置 JAVA_HOME 环境变量...
setx JAVA_HOME "%JAVA_PATH%" /m
if %errorlevel% neq 0 (
    echo [警告] 无法设置系统级 JAVA_HOME，尝试设置用户级...
    setx JAVA_HOME "%JAVA_PATH%"
)

echo [2/3] 更新 PATH 环境变量...
setx PATH "%JAVA_PATH%\bin;%%PATH%%" /m
if %errorlevel% neq 0 (
    echo [警告] 无法更新系统级 PATH，尝试更新用户级...
    setx PATH "%JAVA_PATH%\bin;%%PATH%%"
)

echo [3/3] 验证安装...
echo.
echo 请关闭此窗口并重新打开新的命令提示符，然后运行:
echo   java -version
echo   javac -version
echo.
echo ========================================
echo   配置完成！
echo ========================================
pause
