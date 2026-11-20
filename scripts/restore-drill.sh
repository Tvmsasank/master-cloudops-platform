#!/bin/bash
set -e

echo "======================================================"
echo "  DISASTER RECOVERY DRILL: SCRATCH DATABASE RESTORE   "
echo "======================================================"

BACKUP_DIR="$(dirname "$0")/../backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/dr_drill_${TIMESTAMP}.dump"
mkdir -p "$BACKUP_DIR"

echo "[1/5] Creating database dump..."
docker exec cloudops-db pg_dump -U postgres -d cloudops_db -F c -f /tmp/dr_drill.dump
docker cp cloudops-db:/tmp/dr_drill.dump "$BACKUP_FILE"

echo "[2/5] Creating scratch database..."
docker exec cloudops-db psql -U postgres -c "DROP DATABASE IF EXISTS cloudops_scratch;"
docker exec cloudops-db psql -U postgres -c "CREATE DATABASE cloudops_scratch;"

echo "[3/5] Restoring into scratch database..."
docker exec cloudops-db pg_restore -U postgres -d cloudops_scratch --clean --if-exists /tmp/dr_drill.dump

echo "[4/5] Checking data parity..."
QUERY="SELECT count(*) || '|' || COALESCE(sum(id), 0) || '|' || md5(string_agg(title, '' ORDER BY id)) FROM work_items;"
PROD_HASH=$(docker exec cloudops-db psql -U postgres -d cloudops_db -t -A -c "$QUERY")
SCRATCH_HASH=$(docker exec cloudops-db psql -U postgres -d cloudops_scratch -t -A -c "$QUERY")

echo "Production DB : $PROD_HASH"
echo "Scratch DB    : $SCRATCH_HASH"

if [ "$PROD_HASH" = "$SCRATCH_HASH" ]; then
    echo "======================================================"
    echo "  PARITY VERIFIED: 100% DATA MATCH BETWEEN DB & RESTORE!"
    echo "======================================================"
else
    echo "ERROR: Data mismatch detected!"
    exit 1
fi

echo "[5/5] Cleaning up scratch database..."
docker exec cloudops-db psql -U postgres -c "DROP DATABASE cloudops_scratch;"
docker exec cloudops-db rm /tmp/dr_drill.dump

echo ">>> Disaster Recovery drill completed successfully!"