#!/bin/bash
set -e

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="$(dirname "$0")/../backups"
BACKUP_FILE="${BACKUP_DIR}/cloudops_db_${TIMESTAMP}.dump"

mkdir -p "$BACKUP_DIR"

echo ">>> Starting PostgreSQL Backup..."
docker exec cloudops-db pg_dump -U postgres -d cloudops_db -F c -f /tmp/backup.dump
docker cp cloudops-db:/tmp/backup.dump "$BACKUP_FILE"
docker exec cloudops-db rm /tmp/backup.dump

echo ">>> Backup Complete: $BACKUP_FILE"