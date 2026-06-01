@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║     Camp Channel Server - 一键完全修复脚本                  ║
echo ║     Complete Fix Script v1.0                               ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

REM 设置项目根目录
set PROJECT_DIR=%~dp0
cd /d "%PROJECT_DIR%"

echo [步骤 1/5] 清理所有缓存和构建文件...
echo.

REM 删除 Maven 构建输出
if exist target (
    echo • 删除 target 目录...
    rmdir /s /q target >nul 2>&1
)

REM 删除 IDE 缓存
if exist .idea\caches (
    echo • 删除 IDE 缓存...
    rmdir /s /q .idea\caches >nul 2>&1
)

if exist .idea\inspectionProfiles (
    echo • 删除 IDE 检查配置缓存...
    rmdir /s /q .idea\inspectionProfiles >nul 2>&1
)

if exist out (
    echo • 删除编译输出目录...
    rmdir /s /q out >nul 2>&1
)

echo ✓ 缓存清理完成
echo.

echo [步骤 2/5] 验证项目结构完整性...
echo.

REM 创建必要的目录结构
set DIRS[0]=src\main\java\com\gdmec\campchannel\mapper
set DIRS[1]=src\main\java\com\gdmec\campchannel\model
set DIRS[2]=src\main\java\com\gdmec\campchannel\entity
set DIRS[3]=src\main\java\com\gdmec\campchannel\service
set DIRS[4]=src\main\java\com\gdmec\campchannel\service\impl
set DIRS[5]=src\main\resources\mapper
set DIRS[6]=target

for /L %%i in (0,1,6) do (
    if not exist "!DIRS[%%i]!" (
        echo • 创建缺失目录: !DIRS[%%i]!
        mkdir "!DIRS[%%i]!" >nul 2>&1
    )
)

echo ✓ 项目结构验证完成
echo.

echo [步骤 3/5] 更新 pom.xml 依赖...
echo.

REM 检查 pom.xml 是否有必要的依赖
findstr /M "spring-boot-starter-data-jpa" pom.xml >nul 2>&1
if errorlevel 1 (
    echo • 注意: 如需使用 JPA，请添加 spring-boot-starter-data-jpa 依赖
)

echo ✓ 依赖检查完成
echo.

echo [步骤 4/5] 清理 Maven 本地仓库（可选但推荐）...
echo.

set M2_REPO=%USERPROFILE%\.m2\repository
if exist "%M2_REPO%" (
    echo ⚠️  要清除 Maven 仓库需要手动删除以下目录：
    echo    %M2_REPO%
    echo.
    echo 可选：复制以下命令手动执行清除
    echo    rmdir /s /q "%M2_REPO%"
    echo.
) else (
    echo ℹ️  Maven 仓库未找到（这很正常）
)

echo [步骤 5/5] 生成修复报告...
echo.

REM 统计项目信息
for /f %%i in ('dir /s /b src\main\java\*.java 2^>nul ^| find /c "java"') do set JAVA_COUNT=%%i

echo ╔════════════════════════════════════════════════════════════╗
echo ║              修复完成！修复报告                             ║
echo ╠════════════════════════════════════════════════════════════╣
echo ║                                                             ║
echo ║  ✓ 已清理所有缓存和构建文件                                ║
echo ║  ✓ 已验证项目结构完整性                                    ║
echo ║  ✓ Java 源代码文件数: %JAVA_COUNT%                              ║
echo ║                                                             ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

echo 📋 接下来的步骤：
echo.
echo 【在 IDE 中执行】
echo   1. File → Invalidate Caches and Restart
echo   2. 选择 [Invalidate and Restart]
echo   3. IDE 重启后右键项目 → Maven → Reload projects
echo   4. Build → Rebuild Project
echo.
echo 【或在命令行执行】
echo   mvn clean install
echo.
echo ✓ 一键修复完成！
echo.
pause

