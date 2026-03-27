#!/bin/bash
# Database backup script for Stop & Dance production
# Run daily via cron: 0 2 * * * /path/to/backup-db.sh

set -e

# Configuration
BACKUP_DIR="${BACKUP_DIR:-/home/dang/backups/stop-and-dance}"
RETENTION_DAYS=30
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/stopanddance_$TIMESTAMP.sql.gz"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Backup database from Docker container
echo "[$(date)] Starting database backup..."
docker compose exec -T db pg_dump -U stopanddance stopanddance_production | gzip > "$BACKUP_FILE"

# Verify backup was created
if [ -f "$BACKUP_FILE" ]; then
    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "[$(date)] Backup completed: $BACKUP_FILE ($SIZE)"
else
    echo "[$(date)] ERROR: Backup failed!"
    exit 1
fi

# Delete old backups
echo "[$(date)] Cleaning up old backups (keeping last $RETENTION_DAYS days)..."
find "$BACKUP_DIR" -name "stopanddance_*.sql.gz" -mtime +$RETENTION_DAYS -delete

echo "[$(date)] Backup process completed successfully"
