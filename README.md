# Home NAS Build Documentation

Complete guide for building a home NAS using M1 MacBook Pro with external drives.

## 📚 Documentation

### Main Guides

1. **[HOME_NAS_BUILD_GUIDE.md](HOME_NAS_BUILD_GUIDE.md)** - Complete setup guide
   - Hardware setup and configuration
   - File sharing (SMB) setup
   - Time Machine configuration
   - Plex/Jellyfin media server setup
   - **Tailscale + NordVPN configuration** (critical for remote access)
   - Backup strategy
   - Power management
   - Troubleshooting

2. **[EDITING_WORKFLOW_GUIDE.md](EDITING_WORKFLOW_GUIDE.md)** - Editing from NAS on Windows PC
   - **Can you edit directly from NAS?** (Photos: YES, Large videos: Use proxies or copy first)
   - Network performance analysis and optimization
   - Photo editing workflow (Lightroom, Photoshop, Capture One)
   - Video editing workflow (Premiere, DaVinci Resolve)
   - Proxy workflow explained (best for 4K/8K)
   - Software-specific optimization tips

3. **[TAILSCALE_REMOTE_ACCESS_GUIDE.md](TAILSCALE_REMOTE_ACCESS_GUIDE.md)** - Remote access setup
   - **No public key registration needed!** Simple Google/Microsoft/GitHub sign-in
   - Step-by-step Tailscale setup (Mac, Windows, iPhone, Android)
   - How Tailscale works with NordVPN (both active simultaneously)
   - Accessing NAS from office, traveling, abroad
   - Troubleshooting remote access issues
   - Security best practices

4. **[CLAWDBOT_SETUP_GUIDE.md](CLAWDBOT_SETUP_GUIDE.md)** - Personal AI assistant
   - Telegram bot with voice message support
   - Personal knowledge base (remember & query)
   - Tailscale integration for remote access
   - Voice transcription setup (Whisper, Groq, OpenAI)

## 🛠️ Utility Scripts

All scripts are located in the `scripts/` directory.

### Network Testing
- **[scripts/test_network.sh](scripts/test_network.sh)**
  - Tests VPN configuration (NordVPN + Tailscale)
  - Verifies file sharing services
  - Checks drive mounts
  - Validates security settings
  - **Run this after initial setup!**

```bash
./scripts/test_network.sh
```

### Backup Management
- **[scripts/restic_backup.sh](scripts/restic_backup.sh)**
  - Automated backup using restic (incremental, deduplicated)
  - Includes pruning of old snapshots
  - Logs all operations
  - Better corruption detection than rsync

```bash
# Run manually
./scripts/restic_backup.sh

# Or schedule with cron (runs daily at 2 AM)
crontab -e
# Add: 0 2 * * * /Users/your-username/Work/personal/NAS/scripts/restic_backup.sh
```

### Drive Health Monitoring
- **[scripts/check_drive_health.sh](scripts/check_drive_health.sh)**
  - SMART health status
  - Drive temperature monitoring
  - Reallocated sector detection
  - Storage usage summary
  - Backup status check

```bash
# Requires smartmontools
brew install smartmontools

# Run health check
sudo ./scripts/check_drive_health.sh
```

## 🚀 Quick Start

### 1. Hardware Setup
```bash
# Connect IronWolf Pro 14TB to Bay 1
# Connect backup HDD to Bay 2
# Power on dock and connect to MacBook Pro
```

### 2. Format Drives (APFS Encrypted - Recommended)
```bash
# Open Disk Utility
# Format IronWolf Pro as "NAS_Primary" (APFS Encrypted)
# Format backup HDD as "NAS_Backup" (APFS Encrypted)
# APFS provides best data integrity for large files with Copy-on-Write + checksumming
```

### 3. Create Folder Structure
```bash
cd /Volumes/NAS_Primary
mkdir -p Media/{Movies,TV\ Shows,Music,Photos}
mkdir -p Shared/{Documents,Projects,Archives}
mkdir -p Backups/TimeMachine
```

### 4. Install Software
```bash
# Essential tools
brew install smartmontools

# VPN and remote access
brew install --cask nordvpn tailscale

# Media server (choose one)
brew install --cask plex-media-server
# OR
brew install --cask jellyfin

# Optional but recommended
brew install --cask amphetamine  # Keep Mac awake
brew install --cask drivedx      # Drive monitoring
```

### 5. Configure VPN (Critical!)
```bash
# NordVPN settings:
# - Enable "Invisible on LAN"
# - Configure Split Tunneling for:
#   - 192.168.0.0/16
#   - 10.0.0.0/8
#   - 172.16.0.0/12
#   - 100.64.0.0/10 (Tailscale)

# Tailscale setup:
open /Applications/Tailscale.app
# Authenticate and note your Tailscale IP
```

### 6. Enable File Sharing
```bash
# System Settings → General → Sharing → File Sharing
# Enable SMB protocol
# Share /Volumes/NAS_Primary/Media and /Volumes/NAS_Primary/Shared
```

### 7. Test Everything
```bash
./scripts/test_network.sh
```

## 📋 Your Hardware

- **Primary Storage**: Seagate IronWolf Pro 14TB (NAS-rated)
- **Backup Storage**: Regular HDD (secondary drive)
- **Enclosure**: SABRENT USB 3.2 to SATA 3 Dual Bay Docking Station
- **Host**: M1 MacBook Pro (dual purpose: daily driver + NAS)
- **Remote Access**: Tailscale (free tier) + NordVPN (always-on)

