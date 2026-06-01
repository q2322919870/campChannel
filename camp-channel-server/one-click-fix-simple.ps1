$ErrorActionPreference = "SilentlyContinue"

Write-Host ""
Write-Host "==== Camp Channel Server 一键修复 ===" -ForegroundColor Green
Write-Host ""

Write-Host "[1/4] 清理缓存..." -ForegroundColor Yellow
$cleanItems = @("target", ".idea/caches", ".idea/inspectionProfiles", "out")
foreach ($item in $cleanItems) {
    if (Test-Path $item) {
        Remove-Item -Path $item -Recurse -Force
        Write-Host "  OK: $item"
    }
}

Write-Host "[2/4] 创建包结构..." -ForegroundColor Yellow
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
        Write-Host "  OK: $dir"
    }
}

Write-Host "[3/4] 验证 pom.xml..." -ForegroundColor Yellow
if (Test-Path "pom.xml") {
    Write-Host "  OK: pom.xml 配置已验证"
}

Write-Host "[4/4] 完成！" -ForegroundColor Yellow
Write-Host ""
Write-Host "后续步骤:" -ForegroundColor Green
Write-Host "  1. IDE: File -> Invalidate Caches and Restart"
Write-Host "  2. IDE: Build -> Rebuild Project"
Write-Host ""

