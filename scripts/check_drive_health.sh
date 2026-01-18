#!/bin/bash

# Drive health monitoring script
# Checks SMART status, temperature, and disk space

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "======================================"
echo "  NAS Drive Health Check"
echo "======================================"
echo "Date: $(date)"
echo ""

# Function to check if smartmontools is installed
check_smartmontools() {
    if ! command -v smartctl &> /dev/null; then
        echo -e "${YELLOW}⚠ smartmontools not installed${NC}"
        echo "Install with: brew install smartmontools"
        echo ""
        return 1
    fi
    return 0
}

# Function to get drive identifier for a mounted volume
get_drive_identifier() {
    local volume_name=$1
    diskutil info "/Volumes/$volume_name" 2>/dev/null | grep "Device Node:" | awk '{print $3}'
}

# 1. List all connected drives
echo "1. Connected Drives:"
diskutil list | grep -E "^/dev/disk[0-9]|IDENTIFIER|TYPE NAME"
echo ""

# 2. Check mounted volumes
echo "2. Mounted NAS Volumes:"

PRIMARY_MOUNTED=false
BACKUP_MOUNTED=false

if [ -d "/Volumes/NAS_Primary" ]; then
    PRIMARY_DISK=$(get_drive_identifier "NAS_Primary")
    echo -e "${GREEN}✓ NAS_Primary mounted${NC}"
    echo "  Device: $PRIMARY_DISK"
    df -h "/Volumes/NAS_Primary" | tail -1 | awk '{print "  Size: " $2 "  Used: " $3 " (" $5 ")  Available: " $4}'
    PRIMARY_MOUNTED=true
else
    echo -e "${RED}✗ NAS_Primary not mounted${NC}"
fi

echo ""

if [ -d "/Volumes/NAS_Backup" ]; then
    BACKUP_DISK=$(get_drive_identifier "NAS_Backup")
    echo -e "${GREEN}✓ NAS_Backup mounted${NC}"
    echo "  Device: $BACKUP_DISK"
    df -h "/Volumes/NAS_Backup" | tail -1 | awk '{print "  Size: " $2 "  Used: " $3 " (" $5 ")  Available: " $4}'
    BACKUP_MOUNTED=true
else
    echo -e "${YELLOW}⚠ NAS_Backup not mounted${NC}"
fi

echo ""

# 3. SMART Health Status
if check_smartmontools; then
    echo "3. SMART Health Status:"
    echo ""

    if [ "$PRIMARY_MOUNTED" = true ] && [ -n "$PRIMARY_DISK" ]; then
        echo "  IronWolf Pro (NAS_Primary - $PRIMARY_DISK):"

        # Overall health
        HEALTH=$(sudo smartctl -H "$PRIMARY_DISK" 2>/dev/null | grep "SMART overall-health" | awk -F: '{print $2}' | xargs)
        if [ "$HEALTH" = "PASSED" ]; then
            echo -e "  Overall Health: ${GREEN}✓ $HEALTH${NC}"
        else
            echo -e "  Overall Health: ${RED}✗ $HEALTH${NC}"
        fi

        # Temperature
        TEMP=$(sudo smartctl -A "$PRIMARY_DISK" 2>/dev/null | grep "Temperature_Celsius" | awk '{print $10}')
        if [ -n "$TEMP" ]; then
            if [ "$TEMP" -lt 50 ]; then
                echo -e "  Temperature: ${GREEN}$TEMP°C${NC} (Optimal: <50°C)"
            elif [ "$TEMP" -lt 60 ]; then
                echo -e "  Temperature: ${YELLOW}$TEMP°C${NC} (Warning: 50-60°C)"
            else
                echo -e "  Temperature: ${RED}$TEMP°C${NC} (Critical: >60°C)"
            fi
        fi

        # Power on hours
        HOURS=$(sudo smartctl -A "$PRIMARY_DISK" 2>/dev/null | grep "Power_On_Hours" | awk '{print $10}')
        if [ -n "$HOURS" ]; then
            DAYS=$((HOURS / 24))
            echo "  Power On Time: $HOURS hours ($DAYS days)"
        fi

        # Reallocated sectors (should be 0)
        REALLOC=$(sudo smartctl -A "$PRIMARY_DISK" 2>/dev/null | grep "Reallocated_Sector" | awk '{print $10}')
        if [ -n "$REALLOC" ]; then
            if [ "$REALLOC" -eq 0 ]; then
                echo -e "  Reallocated Sectors: ${GREEN}$REALLOC${NC}"
            else
                echo -e "  Reallocated Sectors: ${RED}$REALLOC${NC} (WARNING: Should be 0)"
            fi
        fi

        # Pending sectors (should be 0)
        PENDING=$(sudo smartctl -A "$PRIMARY_DISK" 2>/dev/null | grep "Current_Pending_Sector" | awk '{print $10}')
        if [ -n "$PENDING" ]; then
            if [ "$PENDING" -eq 0 ]; then
                echo -e "  Pending Sectors: ${GREEN}$PENDING${NC}"
            else
                echo -e "  Pending Sectors: ${RED}$PENDING${NC} (WARNING: Should be 0)"
            fi
        fi

        echo ""
    fi

    if [ "$BACKUP_MOUNTED" = true ] && [ -n "$BACKUP_DISK" ] && [ "$BACKUP_DISK" != "$PRIMARY_DISK" ]; then
        echo "  Backup Drive (NAS_Backup - $BACKUP_DISK):"

        HEALTH=$(sudo smartctl -H "$BACKUP_DISK" 2>/dev/null | grep "SMART overall-health" | awk -F: '{print $2}' | xargs)
        if [ "$HEALTH" = "PASSED" ]; then
            echo -e "  Overall Health: ${GREEN}✓ $HEALTH${NC}"
        else
            echo -e "  Overall Health: ${RED}✗ $HEALTH${NC}"
        fi

        TEMP=$(sudo smartctl -A "$BACKUP_DISK" 2>/dev/null | grep "Temperature_Celsius" | awk '{print $10}')
        if [ -n "$TEMP" ]; then
            if [ "$TEMP" -lt 50 ]; then
                echo -e "  Temperature: ${GREEN}$TEMP°C${NC}"
            elif [ "$TEMP" -lt 60 ]; then
                echo -e "  Temperature: ${YELLOW}$TEMP°C${NC}"
            else
                echo -e "  Temperature: ${RED}$TEMP°C${NC}"
            fi
        fi

        echo ""
    fi
