# ==========================================
# Automated PostgreSQL Backup Script
# ==========================================
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = "E:\cloudops-platform\backups\cloudops_db_$timestamp.dump"

Write-Host ">>> Starting PostgreSQL Backup..." -ForegroundColor Cyan

# Run pg_dump inside container in custom format (-F c)
docker exec cloudops-db pg_dump -U postgres -d cloudops_db -F c -f /tmp/backup.dump

if ($LASTEXITCODE -ne 0) {
    Write-Error "Backup failed inside container."
    exit 1
}

# Copy dump from container to host
docker cp cloudops-db:/tmp/backup.dump $backupFile
docker exec cloudops-db rm /tmp/backup.dump

$fileSize = (Get-Item $backupFile).Length
$hash = (Get-FileHash -Path $backupFile -Algorithm SHA256).Hash

Write-Host ">>> Backup Complete!" -ForegroundColor Green
Write-Host "    File: $backupFile"
Write-Host "    Size: $fileSize bytes"
Write-Host "    SHA256: $hash"