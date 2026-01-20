# NAS Scripts

## Backup Scripts (restic)

### weekly_backup_reminder.sh (Recommended for WD Elements)
Interactive weekly backup helper script.

**For WD Elements 16TB backup drive (consumer, not NAS-rated):**

**Usage:**
```bash
# Every Sunday (set calendar reminder):
# 1. Plug in WD Elements backup drive
# 2. Run:
./scripts/weekly_backup_reminder.sh

# 3. Follow prompts
# 4. When complete, unplug drive and store safely
```

**Why weekly + unplugged:**
- WD Elements NOT designed for 24/7 operation
- Protects from simultaneous failures (power surge, malware)
- Extends drive life by 10x
- True offline backup (ransomware protection)

### restic_backup.sh
Core backup script (called by weekly_backup_reminder.sh or automated daily).

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

## Deprecated Scripts

### backup_to_second_drive.sh.deprecated
Old rsync-based backup script (replaced by restic).

**Why deprecated:**
- Backup drive is NTFS (Time Machine/rsync snapshots don't work well)
- restic provides better corruption detection + recovery
- restic is cross-platform (works on Linux/Windows if you migrate)

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