else
    echo "3. SMART Health Status: Skipped (smartmontools not installed)"
    echo ""
fi

# 4. Storage Usage Summary
echo "4. Storage Usage Summary:"
echo ""

if [ "$PRIMARY_MOUNTED" = true ]; then
    echo "  NAS_Primary:"
    df -h "/Volumes/NAS_Primary" | tail -1 | awk '{
        used_pct = substr($5, 1, length($5)-1)
        if (used_pct < 80)
            printf "  Used: %s of %s (%s) - Available: %s ✓\n", $3, $2, $5, $4
        else if (used_pct < 90)
            printf "  Used: %s of %s (%s) - Available: %s ⚠\n", $3, $2, $5, $4
        else
            printf "  Used: %s of %s (%s) - Available: %s ✗\n", $3, $2, $5, $4
    }'

    # Show largest directories
    echo ""
    echo "  Largest directories:"
    du -sh /Volumes/NAS_Primary/* 2>/dev/null | sort -hr | head -5 | sed 's/^/    /'
    echo ""
fi

if [ "$BACKUP_MOUNTED" = true ]; then
    echo "  NAS_Backup:"
    df -h "/Volumes/NAS_Backup" | tail -1 | awk '{
        used_pct = substr($5, 1, length($5)-1)
        if (used_pct < 80)
            printf "  Used: %s of %s (%s) - Available: %s ✓\n", $3, $2, $5, $4
        else if (used_pct < 90)
            printf "  Used: %s of %s (%s) - Available: %s ⚠\n", $3, $2, $5, $4
        else
            printf "  Used: %s of %s (%s) - Available: %s ✗\n", $3, $2, $5, $4
    }'
    echo ""
fi

# 5. Recent backup status
echo "5. Recent Backup Status:"
BACKUP_LOG="$HOME/Library/Logs/nas_backup.log"
if [ -f "$BACKUP_LOG" ]; then
    LAST_BACKUP=$(tail -20 "$BACKUP_LOG" | grep "Backup completed successfully" | tail -1)
    if [ -n "$LAST_BACKUP" ]; then
        echo -e "  ${GREEN}✓ Last successful backup:${NC}"
        echo "  $LAST_BACKUP"
    else
        echo -e "  ${YELLOW}⚠ No recent successful backup found${NC}"
        echo "  Check $BACKUP_LOG"
    fi
else
    echo "  ℹ No backup log found"
    echo "  Expected at: $BACKUP_LOG"
fi

echo ""
echo "======================================"
echo "  Health Check Complete"
echo "======================================"
echo ""

# Recommendations
echo "Recommendations:"
if [ "$PRIMARY_MOUNTED" = false ]; then
    echo -e "${RED}✗ Mount your primary NAS drive${NC}"
fi

if check_smartmontools; then
    if [ -n "$TEMP" ] && [ "$TEMP" -gt 50 ]; then
        echo -e "${YELLOW}⚠ Drive temperature is high. Ensure adequate ventilation.${NC}"
    fi

    if [ -n "$REALLOC" ] && [ "$REALLOC" -gt 0 ]; then
        echo -e "${RED}✗ Drive has reallocated sectors. Consider replacing drive.${NC}"
    fi
fi

# Check disk usage
if [ "$PRIMARY_MOUNTED" = true ]; then
    USAGE=$(df -h "/Volumes/NAS_Primary" | tail -1 | awk '{print substr($5, 1, length($5)-1)}')
    if [ "$USAGE" -gt 90 ]; then
        echo -e "${RED}✗ Primary drive is over 90% full. Free up space soon.${NC}"
    elif [ "$USAGE" -gt 80 ]; then
        echo -e "${YELLOW}⚠ Primary drive is over 80% full. Plan to free up space.${NC}"
    fi
fi

echo ""
echo "For detailed SMART info, run:"
if [ -n "$PRIMARY_DISK" ]; then
    echo "  sudo smartctl -a $PRIMARY_DISK"
fi
echo ""
