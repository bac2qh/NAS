#!/bin/bash

###############################################
# Find Duplicate Files Report
# Generates report of duplicate files by hash
# User can review and manually move to dup folder
###############################################

# Configuration
SEARCH_DIRS=(
    "/Volumes/NAS_1"
    # Scan entire NAS (excluding some system folders)
)

REPORT_FILE="$HOME/Desktop/duplicates_report_$(date +%Y%m%d_%H%M%S).txt"

# Folders to exclude from scan (already excluded from backup)
EXCLUDE_DIRS=(
    "/Volumes/NAS_1/Torrents"
    "/Volumes/NAS_1/Duplicates"
    "/Volumes/NAS_1/Immich/thumbs"
    "/Volumes/NAS_1/Immich/encoded-video"
    "/Volumes/NAS_1/.Trashes"
    "/Volumes/NAS_1/.Spotlight-V100"
    "/Volumes/NAS_1/.fseventsd"
)

echo "=========================================="
echo "  Duplicate File Finder"
echo "=========================================="
echo ""

# Check if jdupes is installed
if ! command -v jdupes &> /dev/null; then
    echo "❌ jdupes not found. Installing..."
    brew install jdupes
    if [ $? -ne 0 ]; then
        echo "Failed to install jdupes. Please install manually:"
        echo "  brew install jdupes"
        exit 1
    fi
fi

echo "Searching for duplicates in:"
for dir in "${SEARCH_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "  ✅ $dir"
    else
        echo "  ⚠️  $dir (not found, skipping)"
    fi
done
echo ""

echo "Excluding folders:"
for dir in "${EXCLUDE_DIRS[@]}"; do
    echo "  ⊘ $dir"
done
echo ""

echo "⏳ Scanning for duplicates (this may take several minutes)..."
echo "   Finding ALL file types (photos, videos, documents, etc.)"
echo ""

# Build jdupes exclude options
JDUPES_EXCLUDE=""
for exclude_dir in "${EXCLUDE_DIRS[@]}"; do
    JDUPES_EXCLUDE="$JDUPES_EXCLUDE -X dir:$exclude_dir"
done

# Filter by existing directories
EXISTING_DIRS=()
for dir in "${SEARCH_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        EXISTING_DIRS+=("$dir")
    fi
done

if [ ${#EXISTING_DIRS[@]} -eq 0 ]; then
    echo "❌ No directories found to scan!"
    exit 1
fi

# Run jdupes and format output
{
    echo "=========================================="
    echo "DUPLICATE FILES REPORT - ALL FILE TYPES"
    echo "Generated: $(date)"
    echo "=========================================="
    echo ""
    echo "Scanned: ${EXISTING_DIRS[@]}"
    echo "Excluded: ${EXCLUDE_DIRS[@]}"
    echo ""
    echo "Each group below contains duplicate files (same content by hash)."
    echo "Files are grouped together, with file size shown."
    echo ""
    echo "=========================================="
    echo ""

    # Run jdupes with excludes
    # -r = recursive
    # -S = show size
    # -m = don't show files that have no duplicates
    # -X dir:path = exclude directory
    eval jdupes -r -S -m $JDUPES_EXCLUDE "${EXISTING_DIRS[@]}"

    echo ""
    echo "=========================================="
    echo "SUMMARY"
    echo "=========================================="
    echo ""

    # Count duplicate sets
    DUP_SETS=$(eval jdupes -r -m $JDUPES_EXCLUDE "${EXISTING_DIRS[@]}" | grep -c "^$" || echo "0")
    echo "Total duplicate file sets found: $DUP_SETS"
    echo ""

    # Show statistics
    echo "Total files scanned:"
    for dir in "${EXISTING_DIRS[@]}"; do
        COUNT=$(find "$dir" -type f 2>/dev/null | wc -l | tr -d ' ')
        SIZE=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
        echo "  $dir: $COUNT files ($SIZE)"
    done
    echo ""

    echo "=========================================="
    echo "HOW TO USE THIS REPORT"
    echo "=========================================="
    echo ""
    echo "Each group of files listed above are duplicates (same content by hash)."
    echo "This includes ALL file types: photos, videos, documents, music, etc."
    echo ""
    echo "To manually remove duplicates:"
    echo "1. Review each group carefully"
    echo "2. Decide which copy to KEEP (choose best location/name)"
    echo "3. Move ALL OTHER copies to: /Volumes/NAS_1/Duplicates"
    echo ""
    echo "Create duplicates folder:"
    echo "  mkdir -p /Volumes/NAS_1/Duplicates"
    echo ""
    echo "Example: Move duplicate to quarantine"
    echo "  mv '/Volumes/NAS_1/Photos/IMG_1234.jpg' /Volumes/NAS_1/Duplicates/"
    echo "  mv '/Volumes/NAS_1/Documents/report_copy.pdf' /Volumes/NAS_1/Duplicates/"
    echo ""
    echo "After moving all duplicates:"
    echo "  1. Run backup (Duplicates folder is excluded automatically)"
    echo "  2. Verify for a week that nothing is broken"
    echo "  3. Delete Duplicates folder: rm -rf /Volumes/NAS_1/Duplicates"
    echo ""
    echo "Note: /Volumes/NAS_1/Duplicates is already excluded from backup."
    echo ""

} > "$REPORT_FILE"

echo "✅ Report generated!"
echo ""
echo "Report saved to:"
echo "  $REPORT_FILE"
echo ""
echo "Opening report..."
open "$REPORT_FILE"

echo ""
echo "Next steps:"
echo "1. Review the report"
echo "2. Create duplicates folder: mkdir -p /Volumes/NAS_1/Duplicates"
echo "3. Manually move duplicate files to that folder"
echo "4. Update restic_backup.sh to exclude /Volumes/NAS_1/Duplicates"
echo "5. Run backup (duplicates won't be backed up)"
echo ""
