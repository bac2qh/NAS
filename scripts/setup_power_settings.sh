#!/bin/bash

###############################################
# Power Management Setup for NAS Mac
# Optimized for 8/5 usage pattern
###############################################

echo "=========================================="
echo "  NAS Power Management Setup"
echo "=========================================="
echo ""
echo "This will configure power settings for:"
echo "  - 8/5 usage pattern (Mac on ~8 hours/day)"
echo "  - IronWolf Pro stays connected"
echo "  - Drives sleep after 10 min idle"
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

echo ""
echo "Configuring power settings..."
echo ""

# AC Power (plugged in) - NAS mode
echo "Setting AC power (plugged in) preferences..."
sudo pmset -c sleep 0          # Mac never sleeps
sudo pmset -c disksleep 10     # Drives sleep after 10 min
sudo pmset -c displaysleep 10  # Display sleeps after 10 min
sudo pmset -c powernap 0       # Disable Power Nap
sudo pmset -c autopoweroff 0   # Disable auto power off

# Battery Power - Laptop mode
echo "Setting battery power preferences..."
sudo pmset -b sleep 15         # Mac sleeps after 15 min
sudo pmset -b disksleep 5      # Drives sleep after 5 min
sudo pmset -b displaysleep 5   # Display sleeps after 5 min
sudo pmset -b powernap 1       # Enable Power Nap

echo ""
echo "✅ Power settings configured!"
echo ""

# Show current settings
echo "Current power settings:"
echo ""
pmset -g

echo ""
echo "=========================================="
echo "  Configuration Complete"
echo "=========================================="
echo ""
echo "Your Mac will now:"
echo "  ✅ Never sleep when plugged in (important for file serving)"
echo "  ✅ Allow drives to sleep after 10 minutes of inactivity"
echo "  ✅ Power cycles: ~2 per day (safe for IronWolf Pro)"
echo ""
echo "Physical setup:"
echo "  ✅ Keep IronWolf Pro connected at all times"
echo "  ✅ Leave USB cable and dock power connected"
echo "  ❌ Unplug WD Elements backup drive between weekly backups"
echo ""
