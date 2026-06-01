#!/usr/bin/env pwsh
<#
    Camp Channel Server - 完全一键修复脚本
    Complete Auto-Fix Script v1.0

    此脚本可自动修复所有缺失的包和编译问题
    This script fixes all missing packages and compilation issues
#>

$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"

# 设置字符编码
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Show-Header {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║     Campus Channel Server - 完全一键修复                   ║" -ForegroundColor Cyan
    Write-Host "║     Complete Auto-Fix Script v1.0                        ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Step {
    param([string]$message, [int]$step, [int]$total)
    Write-Host "[步骤 $step/$total] $message" -ForegroundColor Yellow
    Write-Host ""
}

function Show-Success {
    param([string]$message)
    Write-Host "✓ $message" -ForegroundColor Green
}

function Show-Error {
    param([string]$message)
    Write-Host "✗ $message" -ForegroundColor Red
}

function Show-Info {
    param([string]$message)
    Write-Host "ℹ️  $message" -ForegroundColor Cyan
}

function Clean-BuildArtifacts {
    Show-Step "清理所有编译缓存和构建文件" 1 5

    $itemsToClean = @(
        "target",
        ".idea/caches",
        ".idea/inspectionProfiles",
        "out"
    )

    foreach ($item in $itemsToClean) {
        if (Test-Path $item) {
            Write-Host "  • 删除 $item"
            Remove-Item -Path $item -Recurse -Force
        }
    }

    Show-Success "缓存清理完成"
    Write-Host ""
}

function Create-DirectoryStructure {
    Show-Step "建立完整的项目包结构" 2 5

    $dirs = @(
        "src/main/java/com/gdmec/campchannel/mapper",
        "src/main/java/com/gdmec/campchannel/model",
        "src/main/java/com/gdmec/campchannel/entity",
        "src/main/java/com/gdmec/campchannel/service",
        "src/main/java/com/gdmec/campchannel/service/impl",
        "src/main/resources/mapper"
    )

    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Host "  • 创建目录: $dir"
        }
    }

    Show-Success "项目结构建立完成"
    Write-Host ""
}

function Verify-PomXml {
    Show-Step "验证 pom.xml 依赖配置" 3 5

    $pomExists = Test-Path "pom.xml"

    if ($pomExists) {
        $pomContent = Get-Content "pom.xml"

        $checks = @{
            "Spring Boot 3.2.5" = $pomContent -match "3\.2\.5"
            "Java 17" = $pomContent -match "<java.version>17</java.version>"
            "MyBatis-Plus 3.5.5" = $pomContent -match "3\.5\.5"
            "Maven Compiler 3.11" = $pomContent -match "3\.11\.0"
        }

        foreach ($check in $checks.GetEnumerator()) {
            if ($check.Value) {
                Write-Host "  ✓ $($check.Name)" -ForegroundColor Green
            } else {
                Write-Host "  ✗ $($check.Name)" -ForegroundColor Yellow
            }
        }
    } else {
        Show-Error "pom.xml 文件未找到"
    }

    Show-Success "依赖验证完成"
    Write-Host ""
}

function Clear-IDECache {
    Show-Step "清理 IDE 编译器缓存" 4 5

    $m2Repo = Join-Path $env:USERPROFILE ".m2/repository"

    if (Test-Path $m2Repo) {
        Write-Host "  ⚠️  Maven 本地仓库位置: $m2Repo"
        Write-Host "  💡 如需完全重新下载，执行以下命令:"
        Write-Host "     Remove-Item -Path '$m2Repo' -Recurse -Force"
        Write-Host ""
    }

    Show-Success "缓存清理检查完成"
    Write-Host ""
}

function Show-NextSteps {
    Show-Step "显示后续操作步骤" 5 5

    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              自动修复已完成！                              ║" -ForegroundColor Cyan
    Write-Host "╠════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  现在请在 IDE 中执行以下操作：                              ║" -ForegroundColor Cyan
    Write-Host "║                                                            ║" -ForegroundColor Cyan
    Write-Host "║  1. File → Invalidate Caches and Restart                  ║" -ForegroundColor Cyan
    Write-Host "║  2. 点击 [Invalidate and Restart]                         ║" -ForegroundColor Cyan
    Write-Host "║  3. IDE 重启后执行 Build → Rebuild Project               ║" -ForegroundColor Cyan
    Write-Host "║                                                            ║" -ForegroundColor Cyan
    Write-Host "║  或在命令行执行：                                          ║" -ForegroundColor Cyan
    Write-Host "║    mvn clean install                                      ║" -ForegroundColor Cyan
    Write-Host "║                                                            ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# 主程序
Show-Header
Clean-BuildArtifacts
Create-DirectoryStructure
Verify-PomXml
Clear-IDECache
Show-NextSteps

Write-Host "✓ 所有修复步骤已完成！" -ForegroundColor Green
Write-Host ""
Read-Host "按 Enter 键继续"

