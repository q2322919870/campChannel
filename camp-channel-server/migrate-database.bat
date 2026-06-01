@echo off
chcp 65001 >nul
echo ========================================
echo   Camp Channel Database Migration Tool
echo ========================================
echo.
echo This script will add the missing channel_id column to the gallery table.
echo.
echo Please ensure:
echo   1. MySQL is running
echo   2. You know your MySQL root password
echo.
pause

echo.
echo Running database migration...
echo.

mysql -u root -p camp_channel < src\main\resources\db\migration-fix.sql

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo   Migration completed successfully!
    echo ========================================
    echo.
    echo You can now restart the backend server.
) else (
    echo.
    echo ========================================
    echo   Migration failed!
    echo ========================================
    echo.
    echo Please check:
    echo   1. MySQL is running
    echo   2. Database 'camp_channel' exists
    echo   3. You entered the correct password
    echo.
    echo Or run the SQL manually:
    echo   ALTER TABLE gallery ADD COLUMN channel_id BIGINT DEFAULT 0 AFTER user_id;
)

echo.
pause
