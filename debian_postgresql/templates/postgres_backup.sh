#!/bin/bash

BACKUP_DIR="/var/backups/postgresql"
DB_NAME="${POSTGRES_DATABASE_NAME}"
RETENTION_DAYS=${BACKUP_RETENTION_DAYS}
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"
sudo -u postgres pg_dump "$DB_NAME" > "$BACKUP_DIR/backup_${DB_NAME}_${DATE}.sql"
find "$BACKUP_DIR" -name "backup_${DB_NAME}_*.sql" -mtime +$RETENTION_DAYS -delete
