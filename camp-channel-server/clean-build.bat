@echo off
echo ============================================
echo 清理项目缓存和编译
echo ============================================
echo.

REM 删除IDE缓存
echo 正在删除IDE缓存目录...
if exist ".idea\caches" rmdir /s /q ".idea\caches"
if exist ".idea\inspectionProfiles" rmdir /s /q ".idea\inspectionProfiles"
if exist "out" rmdir /s /q "out"

REM 删除构建输出
echo 正在删除构建输出目录...
if exist "target" rmdir /s /q "target"

echo.
echo ============================================
echo 清理完成！
echo ============================================
echo.
echo 您现在可以在IDE中：
echo 1. File -> Invalidate Caches and Restart...
echo 2. 或者在命令行运行: mvn clean install
echo ============================================
pause

