# NAS Scripts

## Backup Scripts (restic)

### restic_backup.sh
Core backup script for automated incremental backups.

**Setup:**
```bash
# 1. Initialize restic repository:
restic init -r /Volumes/NAS_Backup/restic-repo

# 2. Save password:
echo "your-password" > ~/.restic-password
chmod 600 ~/.restic-password

# 3. Test backup:
./restic_backup.sh

# 4. Schedule daily backups (see HOME_NAS_BUILD_GUIDE.md)
```

**What it does:**
- Backs up entire NAS_1 drive to restic repository
- Excludes system files (.DS_Store, caches, etc.)
- Prunes old snapshots (keeps 30 daily, 12 monthly)
- Logs to ~/Library/Logs/restic_backup.log

### restic_verify.sh
Monthly backup integrity verification.

**Usage:**
```bash
# Run monthly:
./restic_verify.sh

# Check results:
tail ~/Library/Logs/restic_verify.log
```

**What it does:**
- Verifies repository structure
- Reads and verifies all data chunks (thorough check)
- Lists current snapshots
- Shows repository statistics

## Duplicate Management

### find_duplicates.sh
Scans for duplicate files based on checksums.

**Usage:**
```bash
./scripts/find_duplicates.sh
```

**What it does:**
- Recursively scans directories for duplicate files
- Uses checksums to identify identical files
- Generates a report of duplicates found

### move_duplicates.sh
Moves duplicate files based on report from find_duplicates.sh.

**Usage:**
```bash
# First generate duplicate report:
./scripts/find_duplicates.sh > duplicates_report.txt

# Then move duplicates:
./scripts/move_duplicates.sh duplicates_report.txt
```

**What it does:**
- Reads duplicate report
- Moves duplicate files to specified location
- Keeps one copy of each file

## Setup Scripts

### setup_power_settings.sh
One-time power management configuration.

**Usage:**
```bash
# Run once after initial setup:
./scripts/setup_power_settings.sh
```

**What it configures:**
- AC power: Mac never sleeps, drives sleep after 10 min idle
- Battery power: Aggressive sleep for laptop mode
- Optimized for 8/5 usage pattern

## Health Monitoring

### check_drive_health.sh
SMART drive health monitoring.

**Usage:**
```bash
# Run weekly:
sudo ./check_drive_health.sh
```

**Checks:**
- Drive temperature
- Reallocated sectors
- Power-on hours
- Pending sectors
- Overall health status

### test_network.sh
Network and service verification.

**Usage:**
```bash
./test_network.sh
```

**Tests:**
- NordVPN status
- Tailscale connectivity
- SMB service
- Plex service
- Drive mounts
- Routing table


## Quick Commands

```bash
# Manual backup:
restic -r /Volumes/NAS_Backup/restic-repo backup /Volumes/NAS_1/

# List snapshots:
restic -r /Volumes/NAS_Backup/restic-repo snapshots

# Restore file:
restic -r /Volumes/NAS_Backup/restic-repo restore latest \
  --target /tmp/restore --path /Photos/important.jpg

# Check integrity:
restic -r /Volumes/NAS_Backup/restic-repo check

# Repository stats:
restic -r /Volumes/NAS_Backup/restic-repo stats
```

## Troubleshooting

**restic password error:**
```bash
# Check password file exists and has correct permissions:
ls -l ~/.restic-password
chmod 600 ~/.restic-password
```

**Backup drive not mounted:**
```bash
# Check if drive is connected:
ls /Volumes/
# Should see NAS_Backup

# If using NTFS, ensure Paragon NTFS is running
```

**Repository not found:**
```bash
# Initialize if doesn't exist:
restic init -r /Volumes/NAS_Backup/restic-repo
```
