#!/bin/bash

###############################################
# Quick re-parser for existing rdfind output
# Fixes parsing of negative IDs
###############################################

# Find most recent raw file
RAW_FILE=$(ls -t ~/Documents/NAS_duplicate_reports/rdfind_raw_*.txt 2>/dev/null | head -1)

if [ -z "$RAW_FILE" ] || [ ! -f "$RAW_FILE" ]; then
    echo "❌ No rdfind raw file found"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="$HOME/Documents/NAS_duplicate_reports/duplicates_fixed_${TIMESTAMP}.txt"

echo "Re-parsing: $RAW_FILE"
echo "Output: $REPORT_FILE"
echo ""

{
    echo "=========================================="
    echo "DUPLICATE FILES REPORT - REPARSED"
    echo "Generated: $(date)"
    echo "=========================================="
    echo ""
    echo "Source: $RAW_FILE"
    echo ""
    echo "=========================================="
    echo "DUPLICATE FILE GROUPS"
    echo "=========================================="
    echo ""

    # Use awk to parse (handles negative IDs correctly)
    awk '
    BEGIN { current_id = ""; group = 0 }

    # Skip comments
    /^#/ { next }

    # Parse DUPTYPE lines
    /^DUPTYPE_/ {
        duptype = $1
        id = $2
        size = $4

        # Filename starts at field 9
        filename = ""
        for (i = 9; i <= NF; i++) {
            if (i > 9) filename = filename " "
            filename = filename $i
        }

        # Convert size to human readable
        if (size >= 1073741824) {
            human_size = sprintf("%.2f GB", size/1073741824)
        } else if (size >= 1048576) {
            human_size = sprintf("%.2f MB", size/1048576)
        } else if (size >= 1024) {
            human_size = sprintf("%.2f KB", size/1024)
        } else {
            human_size = size " B"
        }

        # Use absolute value of ID for grouping
        abs_id = (id < 0) ? -id : id

        # New group?
        if (abs_id != current_id && current_id != "") {
            print ""  # Blank line between groups
        }
        current_id = abs_id

        # Print file
        if (duptype == "DUPTYPE_FIRST_OCCURRENCE") {
            printf "[%s] %s  ← ORIGINAL (keep)\n", human_size, filename
        } else {
            printf "[%s] %s  ← DUPLICATE (move)\n", human_size, filename
        }
    }

    END {
        print ""
        print "=========================================="
        print "SUMMARY"
        print "=========================================="
    }
    ' "$RAW_FILE"

    # Count duplicates
    DUP_COUNT=$(grep -c "DUPTYPE_WITHIN_SAME_TREE" "$RAW_FILE")
    echo "Total duplicate files: $DUP_COUNT"
    echo ""

    # Calculate wasted space
    WASTED=$(awk '/DUPTYPE_WITHIN_SAME_TREE/ {sum+=$4} END {print sum+0}' "$RAW_FILE")
    if [ "$WASTED" -ge 1073741824 ]; then
        echo "Space wasted: $(awk "BEGIN {printf \"%.2f GB\", $WASTED/1073741824}")"
    elif [ "$WASTED" -ge 1048576 ]; then
        echo "Space wasted: $(awk "BEGIN {printf \"%.2f MB\", $WASTED/1048576}")"
    else
        echo "Space wasted: $(awk "BEGIN {printf \"%.2f KB\", $WASTED/1024}")"
    fi
    echo ""

    echo "=========================================="
    echo "HOW TO USE"
    echo "=========================================="
    echo ""
    echo "For each group:"
    echo "1. Keep the ORIGINAL file"
    echo "2. Move DUPLICATE files to: /Volumes/NAS_1/Duplicates"
    echo ""
    echo "Commands:"
    echo "  mkdir -p /Volumes/NAS_1/Duplicates"
    echo "  mv '/full/path/to/duplicate' /Volumes/NAS_1/Duplicates/"
    echo ""

} > "$REPORT_FILE"

echo "✅ Done!"
echo ""
open "$REPORT_FILE"
