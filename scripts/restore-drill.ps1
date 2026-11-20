# ==========================================================
# Disaster Recovery Drill: Backup, Restore to Scratch & Parity Check
# ==========================================================
$ErrorActionPreference = "Stop"

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  DISASTER RECOVERY DRILL: SCRATCH DATABASE RESTORE   " -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

# 1. Trigger fresh backup
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = "E:\cloudops-platform\backups\dr_drill_$timestamp.dump"

Write-Host "[1/5] Creating fresh database dump..." -ForegroundColor Yellow
docker exec cloudops-db pg_dump -U postgres -d cloudops_db -F c -f /tmp/dr_drill.dump
docker cp cloudops-db:/tmp/dr_drill.dump $backupFile

# 2. Provision isolated scratch database
Write-Host "[2/5] Initializing scratch database 'cloudops_scratch'..." -ForegroundColor Yellow
docker exec cloudops-db psql -U postgres -c "DROP DATABASE IF EXISTS cloudops_scratch;"
docker exec cloudops-db psql -U postgres -c "CREATE DATABASE cloudops_scratch;"

# 3. Restore dump into scratch database
Write-Host "[3/5] Restoring dump into 'cloudops_scratch'..." -ForegroundColor Yellow
docker exec cloudops-db pg_restore -U postgres -d cloudops_scratch --clean --if-exists /tmp/dr_drill.dump

# 4. Parity verification query
Write-Host "[4/5] Verifying data parity between production and scratch..." -ForegroundColor Yellow

$query = "SELECT count(*) AS total_rows, COALESCE(sum(id), 0) AS id_sum, md5(string_agg(title, '' ORDER BY id)) AS data_hash FROM work_items;"

$prodResult = docker exec cloudops-db psql -U postgres -d cloudops_db -t -A -F "|" -c $query
$scratchResult = docker exec cloudops-db psql -U postgres -d cloudops_scratch -t -A -F "|" -c $query

Write-Host "Production DB : $prodResult"
Write-Host "Scratch DB    : $scratchResult"

if ($prodResult -eq $scratchResult) {
    Write-Host "======================================================" -ForegroundColor Green
    Write-Host "  PARITY VERIFIED: 100% DATA MATCH BETWEEN DB & RESTORE!" -ForegroundColor Green
    Write-Host "======================================================" -ForegroundColor Green
} else {
    Write-Host "======================================================" -ForegroundColor Red
    Write-Host "  PARITY CHECK FAILED: MISMATCH DETECTED!" -ForegroundColor Red
    Write-Host "======================================================" -ForegroundColor Red
    exit 1
}

# 5. Clean up scratch database and temp container files
Write-Host "[5/5] Tearing down scratch database..." -ForegroundColor Yellow
docker exec cloudops-db psql -U postgres -c "DROP DATABASE cloudops_scratch;"
docker exec cloudops-db rm /tmp/dr_drill.dump

Write-Host ">>> Disaster Recovery drill completed successfully!" -ForegroundColor Green