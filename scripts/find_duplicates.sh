#!/bin/bash

###############################################
# Find Duplicate Files Report (using rdfind)
# Generates report of duplicate files by hash
# User can review and manually move to dup folder
###############################################

SCAN_DIR="/Volumes/NAS_1"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_DIR="$HOME/Documents/NAS_duplicate_reports"
RDFIND_OUTPUT="$OUTPUT_DIR/rdfind_raw_${TIMESTAMP}.txt"
REPORT_FILE="$OUTPUT_DIR/duplicates_report_${TIMESTAMP}.txt"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Folders to exclude from scan (already excluded from backup)
EXCLUDE_PATTERNS=(
    "Torrents"
    "Duplicates"
    "Immich/thumbs"
    "Immich/encoded-video"
    ".Trashes"
    ".Spotlight-V100"
    ".fseventsd"
    ".TemporaryItems"
)

echo "=========================================="
echo "  Duplicate File Finder (rdfind)"
echo "=========================================="
echo ""

# Check if rdfind is installed
if ! command -v rdfind &> /dev/null; then
    echo "❌ rdfind not found. Installing..."
    brew install rdfind
    if [ $? -ne 0 ]; then
        echo "Failed to install rdfind. Please install manually:"
        echo "  brew install rdfind"
        exit 1
    fi
fi

# Check if scan directory exists
if [ ! -d "$SCAN_DIR" ]; then
    echo "❌ Directory not found: $SCAN_DIR"
    exit 1
fi

echo "Scanning: $SCAN_DIR"
echo ""
echo "Will exclude folders matching:"
for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    echo "  ⊘ */$pattern/*"
done
echo ""
echo "⏳ Finding duplicates (this may take 5-15 minutes)..."
echo "   Scanning ALL file types by hash (MD5)"
echo ""

# Run rdfind in dry-run mode
# -dryrun true = don't modify anything
# -makehardlinks false = just report, don't link
# -makeresultsfile true = create results.txt
# -outputname = where to save results

cd "$SCAN_DIR" || exit 1

rdfind -dryrun true \
    -makehardlinks false \
    -makeresultsfile true \
    -outputname "$RDFIND_OUTPUT" \
    "$SCAN_DIR" 2>&1

RDFIND_STATUS=$?

if [ $RDFIND_STATUS -ne 0 ]; then
    echo ""
    echo "❌ rdfind scan failed with status $RDFIND_STATUS"
    echo ""
    echo "Common issues:"
    echo "  - Permission denied: Check NAS drive is writable"
    echo "  - Disk not mounted: Verify /Volumes/NAS_1 exists"
    echo "  - Out of space: Check disk space in ~/Documents"
    echo ""
    echo "Partial results may be at:"
    echo "  $RDFIND_OUTPUT"
    echo ""
    exit 1
fi

# Check if output file was created
if [ ! -f "$RDFIND_OUTPUT" ]; then
    echo ""
    echo "❌ rdfind output file not created!"
    echo "Expected: $RDFIND_OUTPUT"
    echo ""
    echo "Check ~/Documents permissions"
    exit 1
fi

# Check if output file has content
if [ ! -s "$RDFIND_OUTPUT" ]; then
    echo ""
    echo "⚠️  rdfind output file is empty"
    echo "This might mean no files were found or an error occurred"
    echo ""
    echo "Check: $RDFIND_OUTPUT"
    exit 1
fi

echo ""
echo "✅ Scan complete! Parsing results..."
echo ""

