#!/bin/bash

#############################################
# restic Backup Script
# Backs up NAS_1 to NAS_Backup using restic
#############################################

# Configuration
RESTIC_REPO="/Volumes/NAS_Backup/restic-repo"
SOURCE="/Volumes/NAS_1"
RESTIC_PASSWORD_FILE="$HOME/.restic-password"
LOG_FILE="$HOME/Library/Logs/restic_backup.log"

# Export password
export RESTIC_PASSWORD_FILE

# Check if source exists
if [ ! -d "$SOURCE" ]; then
    echo "$(date): ERROR - Source $SOURCE not found" >> "$LOG_FILE"
    exit 1
fi

# Check if backup drive mounted
if [ ! -d "/Volumes/NAS_Backup" ]; then
    echo "$(date): ERROR - Backup drive not mounted" >> "$LOG_FILE"
    exit 1
fi

# Check if restic repo exists
if [ ! -d "$RESTIC_REPO" ]; then
    echo "$(date): ERROR - restic repository not found at $RESTIC_REPO" >> "$LOG_FILE"
    echo "Run: restic init -r $RESTIC_REPO" >> "$LOG_FILE"
    exit 1
fi

echo "========================================" >> "$LOG_FILE"
echo "$(date): Starting restic backup" >> "$LOG_FILE"

# Run backup
restic -r "$RESTIC_REPO" backup "$SOURCE" \
    --exclude-caches \
    --exclude='*.DS_Store' \
    --exclude='*.Spotlight-*' \
    --exclude='*.Trashes' \
    --exclude='*.fseventsd' \
    --exclude='*.TemporaryItems' \
    --exclude='/Volumes/NAS_1/Torrents' \
    --exclude='/Volumes/NAS_1/Immich/thumbs' \
    --exclude='/Volumes/NAS_1/Immich/encoded-video' \
    >> "$LOG_FILE" 2>&1

BACKUP_STATUS=$?

if [ $BACKUP_STATUS -eq 0 ]; then
    echo "$(date): Backup completed successfully" >> "$LOG_FILE"
else
    echo "$(date): ERROR - Backup failed with status $BACKUP_STATUS" >> "$LOG_FILE"
    exit $BACKUP_STATUS
fi

# Cleanup old snapshots (weekly backups: keep 8 weekly, 12 monthly)
echo "$(date): Pruning old snapshots..." >> "$LOG_FILE"
restic -r "$RESTIC_REPO" forget \
    --keep-weekly 8 \
    --keep-monthly 12 \
    --prune \
    >> "$LOG_FILE" 2>&1

# Show repository stats
echo "$(date): Repository statistics:" >> "$LOG_FILE"
restic -r "$RESTIC_REPO" stats --mode raw-data >> "$LOG_FILE" 2>&1

echo "$(date): Backup process finished" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"
