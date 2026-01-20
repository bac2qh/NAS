#!/bin/bash

# Automated backup script for NAS
# Syncs data from primary NAS drive to backup drive

# Configuration
SOURCE="/Volumes/NAS_Primary/Shared"
BACKUP="/Volumes/NAS_Backup/Mirror_Backup"
LOG_DIR="$HOME/Library/Logs"
LOG_FILE="$LOG_DIR/nas_backup.log"
EMAIL_ON_ERROR=false  # Set to true if you want email notifications
EMAIL=""              # Add your email if EMAIL_ON_ERROR=true

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to send error notification (optional)
send_error_notification() {
    if [ "$EMAIL_ON_ERROR" = true ] && [ -n "$EMAIL" ]; then
        echo "Backup failed on $(date)" | mail -s "NAS Backup Error" "$EMAIL"
    fi
    # macOS notification
    osascript -e "display notification \"Backup failed. Check log at $LOG_FILE\" with title \"NAS Backup Error\""
}

# Function to send success notification
send_success_notification() {
    osascript -e "display notification \"Backup completed successfully\" with title \"NAS Backup\""
}

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Start backup
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  NAS Backup Script${NC}"
echo -e "${GREEN}======================================${NC}"
log_message "=== Backup started ==="

# Check if source exists
if [ ! -d "$SOURCE" ]; then
    echo -e "${RED}✗ Error: Source directory not found: $SOURCE${NC}"
    log_message "ERROR: Source directory not found: $SOURCE"
    send_error_notification
    exit 1
fi

# Check if backup drive is mounted
BACKUP_VOLUME="/Volumes/NAS_Backup"
if [ ! -d "$BACKUP_VOLUME" ]; then
    echo -e "${RED}✗ Error: Backup drive not mounted: $BACKUP_VOLUME${NC}"
    log_message "ERROR: Backup drive not mounted: $BACKUP_VOLUME"
    send_error_notification
    exit 1
fi

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP"

# Show what will be backed up
echo ""
echo "Source: $SOURCE"
echo "Destination: $BACKUP"
echo ""

# Calculate source size
echo "Calculating source size..."
SOURCE_SIZE=$(du -sh "$SOURCE" 2>/dev/null | cut -f1)
echo "Source size: $SOURCE_SIZE"
log_message "Source size: $SOURCE_SIZE"

# Check available space on backup drive
BACKUP_AVAIL=$(df -h "$BACKUP_VOLUME" | tail -1 | awk '{print $4}')
echo "Backup drive available: $BACKUP_AVAIL"
log_message "Backup drive available: $BACKUP_AVAIL"
echo ""

# Perform backup using rsync
echo "Starting rsync backup..."
echo -e "${YELLOW}This may take a while...${NC}"
echo ""

log_message "Starting rsync..."

# Rsync with progress, archive mode, and deletion of files no longer in source
rsync -avh --delete \
  --exclude=".DS_Store" \
  --exclude="._*" \
  --exclude=".Trashes" \
  --exclude=".Spotlight-V100" \
  --exclude=".fseventsd" \
  --progress \
  --stats \
  "$SOURCE/" "$BACKUP/" 2>&1 | tee -a "$LOG_FILE"

# Check rsync exit status
RSYNC_EXIT=$?

echo ""
if [ $RSYNC_EXIT -eq 0 ]; then
    echo -e "${GREEN}✓ Backup completed successfully!${NC}"
    log_message "=== Backup completed successfully ==="

    # Calculate backup size
    BACKUP_SIZE=$(du -sh "$BACKUP" 2>/dev/null | cut -f1)
    echo "Backup size: $BACKUP_SIZE"
    log_message "Backup size: $BACKUP_SIZE"

    send_success_notification
    exit 0
else
    echo -e "${RED}✗ Backup failed with error code: $RSYNC_EXIT${NC}"
    log_message "ERROR: Backup failed with exit code: $RSYNC_EXIT"
    send_error_notification
    exit $RSYNC_EXIT
fi