# Parse rdfind output and create readable report
{
    echo "=========================================="
    echo "DUPLICATE FILES REPORT - ALL FILE TYPES"
    echo "Generated: $(date)"
    echo "=========================================="
    echo ""
    echo "Scanned: $SCAN_DIR"
    echo "Excluded patterns: ${EXCLUDE_PATTERNS[@]}"
    echo ""
    echo "Raw rdfind output: $RDFIND_OUTPUT"
    echo ""
    echo "=========================================="
    echo "DUPLICATE FILE GROUPS"
    echo "=========================================="
    echo ""
    echo "Format: [SIZE] ORIGINAL"
    echo "        [SIZE] DUPLICATE (can be moved)"
    echo ""
    echo "=========================================="
    echo ""

    # Parse rdfind results.txt
    # Skip commented lines and parse duplicate groups
    current_id=""
    group_size=""
    files_in_group=()

    while IFS= read -r line; do
        # Skip comments
        [[ "$line" =~ ^# ]] && continue

        # Parse line: DUPTYPE id depth size device inode priority name
        if [[ "$line" =~ ^DUPTYPE_([A-Z_]+)[[:space:]]+([0-9]+)[[:space:]]+[0-9]+[[:space:]]+([0-9]+)[[:space:]].*[[:space:]](.+)$ ]]; then
            duptype="${BASH_REMATCH[1]}"
            id="${BASH_REMATCH[2]}"
            size="${BASH_REMATCH[3]}"
            filepath="${BASH_REMATCH[4]}"

            # Check if file matches exclude patterns
            skip=0
            for pattern in "${EXCLUDE_PATTERNS[@]}"; do
                if [[ "$filepath" == *"/$pattern"* ]] || [[ "$filepath" == *"/$pattern/"* ]]; then
                    skip=1
                    break
                fi
            done

            [ $skip -eq 1 ] && continue

            # Convert size to human readable
            if [ "$size" -ge 1073741824 ]; then
                human_size=$(awk "BEGIN {printf \"%.2f GB\", $size/1073741824}")
            elif [ "$size" -ge 1048576 ]; then
                human_size=$(awk "BEGIN {printf \"%.2f MB\", $size/1048576}")
            elif [ "$size" -ge 1024 ]; then
                human_size=$(awk "BEGIN {printf \"%.2f KB\", $size/1024}")
            else
                human_size="${size} B"
            fi

            # New group or continuation?
            if [ "$id" != "$current_id" ]; then
                # Print previous group if it had duplicates
                if [ "${#files_in_group[@]}" -gt 1 ]; then
                    for file_entry in "${files_in_group[@]}"; do
                        echo "$file_entry"
                    done
                    echo ""
                fi

                # Start new group
                current_id="$id"
                group_size="$human_size"
                files_in_group=()
            fi

            # Add file to current group
            if [ "$duptype" = "FIRST_OCCURRENCE" ]; then
                files_in_group+=("[$group_size] $filepath  ← ORIGINAL (keep this)")
            else
                files_in_group+=("[$group_size] $filepath  ← DUPLICATE (can move)")
            fi
        fi
    done < "$RDFIND_OUTPUT"

    # Print last group
    if [ "${#files_in_group[@]}" -gt 1 ]; then
        for file_entry in "${files_in_group[@]}"; do
            echo "$file_entry"
        done
        echo ""
    fi

    echo "=========================================="
    echo "SUMMARY"
    echo "=========================================="
    echo ""

    # Count duplicate groups (groups with DUPTYPE_WITHIN_SAME_TREE)
    DUP_COUNT=$(grep -c "DUPTYPE_WITHIN_SAME_TREE" "$RDFIND_OUTPUT" || echo "0")
    echo "Total duplicate files found: $DUP_COUNT"
    echo ""

    # Calculate space that can be saved
    TOTAL_WASTED=$(awk '/DUPTYPE_WITHIN_SAME_TREE/ {sum+=$4} END {print sum}' "$RDFIND_OUTPUT")
    if [ -n "$TOTAL_WASTED" ] && [ "$TOTAL_WASTED" != "0" ]; then
        if [ "$TOTAL_WASTED" -ge 1073741824 ]; then
            WASTED_HUMAN=$(awk "BEGIN {printf \"%.2f GB\", $TOTAL_WASTED/1073741824}")
        elif [ "$TOTAL_WASTED" -ge 1048576 ]; then
            WASTED_HUMAN=$(awk "BEGIN {printf \"%.2f MB\", $TOTAL_WASTED/1048576}")
        else
            WASTED_HUMAN=$(awk "BEGIN {printf \"%.2f KB\", $TOTAL_WASTED/1024}")
        fi
        echo "Space wasted by duplicates: $WASTED_HUMAN"
    fi
    echo ""

    # Scan statistics
    TOTAL_SIZE=$(du -sh "$SCAN_DIR" 2>/dev/null | awk '{print $1}')
    TOTAL_FILES=$(find "$SCAN_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')
    echo "Scanned: $TOTAL_FILES files ($TOTAL_SIZE)"
    echo ""

    echo "=========================================="
    echo "HOW TO USE THIS REPORT"
    echo "=========================================="
    echo ""
    echo "Each group shows:"
    echo "  - ORIGINAL: The first occurrence (KEEP this one)"
    echo "  - DUPLICATE: Other copies (can be moved/deleted)"
    echo ""
    echo "To manually remove duplicates:"
    echo "1. Review each group carefully"
    echo "2. Keep the ORIGINAL (or choose your preferred copy)"
    echo "3. Move DUPLICATE files to: /Volumes/NAS_1/Duplicates"
    echo ""
    echo "Create duplicates folder:"
    echo "  mkdir -p /Volumes/NAS_1/Duplicates"
    echo ""
    echo "Example: Move duplicate to quarantine"
    echo "  mv '/Volumes/NAS_1/Photos/IMG_1234_copy.jpg' /Volumes/NAS_1/Duplicates/"
    echo ""
    echo "After moving all duplicates:"
    echo "  1. Run backup (Duplicates folder is excluded automatically)"
    echo "  2. Verify for a week that nothing is broken"
    echo "  3. Delete Duplicates folder: rm -rf /Volumes/NAS_1/Duplicates"
    echo ""
    echo "Note: /Volumes/NAS_1/Duplicates is already excluded from backup."
    echo ""
    echo "Raw rdfind output saved at:"
    echo "  $RDFIND_OUTPUT"
    echo ""

} > "$REPORT_FILE"

REPORT_STATUS=$?

if [ $REPORT_STATUS -ne 0 ]; then
    echo ""
    echo "❌ Report generation failed with status $REPORT_STATUS"
    echo ""
    echo "Raw rdfind output is still available at:"
    echo "  $RDFIND_OUTPUT"
    echo ""
    echo "You can manually review the raw file, or try running again."
    exit 1
fi

# Check if report file was created
if [ ! -f "$REPORT_FILE" ]; then
    echo ""
    echo "❌ Report file not created!"
    echo ""
    echo "Raw rdfind output is available at:"
    echo "  $RDFIND_OUTPUT"
    echo ""
    exit 1
fi

# Check if report has content
if [ ! -s "$REPORT_FILE" ]; then
    echo ""
    echo "⚠️  Report file is empty"
    echo ""
    echo "Raw rdfind output is available at:"
    echo "  $RDFIND_OUTPUT"
    echo ""
    exit 1
fi

echo "✅ Report generated successfully!"
echo ""
echo "Files created:"
echo "  Raw data:  $RDFIND_OUTPUT"
echo "  Report:    $REPORT_FILE"
echo ""
echo "Opening report..."
if open "$REPORT_FILE" 2>/dev/null; then
    echo "✅ Report opened"
else
    echo "⚠️  Could not auto-open report. Please open manually:"
    echo "  open '$REPORT_FILE'"
fi

echo ""
echo "Next steps:"
echo "1. Review the report (organized by duplicate groups)"
echo "2. Create duplicates folder: mkdir -p /Volumes/NAS_1/Duplicates"
echo "3. Move DUPLICATE files (not ORIGINAL) to that folder"
echo "4. Run backup (duplicates won't be backed up)"
echo "5. Verify for a week, then: rm -rf /Volumes/NAS_1/Duplicates"
echo ""
