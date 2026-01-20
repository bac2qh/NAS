# Home NAS Build Guide
## MacBook Pro M1 + External Drive Setup with Tailscale

---

## Table of Contents
1. [Hardware Overview](#hardware-overview)
2. [Initial Setup](#initial-setup)
3. [Drive Configuration](#drive-configuration)
4. [File Sharing Setup](#file-sharing-setup)
5. [Time Machine Configuration](#time-machine-configuration)
6. [Media Server Setup](#media-server-setup)
7. [Tailscale Remote Access (with NordVPN)](#tailscale-remote-access-with-nordvpn)
8. [Backup Strategy](#backup-strategy)
9. [Power Management](#power-management)
10. [Maintenance & Monitoring](#maintenance--monitoring)
11. [VPN Quick Reference](#vpn-quick-reference)

---

## Hardware Overview

### Your Components
- **Primary Storage**: Seagate IronWolf Pro 14TB (NAS-rated, CMR technology)
- **Backup Storage**: Regular HDD (secondary drive)
- **Enclosure**: SABRENT USB 3.2 to SATA 3 Dual Bay External Docking Station
- **Host**: M1 MacBook Pro (dual purpose: daily driver + NAS)
- **Network**: Tailscale free tier (remote access)

### Advantages of This Setup
- **IronWolf Pro**: Designed for 24/7 operation, 300TB/year workload rating
- **USB 3.2**: Up to 10Gbps transfer speeds
- **M1 Efficiency**: Low power consumption, excellent for always-on operation
- **Tailscale**: Secure, zero-config remote access without port forwarding

---

## Initial Setup

### 1. Connect Hardware
1. Insert IronWolf Pro 14TB into Bay 1 of the SABRENT dock
2. Insert backup HDD into Bay 2
3. Connect dock to MacBook Pro via USB-C/USB 3.2
4. Power on the dock
5. Verify drives appear in Disk Utility

### 2. Check Drive Health
```bash
# Install smartmontools via Homebrew
brew install smartmontools

# Check IronWolf Pro health
diskutil list  # Find your drive identifier (e.g., disk2)
sudo smartctl -a /dev/disk2

# Key metrics to check:
# - Power_On_Hours
# - Reallocated_Sector_Ct (should be 0)
# - Current_Pending_Sector (should be 0)
# - Temperature (should be <50°C)
```

---

## Drive Configuration

### Format IronWolf Pro (Primary NAS Drive)

**IMPORTANT**: See [FILE_SYSTEM_GUIDE.md](FILE_SYSTEM_GUIDE.md) for detailed file system comparison.

**Recommended for your setup**: **APFS (Encrypted)**
- Best data integrity for large files (50GB+)
- Copy-on-Write + checksumming protects against corruption
- Native macOS support with excellent performance
- Hardware-accelerated encryption on M1

1. Open **Disk Utility**
2. Select the IronWolf Pro 14TB drive
3. Click **Erase** with these settings:
   - **Name**: `NAS_Primary` (or your preference)
   - **Format**: `APFS (Encrypted)` ← **RECOMMENDED**
   - **Scheme**: `GUID Partition Map`
4. Click **Erase**
5. Create a strong encryption password when prompted (store in password manager)

**Alternative formats**:
- **APFS** (unencrypted): If you don't need encryption
- **ExFAT**: Only if you need Windows/Linux compatibility (NOT recommended - no corruption protection)

**Why NOT exFAT for large media files**:
- No checksumming - cannot detect corruption
- No journaling - vulnerable to crashes
- No data integrity features
- See FILE_SYSTEM_GUIDE.md for details

### Format Backup Drive (NTFS for Cross-Platform)

**Backup drive uses NTFS for maximum compatibility:**
- Works on macOS (via Paragon NTFS)
- Native on Windows
- Native on Linux
- restic handles encryption + integrity (filesystem-agnostic)

**Format as NTFS:**
1. Open **Disk Utility**
2. Select backup HDD
3. Click **Erase**:
   - **Name**: `NAS_Backup`
   - **Format**: `ExFAT` (Disk Utility doesn't support NTFS)
   - **Scheme**: `GUID Partition Map`
4. After formatting to ExFAT, use Paragon NTFS to reformat to NTFS if needed
5. Or keep ExFAT and let restic handle everything

**Note**: Filesystem doesn't matter much since restic provides encryption and integrity checking regardless of underlying format.

### Create Folder Structure

```bash
# Navigate to your primary NAS drive
cd /Volumes/NAS_Primary

# Create organized folders
mkdir -p Media/{Movies,TV\ Shows,Music,Photos}
mkdir -p Shared/{Documents,Projects,Archives}
mkdir -p Backups/TimeMachine

# Set permissions (everyone can read/write on local network)
chmod -R 755 Media Shared
chmod -R 700 Backups  # Backups are private
```

---

## File Sharing Setup

### Enable SMB File Sharing (for all devices)

1. **System Settings** → **General** → **Sharing**
2. Enable **File Sharing**
3. Click the **(i)** info button next to File Sharing
4. Enable **SMB** protocol
5. Click **Options**, enable SMB for your user account
6. Add shared folders:
   - Click **+** under Shared Folders
   - Add `/Volumes/NAS_Primary/Media`
   - Add `/Volumes/NAS_Primary/Shared`
7. Set permissions:
   - **Everyone**: Read & Write (or Read Only for media)

### Create a Dedicated NAS User (Recommended)

```bash
# This user account is for NAS access only
# Go to System Settings → Users & Groups → Add User
# Create user: "nasuser" with a strong password
```

### Configure Static IP (Optional but Recommended)

**Best approach**: Reserve IP in your router's DHCP settings instead of manual configuration.

**Method 1: DHCP Reservation (Recommended)**
1. Note your Mac's current IP: System Settings → Network → Details → TCP/IP
2. Log into router admin (usually http://192.168.1.1)
3. Find "DHCP Reservation" or "Static Lease"
4. Add: Mac's MAC address → desired IP (e.g., 192.168.1.100)
5. Mac keeps same IP automatically, no manual config needed

**Method 2: Manual Configuration (Advanced)**
1. System Settings → Network → Wi-Fi/Ethernet → Details
2. TCP/IP tab → Configure IPv4: **Using DHCP**
3. Note current Router address and DNS servers
4. Change to: **Using DHCP with manual address**
5. IPv4 Address: `192.168.1.100` (pick unused IP in your subnet)
6. **Important**: DNS tab → Add DNS servers:
   - Your router's IP (e.g., `192.168.1.1`)
   - Google DNS: `8.8.8.8` (backup)
7. Click OK and test internet connectivity

**⚠️ If internet stops working**: Switch back to "Using DHCP" and use Method 1 instead.

### Access from Other Devices

**macOS**:
- Finder → Go → Connect to Server
- `smb://192.168.1.100` or `smb://your-macbook-name.local`

**Windows**:
- File Explorer → `\\192.168.1.100` or `\\your-macbook-name`

**Linux**:
```bash
sudo mount -t cifs //192.168.1.100/Media /mnt/nas -o user=nasuser
```

---

## Time Machine Configuration (Optional)

**Note**: Time Machine is for the **NAS Mac itself**, not for backing up the NAS drive (that's handled by restic).

### Local Time Machine Backup

Use NAS_Primary to back up your Mac's internal system drive:

1. **System Settings** → **General** → **Time Machine**
2. Click **+** to add backup disk
3. Select a folder on `/Volumes/NAS_1/` (create MacBackup folder)
4. Time Machine backs up Mac system, applications, documents

**This is separate from your NAS data backup (which uses restic).**

### Time Machine for Other Macs (Network Backup)

Share NAS as Time Machine destination for other Macs on your network:

1. Create folder: `mkdir -p /Volumes/NAS_1/TimeMachine`
2. **System Settings** → **Sharing** → **File Sharing**
3. Add `/Volumes/NAS_1/TimeMachine` to shared folders
4. Right-click → **Advanced Options** → **Share as Time Machine backup destination**

**Other Macs can now use your NAS for Time Machine backups over the network.**

---

## Media Server Setup

### Option 1: Plex Media Server (Recommended)

**Installation**:
```bash
# Download from https://www.plex.tv/media-server-downloads/
# Or via Homebrew:
brew install --cask plex-media-server
```

**Configuration**:
1. Open Plex at `http://localhost:32400/web`
2. Create account/sign in
3. Add Libraries:
   - **Movies**: `/Volumes/NAS_Primary/Media/Movies`
   - **TV Shows**: `/Volumes/NAS_Primary/Media/TV Shows`
   - **Music**: `/Volumes/NAS_Primary/Media/Music`
   - **Photos**: `/Volumes/NAS_Primary/Media/Photos`
4. Settings → Network:
   - Enable **Remote Access** (will work with Tailscale)
   - **LAN Networks**: `192.168.0.0/16,100.64.0.0/10` (include Tailscale subnet)

**Optimize for M1**:
- Settings → Transcoder → **Hardware acceleration**: enabled
- **Use hardware-accelerated video encoding**: enabled

### Option 2: Jellyfin (Open Source Alternative)

```bash
brew install --cask jellyfin
```

Setup is similar to Plex, access at `http://localhost:8096`

---

## Tailscale Remote Access (with NordVPN)

### Important: Running VPNs Together

Since your Mac will be connected to NordVPN at all times, you need to configure both VPNs to work together properly.

**The Challenge**:
- NordVPN routes all traffic through its VPN tunnel
- Tailscale creates its own virtual network
- By default, they conflict and can break local network access

**The Solution**: Use NordVPN's split tunneling feature or configure proper routing

### Install & Setup Tailscale

```bash
# Install Tailscale
brew install --cask tailscale

# Launch and authenticate
open /Applications/Tailscale.app

# Or via command line
sudo tailscale up
```

### Configure NordVPN for Local Network Access

**Method 1: Enable Split Tunneling (Recommended)**

1. Open NordVPN app → **Settings** → **Advanced**
2. Enable **Split Tunneling**
3. Add exceptions for:
   - Local network ranges: `192.168.0.0/16`, `10.0.0.0/8`, `172.16.0.0/12`
   - Tailscale subnet: `100.64.0.0/10`
4. Alternatively, exclude specific apps from VPN:
   - Plex Media Server
   - Finder (for file sharing)

**Method 2: Use NordVPN Whitelist Feature**

```bash
# Enable LAN discovery in NordVPN
# NordVPN app → Settings → Enable "Invisible on LAN"
```

This allows your Mac to be discoverable on the local network while VPN is active.

### Configure Tailscale

1. Open Tailscale menu bar app → **Settings**
2. Enable:
   - **Run in background**
   - **Accept routes**
   - **Use Tailscale DNS** (optional, but helps with name resolution)
3. Note your Tailscale IP (e.g., `100.x.x.x`)

### Connection Priority Setup

```bash
# Check route priorities
netstat -nr

# Tailscale should create routes for 100.64.0.0/10
# NordVPN should handle 0.0.0.0/0 (all other traffic)
```

**Proper routing order**:
1. Local network (192.168.x.x) - direct connection
2. Tailscale network (100.x.x.x) - Tailscale tunnel
3. Everything else - NordVPN tunnel

### Access Your NAS Remotely

**File Sharing**:
- `smb://100.x.x.x` (use your Tailscale IP)

**Plex**:
- `http://100.x.x.x:32400/web`

**SSH** (for administration):
```bash
# Enable Remote Login in System Settings → General → Sharing
ssh your-username@100.x.x.x
```

### Tailscale Free Tier Limits
- Up to 100 devices
- 1 user
- All features included
- Perfect for personal use

### Optimize for Mobile Access

**iOS/Android**:
1. Install Tailscale app
2. Connect to your network
3. Access files via SMB client (e.g., FileBrowser, FE File Explorer)
4. Or use Plex mobile app (auto-discovers server)

---

## Backup Strategy

### Why restic?

**Your backup drive is NTFS** (cross-platform compatibility), which means:
- ❌ Can't use Time Machine (requires APFS/HFS+)
- ❌ Can't use APFS checksumming
- ✅ Use restic for encryption + integrity checking + versioned backups

**restic advantages:**
- Content-addressed chunking (deduplicated, space-efficient)
- Built-in encryption (AES-256)
- Checksummed data (corruption detection)
- Versioned snapshots (point-in-time recovery)
- Cross-platform (works on macOS, Linux, Windows)
- Filesystem-agnostic (NTFS, APFS, ext4, anything)

### 3-2-1 Backup Rule

Your setup:
- **3 copies**: Original data + restic snapshots + cloud (critical files)
- **2 different media**: IronWolf Pro + backup HDD
- **1 offsite**: Cloud backup for important files

### Initial Setup

**1. Install restic:**
```bash
brew install restic
```

**2. Initialize encrypted repository:**
```bash
# Create restic repo on backup drive:
restic init -r /Volumes/NAS_Backup/restic-repo

# Set a strong password when prompted
# Store in password manager!

# Or save password to file (secure permissions):
echo "your-strong-password" > ~/.restic-password
chmod 600 ~/.restic-password
```

**3. Create backup script:**

Use the provided script at `scripts/restic_backup.sh`

**4. Test backup:**
```bash
chmod +x scripts/restic_backup.sh
./scripts/restic_backup.sh
```

### Backup Frequency

**Recommended: Weekly manual backups (unplug drive between backups)**

Why weekly + unplugged:
- ✅ WD Elements 16TB is consumer drive (not NAS-rated, not designed for 24/7)
- ✅ Protects from simultaneous failure (power surge, ransomware)
- ✅ True offline backup (air-gapped security)
- ✅ Extends backup drive life (10x longer)
- ✅ Weekly cadence sufficient for media files (photos/videos don't change daily)

**Manual weekly workflow:**
```bash
# Every Sunday (or your schedule):
# 1. Plug in WD Elements backup drive
# 2. Wait for /Volumes/NAS_Backup to mount
# 3. Run backup:
cd ~/Work/personal/NAS
./scripts/restic_backup.sh

# 4. Verify completed:
tail ~/Library/Logs/restic_backup.log

# 5. Safely eject:
diskutil eject /Volumes/NAS_Backup

# 6. Unplug and store in safe location (separate room from primary NAS)
```

### Optional: Automated Daily Backups (Keep Drive Plugged In)

**Only if you upgrade to NAS-rated backup drive** (IronWolf, WD Red, etc.)

**Daily backups with launchd:**
```bash
# Create plist file:
cat > ~/Library/LaunchAgents/com.user.restic-backup.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.restic-backup</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>/Users/YOUR_USERNAME/Work/personal/NAS/scripts/restic_backup.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>2</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardErrorPath</key>
    <string>/tmp/restic-backup.err</string>
    <key>StandardOutPath</key>
    <string>/tmp/restic-backup.out</string>
</dict>
</plist>
EOF

# Replace YOUR_USERNAME:
sed -i '' "s/YOUR_USERNAME/$(whoami)/g" ~/Library/LaunchAgents/com.user.restic-backup.plist

# Load:
launchctl load ~/Library/LaunchAgents/com.user.restic-backup.plist
```

### Common restic Commands

```bash
# Manual backup:
restic -r /Volumes/NAS_Backup/restic-repo backup /Volumes/NAS_1/

# List snapshots:
restic -r /Volumes/NAS_Backup/restic-repo snapshots

# Check repository integrity:
restic -r /Volumes/NAS_Backup/restic-repo check

# Restore from latest snapshot:
restic -r /Volumes/NAS_Backup/restic-repo restore latest --target /tmp/restore

# Restore specific file:
restic -r /Volumes/NAS_Backup/restic-repo restore latest \
  --target /tmp/restore --path /Photos/important.jpg

# View what changed:
restic -r /Volumes/NAS_Backup/restic-repo diff <snapshot-1> <snapshot-2>

# Prune old snapshots (keep last 30 daily, 12 monthly):
restic -r /Volumes/NAS_Backup/restic-repo forget \
  --keep-daily 30 --keep-monthly 12 --prune
```

### Monthly Maintenance

```bash
# Verify backup integrity:
restic -r /Volumes/NAS_Backup/restic-repo check --read-data

# Prune old snapshots:
restic -r /Volumes/NAS_Backup/restic-repo forget \
  --keep-daily 30 --keep-monthly 12 --prune

# Check repository stats:
restic -r /Volumes/NAS_Backup/restic-repo stats
```

### Cloud Backup (Optional)

For critical files, use restic with cloud backend:
```bash
# Backblaze B2:
export B2_ACCOUNT_ID=your-account-id
export B2_ACCOUNT_KEY=your-account-key
restic init -r b2:your-bucket-name:restic-repo

# AWS S3:
export AWS_ACCESS_KEY_ID=your-key
export AWS_SECRET_ACCESS_KEY=your-secret
restic init -r s3:s3.amazonaws.com/your-bucket/restic-repo
```

---

## Power Management

### Recommended Settings for 8/5 Usage Pattern

**Your usage:** Mac runs ~8 hours/day, 5 days/week (not 24/7)

**IronWolf Pro 14TB:** Can stay connected to dock at all times
- ✅ NAS-rated for 24/7 operation
- ✅ Fewer power cycles = longer drive life
- ✅ Designed for always-on use

**Conservative approach:** Let drives sleep when idle

### Configure Power Settings

**Quick setup (recommended):**
```bash
# Run the provided setup script:
./scripts/setup_power_settings.sh
```

**Or configure manually:**

**When plugged in (AC power) - NAS mode:**
```bash
# Mac never sleeps (important for file serving):
sudo pmset -c sleep 0

# Drives sleep after 10 minutes of inactivity:
sudo pmset -c disksleep 10

# Display can sleep (saves power):
sudo pmset -c displaysleep 10

# Disable Power Nap (can cause slowdowns):
sudo pmset -c powernap 0

# Disable auto power off:
sudo pmset -c autopoweroff 0
```

**When on battery - Laptop mode:**
```bash
# Mac sleeps after 15 minutes:
sudo pmset -b sleep 15

# Drives sleep quickly:
sudo pmset -b disksleep 5

# Display sleeps quickly:
sudo pmset -b displaysleep 5

# Enable Power Nap:
sudo pmset -b powernap 1
```

**Verify settings:**
```bash
pmset -g
# Check output shows correct values for -c (charger) and -b (battery)
```

### What This Does

**Daily workflow (8/5 usage):**
```
9am: Power on Mac
  → Drive spins up (10 seconds)
  → NAS ready

9am-6pm: Working
  → Drive stays active while in use
  → If idle 10+ minutes, drive spins down
  → Wakes instantly when accessed

6pm: Power off Mac
  → Drive spins down gracefully
  → Safe to leave connected

Overnight/Weekends:
  → Mac off, drive powered but not spinning
  → Ready for next power-on
```

**Power cycles:** ~2 per day (well within IronWolf Pro specs)

### Physical Setup

**IronWolf Pro 14TB (Primary NAS):**
- ✅ Keep in dock permanently
- ✅ Keep USB connected to Mac
- ✅ Keep dock powered on
- ✅ Don't need to unplug daily

**WD Elements 16TB (Backup):**
- ❌ Don't leave connected 24/7
- ✅ Plug in weekly for backups
- ✅ Unplug after backup completes
- ✅ Store in safe location (separate from primary)

### Optional: Amphetamine for Fine Control

If you want more control over sleep behavior:

```bash
# Install from Mac App Store:
open "https://apps.apple.com/us/app/amphetamine/id937984704"
```

**Configure trigger:**
- "Keep Mac awake when NAS_1 is mounted"
- Allows Mac to sleep when drives unmounted (traveling)

### UPS Recommendation (Optional)

For data protection during power outages:
- **APC Back-UPS 600VA** (~$70) - Basic protection
- **CyberPower CP1500PFCLCD** (~$200) - Pure sine wave, better for sensitive electronics

**Benefits:**
- Protects from sudden power loss during writes
- Allows graceful shutdown
- Prevents corruption from unexpected shutdowns

---

## Maintenance & Monitoring

### Weekly Drive Health Checks

Use the provided script at `scripts/check_drive_health.sh`

```bash
sudo ./scripts/check_drive_health.sh
```

### Monitor with GUI Tools

```bash
brew install --cask drivedx      # Drive monitoring
brew install --cask istat-menus  # System monitoring
```

### Plex/Jellyfin Maintenance

- Update regularly for security
- Optimize database monthly (Plex: Settings → Scheduled Tasks)
- Clean bundles to free space

---

## Best Practices & Tips

### Performance Optimization

1. Format with APFS for best performance
2. Use Ethernet (not Wi-Fi) for 2-3x speed improvement
3. Keep frequently accessed files on Mac internal SSD
4. Organize media: `Movies/Movie Name (Year)/` and `TV Shows/Show Name/Season 01/`

### Security Essentials

```bash
# Enable FileVault (System Settings → Privacy & Security)
# Encrypt external drives
diskutil apfs encryptVolume /Volumes/NAS_Primary

# Enable firewall with stealth mode
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
```

- Use strong passwords (16+ characters)
- Keep macOS updated
- Don't disable firewall

### Security with NordVPN + Tailscale

**Security layers**:
- NordVPN: Protects internet traffic
- Tailscale: Encrypted device-to-device (WireGuard)
- Firewall: Blocks unauthorized access
- Drive Encryption: Protects data at rest

**Key points**:
- "Invisible on LAN" makes Mac visible on local network (necessary for sharing)
- Only exclude local networks + Tailscale from VPN (not individual apps)
- Use strong SMB passwords (16+ chars)
- Create separate NAS user (not admin account)
- Monitor access: `sudo lsof -i :445` for SMB, Tailscale at https://login.tailscale.com/admin/machines

**Don't**:
- Disable macOS Firewall
- Use weak passwords
- Expose SMB to internet (use Tailscale)
- Share on untrusted networks without VPN

### Troubleshooting

**Drive Not Mounting**:
```bash
diskutil list
sudo diskutil mountDisk /dev/disk2
```

**SMB Issues**:
```bash
# Restart SMB service
sudo launchctl kickstart -k system/com.apple.smbd
```

**Plex Not Accessible**:
- Check firewall settings
- Verify Plex is running: `ps aux | grep Plex`
- Check Tailscale connection: `tailscale status`

**Drive Running Hot**:
- Ensure adequate ventilation around dock
- IronWolf Pro rated for 0-70°C, ideal <50°C
- Consider adding USB fan

**VPN-Related Issues**:

*Cannot access NAS on local network with NordVPN connected*:
```bash
# Test local connectivity
ping 192.168.1.1  # Your router

# If ping fails, check NordVPN settings
# Enable "Invisible on LAN" in NordVPN app

# Or temporarily disable NordVPN to test
# Right-click NordVPN menu bar → Pause connection
```

*Tailscale and NordVPN both connected but can't access NAS*:
```bash
# Check Tailscale status and routes
tailscale status
tailscale netcheck

# Verify routing table
netstat -nr | grep -E "(100\.|default)"

# Test Tailscale connectivity
ping 100.x.x.x  # Your Tailscale IP

# If Tailscale works but NAS is unreachable:
# Make sure Plex/SMB is bound to all interfaces, not just NordVPN
```

*File sharing works locally but not via Tailscale*:
1. Verify macOS Firewall allows connections:
   - System Settings → Network → Firewall → Options
   - Add Plex Media Server and smbd to allowed list
2. Check if NordVPN is blocking Tailscale subnet:
   - Add `100.64.0.0/10` to NordVPN split tunnel exceptions
3. Test with SMB://[Tailscale-IP] instead of hostname

*Plex Remote Access shows "Not available outside your network"*:
- This is EXPECTED with NordVPN active
- Use Tailscale IP instead: `http://100.x.x.x:32400/web`
- Or add Plex to NordVPN split tunnel exceptions
- Plex relay will still work but is slower

**Testing Your Setup**:

Use the provided script at `scripts/test_network.sh`

```bash
./scripts/test_network.sh
```

### Capacity Planning

**14TB IronWolf Pro Breakdown** (example):
- Movies: ~4TB (200 films @ 20GB each)
- TV Shows: ~3TB
- Music: ~500GB
- Photos: ~1TB
- Time Machine: ~2TB
- Shared Files: ~2TB
- Free Space: ~1.5TB (10% buffer)

---

## Additional Resources

### Useful Tools

```bash
brew install rsync htop ncdu
brew install --cask plex-media-player vlc
```

### Resources

- Plex: https://support.plex.tv
- Tailscale: https://tailscale.com/kb/
- IronWolf Pro: https://www.seagate.com/support/

---

## Quick Start Checklist

### Hardware Setup
- [ ] Connect and power on all hardware
- [ ] Format IronWolf Pro (APFS Encrypted - recommended)
- [ ] Format backup HDD (APFS Encrypted)
- [ ] Create folder structure
- [ ] Install drive health monitoring (smartmontools, DriveDx)

### Network & Sharing
- [ ] Enable File Sharing (SMB)
- [ ] Create dedicated NAS user account
- [ ] Configure static IP (optional)
- [ ] Test local file sharing access

### VPN Configuration (Critical!)
- [ ] Install NordVPN (if not already installed)
- [ ] Enable "Invisible on LAN" in NordVPN settings
- [ ] Configure Split Tunneling for local networks
- [ ] Install Tailscale
- [ ] Authenticate Tailscale and note your IP
- [ ] Test connectivity with both VPNs active
- [ ] Run network test script to verify routing

### Backup & Storage
- [ ] Configure Time Machine
- [ ] Create and test backup script
- [ ] Schedule automated backups (cron or CCC)

### Media Server
- [ ] Install and configure Plex or Jellyfin
- [ ] Add media libraries
- [ ] Configure for M1 hardware acceleration
- [ ] Add Tailscale subnet to LAN networks
- [ ] Test remote access via Tailscale IP

### System Configuration
- [ ] Configure power management (prevent sleep)
- [ ] Enable FileVault and drive encryption
- [ ] Configure macOS Firewall
- [ ] Set up automated health checks

### Testing & Validation
- [ ] Test local file sharing (same network)
- [ ] Test remote file sharing (via Tailscale)
- [ ] Test Plex/Jellyfin streaming locally
- [ ] Test Plex/Jellyfin streaming remotely
- [ ] Verify backup script runs successfully
- [ ] Run full network test script
- [ ] Document your setup and passwords (securely!)

### Ongoing Maintenance (Set Calendar Reminders)
- [ ] Weekly: Check drive health (SMART)
- [ ] Weekly: Verify backups completed
- [ ] Monthly: Update macOS, Plex, and other software
- [ ] Monthly: Review storage usage and cleanup
- [ ] Quarterly: Test disaster recovery (restore from backup)

---

## VPN Quick Reference

### Critical Configuration Summary

Your NAS runs with **NordVPN always connected**, which requires special configuration to allow local network access and Tailscale remote access.

### NordVPN Settings (Required)

**Access**: NordVPN app → Settings

**Must Enable**:
1. **"Invisible on LAN"** - Allows local network devices to see your Mac
2. **Split Tunneling** - Excludes local networks from VPN tunnel

**Split Tunneling Configuration**:
```
Add to exceptions:
- 192.168.0.0/16  (Common home networks)
- 10.0.0.0/8       (Private networks)
- 172.16.0.0/12    (Private networks)
- 100.64.0.0/10    (Tailscale subnet)
```

### Tailscale Settings

**Access**: Tailscale menu bar → Settings

**Must Enable**:
- Run in background
- Accept routes
- Use Tailscale DNS (optional)

### How Traffic Routes

| Destination | Route | Purpose |
|------------|--------|---------|
| `192.168.x.x` | Direct (local) | Home network devices |
| `100.x.x.x` | Tailscale | Your devices remotely |
| Everything else | NordVPN | Internet traffic (secured) |

### Common Access Patterns

**Local Network (At Home)**:
- File Sharing: `smb://192.168.1.100` or `smb://macbook-name.local`
- Plex: `http://192.168.1.100:32400/web`

**Remote Access (Away from Home)**:
- File Sharing: `smb://100.x.x.x` (your Tailscale IP)
- Plex: `http://100.x.x.x:32400/web`
- SSH: `ssh user@100.x.x.x`

### Quick Troubleshooting

**Problem**: Can't access NAS on local network
```bash
# Solution 1: Check NordVPN "Invisible on LAN"
# Open NordVPN app → Settings → Enable "Invisible on LAN"

# Solution 2: Test without VPN
# Right-click NordVPN menu bar → Pause connection → Test access

# Solution 3: Restart SMB service
sudo launchctl kickstart -k system/com.apple.smbd
```

**Problem**: Can't access NAS via Tailscale
```bash
# Check Tailscale status
tailscale status

# Verify your Tailscale IP
tailscale ip -4

# Check if NordVPN is blocking Tailscale
# Open NordVPN → Split Tunneling → Ensure 100.64.0.0/10 is excluded

# Test Tailscale connectivity
ping $(tailscale ip -4)
```

**Problem**: Plex says "Not available outside your network"
```
This is NORMAL with NordVPN active. Two solutions:

1. Use Tailscale IP instead:
   http://100.x.x.x:32400/web

2. Exclude Plex from VPN:
   NordVPN → Split Tunneling → Add "Plex Media Server"
```

### Verification Commands

```bash
# Show all network interfaces and IPs
ifconfig | grep -E "^[a-z]|inet "

# Show routing table
netstat -nr | grep -E "(default|100\.)"

# Test each connection type
ping 192.168.1.1           # Local router
ping $(tailscale ip -4)    # Tailscale (self)
ping 8.8.8.8               # Internet via NordVPN

# Check what's listening on SMB port
sudo lsof -i :445

# Check Plex is running
ps aux | grep "Plex Media Server"
```

### Security Reminder

**With "Invisible on LAN" enabled**:
- ✅ Your Mac is accessible on your home network
- ✅ You can share files with other devices at home
- ⚠️ Any device on your Wi-Fi can potentially access your NAS
- 🛡️ Use strong passwords for SMB shares
- 🛡️ Enable macOS Firewall
- 🛡️ Don't use this configuration on public/untrusted Wi-Fi

**Optimal Security Configuration**:
1. Use dedicated NAS user (not admin account)
2. Strong SMB password (16+ characters)
3. macOS Firewall enabled
4. Drive encryption enabled
5. Tailscale ACLs configured (limit device access)
6. Disable file sharing when on public Wi-Fi

### Startup Sequence

When booting your Mac, ensure services start in this order:

1. **macOS boots** → System services start
2. **NordVPN connects** (set to auto-connect)
   - Enable "Invisible on LAN" before connecting
3. **Tailscale starts** (runs in background automatically)
4. **SMB/File Sharing starts** (automatic)
5. **Plex starts** (automatic)
6. **Drives mount** (automatic when powered on)

**Set Auto-Start**:
- NordVPN: Settings → Auto-connect
- Tailscale: Settings → Launch at login
- Plex: Starts automatically when installed

### Monthly Maintenance Checklist

```bash
# 1. Verify backup integrity
./scripts/restic_verify.sh
# Or manually:
# restic -r /Volumes/NAS_Backup/restic-repo check --read-data

# 2. Check drive health
sudo ./scripts/check_drive_health.sh

# 3. Review backup logs
tail -100 ~/Library/Logs/restic_backup.log
tail -100 ~/Library/Logs/restic_verify.log

# 4. Test remote access
# From phone/remote device, connect via Tailscale and access NAS

# 5. Verify VPN configuration
# Check NordVPN settings still allow Tailscale traffic

# 6. Check for updates
brew update
brew upgrade restic
brew upgrade --cask nordvpn tailscale plex paragon-ntfs

# 7. Review Tailscale audit log
# Visit https://login.tailscale.com/admin/machines

# 8. Test file restore (quarterly)
# restic -r /Volumes/NAS_Backup/restic-repo restore latest \
#   --target /tmp/test-restore --path /some/test/file.mov
```

---

## Future Upgrades

**Consider dedicated NAS when**:
- Need more than 2-4 drives
- Want RAID 5/6 protection
- Mac becomes constrained
- Need 24/7 without daily driver
- Want docker/VMs

**Options**: Synology, QNAP, TrueNAS

---

## Summary

**Setup Time**: 2-3 hours
**Maintenance**: ~30 minutes/month

This configuration balances cost, performance, security, and reliability. As needs grow, you can expand or migrate to dedicated NAS hardware.
