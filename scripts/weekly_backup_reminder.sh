#!/bin/bash

###############################################
# Weekly Backup Reminder & Helper Script
# Run this every Sunday for your weekly backup
###############################################

echo "=========================================="
echo "  Weekly NAS Backup - WD Elements Drive"
echo "=========================================="
echo ""

# Check if backup drive is mounted
if [ ! -d "/Volumes/NAS_Backup" ]; then
    echo "❌ Backup drive NOT mounted"
    echo ""
    echo "Please:"
    echo "  1. Plug in your WD Elements 16TB backup drive"
    echo "  2. Wait for it to mount (you'll see /Volumes/NAS_Backup)"
    echo "  3. Run this script again"
    echo ""
    exit 1
fi

echo "✅ Backup drive found: /Volumes/NAS_Backup"
echo ""

# Check if primary drive exists
if [ ! -d "/Volumes/NAS_1" ]; then
    echo "❌ Primary NAS drive NOT found at /Volumes/NAS_1"
    echo ""
    exit 1
fi

echo "✅ Primary NAS drive found: /Volumes/NAS_1"
echo ""

# Check if restic repo exists
if [ ! -d "/Volumes/NAS_Backup/restic-repo" ]; then
    echo "❌ restic repository not found"
    echo ""
    echo "Initialize with:"
    echo "  restic init -r /Volumes/NAS_Backup/restic-repo"
    echo ""
    exit 1
fi

echo "✅ restic repository found"
echo ""

# Estimate backup size
echo "Checking data size..."
DATA_SIZE=$(du -sh /Volumes/NAS_1 2>/dev/null | awk '{print $1}')
echo "Primary NAS size: $DATA_SIZE"
echo ""

# Estimate time
echo "⏱️  Estimated backup time: 2-3 hours for first backup"
echo "   (Subsequent backups much faster due to deduplication)"
echo ""

# Confirm
read -p "Start backup now? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Backup cancelled."
    exit 0
fi

echo ""
echo "🚀 Starting backup..."
echo "   (This will run in the background, you can use your Mac)"
echo ""

# Change to script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Run backup
./scripts/restic_backup.sh

BACKUP_STATUS=$?

echo ""
if [ $BACKUP_STATUS -eq 0 ]; then
    echo "✅ Backup completed successfully!"
    echo ""

    # Show snapshots
    echo "Recent snapshots:"
    export RESTIC_PASSWORD_FILE="$HOME/.restic-password"
    restic -r /Volumes/NAS_Backup/restic-repo snapshots --compact | tail -5
    echo ""

    # Show repo stats
    echo "Repository statistics:"
    restic -r /Volumes/NAS_Backup/restic-repo stats --mode raw-data
    echo ""

    echo "=========================================="
    echo "  You can now safely eject the backup drive"
    echo "=========================================="
    echo ""
    echo "To eject:"
    echo "  diskutil eject /Volumes/NAS_Backup"
    echo ""
    echo "Or use Finder: Right-click NAS_Backup → Eject"
    echo ""
    echo "Store the drive in a safe location (separate from Mac)"
    echo ""
else
    echo "❌ Backup failed! Check logs:"
    echo "   tail ~/Library/Logs/restic_backup.log"
    echo ""
    exit $BACKUP_STATUS
fi
