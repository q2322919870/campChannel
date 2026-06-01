@echo off
REM IDE 自动配置修复脚本
REM 此脚本可修复 JetBrains IDE 的编译器配置问题

setlocal enabledelayedexpansion
chcp 65001 >nul

set IDEA_FOLDER=.idea

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║     IDE 编译器配置自动修复工具                              ║
echo ║     Compiler Configuration Auto-Fix Tool                  ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

if not exist "%IDEA_FOLDER%" (
    echo ℹ️  .idea 文件夹不存在，创建中...
    mkdir "%IDEA_FOLDER%"
)

echo [1/3] 更新编译器配置...

REM 创建或更新 misc.xml （IDE 设置）
(
    echo ^<?xml version="1.0" encoding="UTF-8"?^>
    echo ^<project version="4"^>
    echo   ^<component name="ProjectRootManager" version="2" languageLevel="JDK_17" default="true" project-jdk-name="17" project-jdk-type="JavaSDK"^>
    echo     ^<output url="file://$PROJECT_DIR$/out" /^>
    echo   ^</component^>
    echo ^</project^>
) > "%IDEA_FOLDER%\misc.xml" 2>nul

echo ✓ IDE 根配置已更新

echo [2/3] 更新 Java 编译器版本...

REM 创建或更新 jps-build-system.xml
(
    echo ^<?xml version="1.0" encoding="UTF-8"?^>
    echo ^<project version="4"^>
    echo   ^<component name="CompilerConfiguration"^>
    echo     ^<option name="DEFAULT_COMPILER" value="javac" /^>
    echo     ^<resourceExtensions^>
    echo       ^<entry name="!?*.java" /^>
    echo     ^</resourceExtensions^>
    echo     ^<wildcardResourcePatterns^>
    echo       ^<entry name="!?*.class" /^>
    echo       ^<entry name="!?*.scala" /^>
    echo       ^<entry name="!?*.groovy" /^>
    echo     ^</wildcardResourcePatterns^>
    echo     ^<annotationProcessing^>
    echo       ^<profile default="true" name="Default" enabled="true"^>
    echo         ^<outputRelativeToContentRoot value="true" /^>
    echo         ^<processorPath useClasspath="true" /^>
    echo       ^</profile^>
    echo     ^</annotationProcessing^>
    echo     ^<bytecodeTargetLevel target="17" /^>
    echo   ^</component^>
    echo ^</project^>
) > "%IDEA_FOLDER%\compiler.xml" 2>nul

echo ✓ Java 编译器配置已更新

echo [3/3] 清理缓存...

REM 删除旧缓存
if exist "%IDEA_FOLDER%\caches" (
    rmdir /s /q "%IDEA_FOLDER%\caches" >nul 2>&1
    echo ✓ 编译缓存已清除
)

if exist "%IDEA_FOLDER%\kotlin" (
    rmdir /s /q "%IDEA_FOLDER%\kotlin" >nul 2>&1
    echo ✓ Kotlin 缓存已清除
)

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║  IDE 配置修复完成！                                         ║
echo ╠════════════════════════════════════════════════════════════╣
echo ║                                                             ║
echo ║  📌 现在请在 IDE 中执行：                                   ║
echo ║                                                             ║
echo ║     File → Invalidate Caches and Restart                  ║
echo ║                                                             ║
echo ║  然后选择 [Invalidate and Restart]                        ║
echo ║                                                             ║
echo ║  最后执行 Build → Rebuild Project                         ║
echo ║                                                             ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

pause