## ⚙️ Configuration Summary

### File System
- **Format**: APFS (Encrypted)
- **Why**: Best data integrity for large files (up to 50GB each)
- **Protection**: Copy-on-Write + checksumming
- **Avoid exFAT**: No corruption protection for large files

### Network Access
- **Local (home network)**: `smb://192.168.1.x` or `smb://macbook-name.local`
- **Remote (via Tailscale)**: `smb://100.x.x.x`
- **Plex local**: `http://192.168.1.x:32400/web`
- **Plex remote**: `http://100.x.x.x:32400/web` (Tailscale IP)

### VPN Configuration
- **NordVPN**: Always connected for internet privacy
- **"Invisible on LAN"**: ENABLED (allows local network access)
- **Split Tunneling**: LOCAL networks + Tailscale subnet excluded
- **Tailscale**: For secure remote access (100.x.x.x subnet)

## 🔒 Security

Your setup has multiple security layers:

1. **NordVPN**: Protects internet traffic and public IP
2. **Tailscale**: Encrypted peer-to-peer remote access
3. **APFS Encryption**: Protects data at rest
4. **macOS Firewall**: Blocks unauthorized access
5. **Strong passwords**: For SMB shares and encryption

## 💾 Backup Strategy

### 3-2-1 Rule Implementation
- **3 copies**: Original + local backup + (optional) cloud
- **2 media types**: IronWolf Pro + regular HDD
- **1 offsite**: Consider cloud for critical files

### Automated Backups
```bash
# Daily automated backup (restic)
./scripts/restic_backup.sh

# Monthly backup verification
./scripts/restic_verify.sh

# Weekly health checks
sudo ./scripts/check_drive_health.sh
```

## 📊 Maintenance Schedule

### Weekly
- ✅ Check drive health (SMART)
- ✅ Verify backups completed

### Monthly
- ✅ Update software (macOS, Plex, VPNs)
- ✅ Review storage usage
- ✅ Deep checksum verification

### Quarterly
- ✅ Test disaster recovery (restore from backup)
- ✅ Review security settings
- ✅ Update documentation

## 🆘 Troubleshooting

### Can't access NAS on local network
```bash
# Check NordVPN "Invisible on LAN" setting
# Restart SMB: sudo launchctl kickstart -k system/com.apple.smbd
```

### Can't access NAS via Tailscale
```bash
# Check Tailscale: tailscale status
# Verify split tunneling includes 100.64.0.0/10
```

### Plex shows "Not available outside your network"
```bash
# This is NORMAL with NordVPN
# Use Tailscale IP instead: http://100.x.x.x:32400/web
```

**For detailed troubleshooting**, see main guide: [HOME_NAS_BUILD_GUIDE.md](HOME_NAS_BUILD_GUIDE.md)

## 📖 Additional Resources

- **Plex Support**: https://support.plex.tv
- **Tailscale Docs**: https://tailscale.com/kb/
- **IronWolf Support**: https://www.seagate.com/support/
- **/r/HomeNAS**: Reddit community
- **/r/DataHoarder**: Storage enthusiasts
- **/r/Plex**: Plex community

## 🎯 Quick Reference

| Task | Command |
|------|---------|
| Test network config | `./scripts/test_network.sh` |
| Run backup | `./scripts/restic_backup.sh` |
| Verify backup | `./scripts/restic_verify.sh` |
| Check drive health | `sudo ./scripts/check_drive_health.sh` |
| Restart file sharing | `sudo launchctl kickstart -k system/com.apple.smbd` |
| Check Tailscale IP | `tailscale ip -4` |
| View backup log | `cat ~/Library/Logs/restic_backup.log` |
| Mount drive | `diskutil mountDisk /dev/disk2` |
| Check SMART | `sudo smartctl -a /dev/disk2` |

## 📝 Important Notes

### Large Media Files (50GB+)
- ✅ APFS handles large files efficiently
- ✅ Copy-on-Write protects against corruption
- ✅ Checksumming detects bit rot
- ❌ Don't use exFAT (no corruption protection)

### NordVPN Always Connected
- Your Mac runs NordVPN 24/7 for privacy
- **MUST enable "Invisible on LAN"** for file sharing
- **MUST configure split tunneling** for Tailscale
- See VPN Quick Reference in main guide

### Dual-Purpose Mac
- Mac serves as both NAS and daily driver
- Configure Amphetamine to prevent sleep when drives connected
- Consider dedicated NAS when you outgrow this setup

## 🔮 Future Upgrades

When your needs grow:
- Add more drives (dock supports 2 bays)
- Upgrade to Thunderbolt enclosure (faster)
- Migrate to dedicated NAS (Synology, TrueNAS)
- Implement RAID for redundancy
- Consider ZFS (only with multi-drive RAID setup)

---

## Getting Started

1. Read [HOME_NAS_BUILD_GUIDE.md](HOME_NAS_BUILD_GUIDE.md)
2. Follow Quick Start Checklist above
3. Run `./scripts/test_network.sh` to verify setup
4. Schedule automated backups
5. Set calendar reminders for maintenance

**Estimated setup time**: 2-3 hours
**Skill level**: Intermediate (clear instructions provided)

---

**Questions?** Open an issue or refer to troubleshooting sections in the guides.

**Happy building!** 🏠💾
