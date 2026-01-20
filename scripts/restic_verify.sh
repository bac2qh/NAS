#!/bin/bash

#############################################
# restic Monthly Verification Script
# Verifies backup integrity
#############################################

# Configuration
RESTIC_REPO="/Volumes/NAS_Backup/restic-repo"
RESTIC_PASSWORD_FILE="$HOME/.restic-password"
LOG_FILE="$HOME/Library/Logs/restic_verify.log"

# Export password
export RESTIC_PASSWORD_FILE

# Check if backup drive mounted
if [ ! -d "/Volumes/NAS_Backup" ]; then
    echo "$(date): ERROR - Backup drive not mounted" >> "$LOG_FILE"
    exit 1
fi

echo "========================================" >> "$LOG_FILE"
echo "$(date): Starting restic verification" >> "$LOG_FILE"

# Check repository integrity
echo "$(date): Checking repository structure..." >> "$LOG_FILE"
restic -r "$RESTIC_REPO" check >> "$LOG_FILE" 2>&1
CHECK_STATUS=$?

if [ $CHECK_STATUS -eq 0 ]; then
    echo "$(date): Repository structure OK" >> "$LOG_FILE"
else
    echo "$(date): ERROR - Repository check failed" >> "$LOG_FILE"
    exit $CHECK_STATUS
fi

# Read data verification (slower, thorough)
echo "$(date): Verifying all data chunks (this may take a while)..." >> "$LOG_FILE"
restic -r "$RESTIC_REPO" check --read-data >> "$LOG_FILE" 2>&1
READ_STATUS=$?

if [ $READ_STATUS -eq 0 ]; then
    echo "$(date): All data verified successfully" >> "$LOG_FILE"
else
    echo "$(date): ERROR - Data verification failed" >> "$LOG_FILE"
    exit $READ_STATUS
fi

# List snapshots
echo "$(date): Current snapshots:" >> "$LOG_FILE"
restic -r "$RESTIC_REPO" snapshots >> "$LOG_FILE" 2>&1

# Show statistics
echo "$(date): Repository statistics:" >> "$LOG_FILE"
restic -r "$RESTIC_REPO" stats >> "$LOG_FILE" 2>&1

echo "$(date): Verification completed successfully" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"
