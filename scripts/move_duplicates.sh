#!/bin/bash

###############################################
# Move Duplicate Files Script
# Processes duplicate report and moves files
# Preserves directory structure under Duplicates/
###############################################

# Configuration
BASE_DIR="/Volumes/NAS_1"
DUPLICATES_DIR="$BASE_DIR/Duplicates"
LOG_FILE="$HOME/Library/Logs/move_duplicates.log"

# Parse arguments
DRY_RUN=false
REPORT_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            REPORT_FILE="$1"
            shift
            ;;
    esac
done

# Validate report file
if [ -z "$REPORT_FILE" ]; then
    echo "Usage: $0 [--dry-run] <report_file>"
    echo ""
    echo "Example:"
    echo "  $0 --dry-run ~/Documents/NAS_duplicate_reports/duplicates_fixed_20260121.txt"
    echo "  $0 ~/Documents/NAS_duplicate_reports/duplicates_fixed_20260121.txt"
    exit 1
fi

if [ ! -f "$REPORT_FILE" ]; then
    echo "❌ Report file not found: $REPORT_FILE"
    exit 1
fi

# Check if NAS is mounted
if [ ! -d "$BASE_DIR" ]; then
    echo "❌ NAS not mounted: $BASE_DIR"
    exit 1
fi

echo "=========================================="
echo "  Duplicate File Mover"
echo "=========================================="
echo ""
echo "Report: $REPORT_FILE"
echo "Base: $BASE_DIR"
echo "Destination: $DUPLICATES_DIR"
if [ "$DRY_RUN" = true ]; then
    echo "Mode: DRY RUN (no files will be moved)"
else
    echo "Mode: LIVE (files will be moved)"
fi
echo ""

# Log start
{
    echo "=========================================="
    echo "$(date): Starting duplicate move"
    echo "Report: $REPORT_FILE"
    echo "Dry run: $DRY_RUN"
    echo "=========================================="
} >> "$LOG_FILE"

# Extract duplicate file paths
# Format: "← DUPLICATE (can move)" from both find_duplicates.sh and reparse_duplicates.sh
DUPLICATES=$(grep "← DUPLICATE (can move)" "$REPORT_FILE" | sed -E 's/^\[[^]]+\] (.+)  ← DUPLICATE \(can move\)$/\1/')

# Count total
TOTAL=$(echo "$DUPLICATES" | grep -c .)
if [ "$TOTAL" -eq 0 ]; then
    echo "No duplicate files found in report."
    exit 0
fi

echo "Found $TOTAL duplicate files to move"
echo ""

MOVED=0
FAILED=0
SKIPPED=0

while IFS= read -r filepath; do
    # Skip empty lines
    [ -z "$filepath" ] && continue

    # Check if file exists
    if [ ! -f "$filepath" ]; then
        echo "⚠️  SKIP (not found): $filepath"
        echo "$(date): SKIP - File not found: $filepath" >> "$LOG_FILE"
        ((SKIPPED++))
        continue
    fi

    # Strip /Volumes/NAS_1/ prefix and build destination path
    if [[ "$filepath" =~ ^/Volumes/NAS_1/(.+)$ ]]; then
        relative_path="${BASH_REMATCH[1]}"
        dest_path="$DUPLICATES_DIR/$relative_path"
        dest_dir=$(dirname "$dest_path")
    else
        echo "⚠️  SKIP (invalid path): $filepath"
        echo "$(date): SKIP - Path doesn't start with /Volumes/NAS_1/: $filepath" >> "$LOG_FILE"
        ((SKIPPED++))
        continue
    fi

    # Create destination directory
    if [ "$DRY_RUN" = true ]; then
        echo "🔍 DRY RUN: Would move"
        echo "   From: $filepath"
        echo "   To:   $dest_path"
        ((MOVED++))
    else
        # Create directory
        if ! mkdir -p "$dest_dir"; then
            echo "❌ FAIL (mkdir): $dest_dir"
            echo "$(date): FAIL - Could not create directory: $dest_dir" >> "$LOG_FILE"
            ((FAILED++))
            continue
        fi

        # Move file
        if mv "$filepath" "$dest_path"; then
            echo "✅ Moved: $relative_path"
            echo "$(date): SUCCESS: $filepath -> $dest_path" >> "$LOG_FILE"
            ((MOVED++))
        else
            echo "❌ FAIL: $filepath"
            echo "$(date): FAIL - Move failed: $filepath -> $dest_path" >> "$LOG_FILE"
            ((FAILED++))
        fi
    fi

done <<< "$DUPLICATES"

echo ""
echo "=========================================="
echo "SUMMARY"
echo "=========================================="
echo "Total duplicates: $TOTAL"
if [ "$DRY_RUN" = true ]; then
    echo "Would move: $MOVED"
else
    echo "Successfully moved: $MOVED"
fi
echo "Skipped: $SKIPPED"
echo "Failed: $FAILED"
echo ""

# Log summary
{
    echo "Summary: Total=$TOTAL, Moved=$MOVED, Skipped=$SKIPPED, Failed=$FAILED"
    echo "$(date): Duplicate move finished"
    echo "=========================================="
    echo ""
} >> "$LOG_FILE"

if [ "$DRY_RUN" = true ]; then
    echo "This was a DRY RUN. No files were moved."
    echo "To actually move files, run without --dry-run flag."
    echo ""
fi

if [ "$FAILED" -gt 0 ]; then
    echo "⚠️  Some moves failed. Check log: $LOG_FILE"
    exit 1
fi

if [ "$DRY_RUN" = false ] && [ "$MOVED" -gt 0 ]; then
    echo "✅ Done! Files moved to: $DUPLICATES_DIR"
    echo ""
    echo "Next steps:"
    echo "1. Run backup (Duplicates folder is excluded automatically)"
    echo "2. Verify for a week that nothing is broken"
    echo "3. Delete: rm -rf $DUPLICATES_DIR"
fi
echo ""
