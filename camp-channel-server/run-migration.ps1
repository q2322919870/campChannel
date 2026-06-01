# Database Migration Script for Camp Channel
# This script adds the missing mentioned_users column to the post table

$mysqlPath = "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"

# Check if MySQL exists at default location
if (-Not (Test-Path $mysqlPath)) {
    Write-Host "MySQL not found at default location. Trying to find mysql.exe..." -ForegroundColor Yellow
    
    # Try common locations
    $possiblePaths = @(
        "C:\xampp\mysql\bin\mysql.exe",
        "C:\wamp64\bin\mysql\mysql8.0.27\bin\mysql.exe",
        "C:\mysql\bin\mysql.exe"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $mysqlPath = $path
            break
        }
    }
}

if (-Not (Test-Path $mysqlPath)) {
    Write-Host "ERROR: MySQL executable not found!" -ForegroundColor Red
    Write-Host "Please install MySQL or update the path in this script." -ForegroundColor Red
    exit 1
}

Write-Host "Found MySQL at: $mysqlPath" -ForegroundColor Green
Write-Host "Running database migration..." -ForegroundColor Cyan

# SQL command to add the mentioned_users column
$sql = "ALTER TABLE camp_channel.post ADD COLUMN IF NOT EXISTS mentioned_users VARCHAR(500) AFTER topic;"

# Execute the SQL
try {
    $process = Start-Process -FilePath $mysqlPath `
        -ArgumentList "-u", "root", "-pq871651480", "-e", $sql `
        -NoNewWindow `
        -Wait `
        -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Host "`nMigration completed successfully!" -ForegroundColor Green
        Write-Host "The mentioned_users column has been added to the post table." -ForegroundColor Green
    } else {
        Write-Host "`nMigration failed with exit code: $($process.ExitCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "`nError executing migration: $_" -ForegroundColor Red
}
