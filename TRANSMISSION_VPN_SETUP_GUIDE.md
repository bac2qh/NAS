# Transmission with NordVPN Setup Guide
## Private Torrenting with Docker + VPN Container

---

## What is This?

**Transmission** = Lightweight BitTorrent client with web UI
**VPN Container** = Docker container that routes ALL its traffic through NordVPN
**Result** = Private torrenting while keeping Tailscale, SMB, and Immich working normally

**Perfect for:**
- Downloading Linux ISOs, open source software, etc. privately
- Keeping torrent traffic separate from NAS services
- No system-wide VPN conflicts

---

## How It Works

```
Your Setup:
┌─────────────────────────────────────────┐
│  macOS (normal network)                 │
│  ├── Tailscale ✅ (works normally)      │
│  ├── SMB sharing ✅ (works normally)    │
│  ├── Immich ✅ (works normally)         │
│  │                                       │
│  └── Docker Container:                  │
│      └── Transmission (torrent client)  │
│          └── NordVPN tunnel (isolated)  │
│              ↓                           │
│         All torrent traffic encrypted   │
└─────────────────────────────────────────┘

Access Transmission:
- Local: http://localhost:9091
- Remote: http://100.x.x.x:9091 (via Tailscale)
- Web-based UI (works on any device)
```

**Network isolation:**
- Container has its own network namespace
- VPN runs INSIDE container only
- macOS network completely unaffected
- If VPN disconnects, torrents stop (built-in kill switch)

---

## Prerequisites

- ✅ Docker Desktop installed and running
- ✅ NordVPN subscription (active account)
- ✅ Tailscale set up (optional, for remote access)
- ✅ NAS drive mounted at /Volumes/NAS_1

---

## Installation

### Step 1: Create Directory Structure

```bash
# Create folders for Transmission
mkdir -p /Volumes/NAS_1/Torrents/downloads
mkdir -p /Volumes/NAS_1/Torrents/incomplete
mkdir -p /Volumes/NAS_1/Torrents/config
mkdir -p ~/docker-apps/transmission

# Navigate to app directory
cd ~/docker-apps/transmission
```

### Step 2: Get NordVPN Credentials

**You need your NordVPN account credentials:**

```
Email: your-nordvpn-account-email@example.com
Password: your-nordvpn-account-password

⚠️ Use your ACCOUNT credentials (what you login to nordvpn.com with)
   NOT service credentials or tokens
```

**Verify credentials work:**
1. Go to https://nordvpn.com
2. Login with your email/password
3. If it works, use these for Docker

### Step 3: Create Docker Compose Configuration

```bash
# Create docker compose.yml file
nano docker compose.yml
```

**Paste this configuration:**

```yaml
version: "3.8"

services:
  transmission:
    image: haugene/transmission-openvpn:latest
    container_name: transmission-vpn
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun
    environment:
      # NordVPN Configuration
      - OPENVPN_PROVIDER=NORDVPN
      - OPENVPN_USERNAME=your-nordvpn-email@example.com
      - OPENVPN_PASSWORD=your-nordvpn-password
      - NORDVPN_COUNTRY=US
      - NORDVPN_PROTOCOL=tcp

      # Local Network Access (so you can access web UI)
      - LOCAL_NETWORK=192.168.4.0/24

      # Transmission Settings
      - TRANSMISSION_WEB_UI=flood
      - TRANSMISSION_DOWNLOAD_DIR=/data/completed
      - TRANSMISSION_INCOMPLETE_DIR=/data/incomplete
      - TRANSMISSION_RATIO_LIMIT=2
      - TRANSMISSION_RATIO_LIMIT_ENABLED=true

      # Performance
      - TRANSMISSION_SPEED_LIMIT_DOWN=10000
      - TRANSMISSION_SPEED_LIMIT_DOWN_ENABLED=false
      - TRANSMISSION_SPEED_LIMIT_UP=1000
      - TRANSMISSION_SPEED_LIMIT_UP_ENABLED=true

      # Privacy
      - TRANSMISSION_PEER_PORT_RANDOM_ON_START=true
      - TRANSMISSION_DHT_ENABLED=false
      - TRANSMISSION_PEX_ENABLED=false
      - TRANSMISSION_LPD_ENABLED=false

    volumes:
      - /Volumes/NAS_1/Torrents/downloads:/data/completed
      - /Volumes/NAS_1/Torrents/incomplete:/data/incomplete
      - /Volumes/NAS_1/Torrents/config:/config

    ports:
      - "9091:9091"  # Web UI

    restart: unless-stopped

    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
```

**Important configuration notes:**

```yaml
# Change these to YOUR values:
OPENVPN_USERNAME: your-nordvpn-email@example.com
OPENVPN_PASSWORD: your-nordvpn-password
LOCAL_NETWORK: 192.168.4.0/24  # Your home network (check with: ipconfig getifaddr en0)

# VPN Server Selection:
NORDVPN_COUNTRY: US           # Options: US, UK, CA, DE, FR, etc.
NORDVPN_PROTOCOL: tcp         # tcp = reliable, udp = faster (try both)

# Web UI Options:
TRANSMISSION_WEB_UI: flood    # Modern UI (recommended)
# Or: transmission-web-control, combustion, kettu (alternatives)
```

**Save file:** Ctrl+O, Enter, Ctrl+X

### Step 4: Configure Environment Variables (Secure Method)

**Better security - use .env file for credentials:**

```bash
# Create .env file for sensitive data
nano .env
```

**Add credentials:**
```
NORDVPN_USER=your-nordvpn-email@example.com
NORDVPN_PASS=your-nordvpn-password
```

**Update docker compose.yml to use variables:**
```yaml
environment:
  - OPENVPN_USERNAME=${NORDVPN_USER}
  - OPENVPN_PASSWORD=${NORDVPN_PASS}
```

**Secure the .env file:**
```bash
chmod 600 .env
echo ".env" >> .gitignore  # Don't commit credentials to git
```

### Step 5: Start Transmission

```bash
# Start container
docker compose up -d

# Watch logs to verify VPN connection
docker compose logs -f transmission

# Look for these success messages:
# ✅ "Initialization Sequence Completed"
# ✅ "transmission-daemon started"
# ✅ "VPN provider: NordVPN"
```

**First startup takes 1-2 minutes** (connecting to VPN, starting Transmission)

### Step 6: Verify VPN is Working

```bash
# Check container's public IP (should be NordVPN IP, not your real IP)
docker exec transmission-vpn curl -s ifconfig.me

# Compare with your real IP
curl -s ifconfig.me

# These should be DIFFERENT
# Container IP = NordVPN server
# Your IP = Your actual ISP
```

**Check VPN location:**
```bash
docker exec transmission-vpn curl -s ipinfo.io

# Should show:
# "country": "US" (or whatever you configured)
# "org": "AS174 NordVPN" (confirms NordVPN active)
```

---

## Accessing Transmission Web UI

### On Local Network (at home)

**Open browser:**
```
http://localhost:9091
```

**Default credentials (if prompted):**
```
Username: admin
Password: (leave blank initially)
```

**You'll see:**
- Modern Flood UI (clean, mobile-friendly)
- Add torrent button
- Download speed graph
- List of active torrents

### Via Tailscale (remote access)

**From anywhere in the world:**

```bash
# 1. Get your Mac's Tailscale IP:
tailscale ip -4
# Example: 100.101.102.103

# 2. Open in browser:
http://100.101.102.103:9091

# 3. Use Transmission normally
# (All traffic goes through NordVPN automatically)
```

**Works from:**
- iPhone (via Safari)
- iPad
- Another laptop
- Friend's house (if you're connected to Tailscale)

---

## Using Transmission

### Adding Torrents

**Method 1: Upload .torrent file**
```
1. Click "Add Torrent" button (+ icon)
2. Upload .torrent file
3. Choose download location (optional)
4. Click "Add"
5. Download starts automatically
```

**Method 2: Magnet link**
```
1. Copy magnet link (magnet:?xt=...)
2. Click "Add Torrent" button
3. Paste magnet link
4. Click "Add"
```

**Method 3: Watch folder (automatic)**
```
1. Drop .torrent files into: /Volumes/NAS_1/Torrents/config/watch
2. Transmission auto-adds them
3. Convenient for automation
```

### Managing Downloads

**While downloading:**
- See real-time speed (MB/s)
- ETA (estimated time remaining)
- Peers connected
- Progress percentage

**Actions:**
- ⏸️ Pause - Stop download temporarily
- ▶️ Resume - Continue download
- 🗑️ Remove - Delete torrent (keeps or removes files)
- 🔍 Details - See peer info, trackers, files

**When complete:**
- Files saved to: /Volumes/NAS_1/Torrents/downloads
- Accessible via SMB: smb://192.168.4.21/Torrents/downloads
- Accessible via Finder: /Volumes/NAS_1/Torrents/downloads

### Performance Settings

**Speed limits:**
```
Settings → Speed
- Download: Unlimited (or set limit)
- Upload: 1 MB/s (recommended to seed)
- Alternative speed limits (for daytime)
```

**Connection limits:**
```
Settings → Network
- Max peers per torrent: 50
- Max peers overall: 200
- Encryption: Prefer encrypted (for privacy)
```

**Seeding (sharing):**
```
Settings → Seeding
- Stop seeding at ratio: 2.0 (uploaded 2x what you downloaded)
- Or seed forever (ethical, helps community)
```

---

## File Organization

### Directory Structure

```
/Volumes/NAS_1/Torrents/
├── downloads/              ← Completed downloads (access here)
│   ├── ubuntu-24.04.iso
│   └── debian-12.iso
├── incomplete/             ← Downloads in progress (automatic)
│   └── fedora-39.iso.part
└── config/                 ← Transmission settings (automatic)
    ├── settings.json
    ├── stats.json
    └── watch/              ← Drop .torrent files here
```

### Accessing Downloads

**From macOS Finder:**
```bash
# Navigate to:
/Volumes/NAS_1/Torrents/downloads

# Or create shortcut:
ln -s /Volumes/NAS_1/Torrents/downloads ~/Desktop/Torrents
```

**Via SMB (from other devices):**
```
smb://192.168.4.21/NAS_1/Torrents/downloads
```

**Via Tailscale (remote):**
```
smb://100.x.x.x/NAS_1/Torrents/downloads
```

---

## Security & Privacy

### Built-in Kill Switch

**If VPN disconnects, torrents stop automatically:**

```
Container network is configured to ONLY work through VPN.
No VPN = No internet for container = Torrents can't leak IP.
```

**Verify kill switch:**
```bash
# Stop VPN (for testing)
docker exec transmission-vpn killall openvpn

# Try to reach internet from container (should FAIL)
docker exec transmission-vpn curl -s --max-time 5 ifconfig.me
# Result: Timeout (no connection) ✅

# Restart container (VPN reconnects)
docker compose restart transmission
```

### IP Leak Testing

**Always verify VPN is working:**

```bash
# 1. Check container IP
docker exec transmission-vpn curl -s ifconfig.me

# 2. Check your real IP
curl -s ifconfig.me

# 3. These MUST be different
```

**Check on torrent trackers:**
```
1. Add torrent from public tracker
2. Visit tracker website
3. Check "peers" list
4. Your IP should show NordVPN IP (not real IP)
```

### Privacy Best Practices

```
✅ Always verify VPN connected before adding torrents
✅ Use magnet links (more private than .torrent files)
✅ Disable DHT/PEX (already configured in guide)
✅ Enable encryption in Transmission settings
✅ Check VPN status periodically
✅ Use private trackers when possible

❌ Don't add torrents if VPN is down
❌ Don't disable kill switch
❌ Don't expose port 9091 to public internet
```

---

## Maintenance

### Updating Transmission

```bash
cd ~/docker-apps/transmission

# Pull latest image
docker compose pull

# Restart with new version
docker compose down
docker compose up -d

# Check logs
docker compose logs -f transmission
```

**Update frequency:** Monthly (check Docker Hub for updates)

### Monitoring

**Check status:**
```bash
# Container running?
docker compose ps

# Should show:
# NAME                STATUS              PORTS
# transmission-vpn    Up 3 hours         0.0.0.0:9091->9091/tcp

# View logs
docker compose logs -f transmission

# Check VPN status
docker exec transmission-vpn curl -s ipinfo.io | grep country
```

**Disk usage:**
```bash
# Check downloads size
du -sh /Volumes/NAS_1/Torrents/downloads

# Check total Torrents folder
du -sh /Volumes/NAS_1/Torrents
```

### Restart Container

```bash
# Restart (preserves downloads and settings)
docker compose restart transmission

# Stop
docker compose stop transmission

# Start
docker compose start transmission

# Full restart (reload config)
docker compose down
docker compose up -d
```

---

## Troubleshooting

### VPN Won't Connect

**Check NordVPN credentials:**
```bash
# View logs for authentication errors
docker compose logs transmission | grep -i auth

# Common errors:
# "AUTH_FAILED" → Wrong username/password
# "Cannot resolve host" → Network issue

# Fix: Update credentials in .env or docker compose.yml
nano .env  # or docker compose.yml
docker compose down
docker compose up -d
```

**Try different VPN protocol:**
```yaml
# In docker compose.yml, change:
- NORDVPN_PROTOCOL=tcp    # Try tcp if udp fails
# Or:
- NORDVPN_PROTOCOL=udp    # Try udp if tcp is slow
```

**Try different country:**
```yaml
# Some servers may be full or slow
- NORDVPN_COUNTRY=US      # Try: UK, CA, DE, NL, SE
```

### Can't Access Web UI

**Check container is running:**
```bash
docker compose ps

# If not running, check logs:
docker compose logs transmission
```

**Verify port not in use:**
```bash
# Check if port 9091 is taken
lsof -i :9091

# If taken by another app, change port:
# In docker compose.yml:
ports:
  - "9092:9091"  # Use 9092 instead

# Access at: http://localhost:9092
```

**Check local network setting:**
```yaml
# In docker compose.yml, verify:
- LOCAL_NETWORK=192.168.4.0/24

# Get your actual network:
ipconfig getifaddr en0  # Your Mac IP
# If 192.168.1.x, use: 192.168.1.0/24
# If 10.0.0.x, use: 10.0.0.0/24
```

### Slow Download Speeds

**Check VPN connection:**
```bash
# Test VPN speed from container
docker exec transmission-vpn curl -o /dev/null http://speedtest.tele2.net/100MB.zip

# Should get 10-50 MB/s depending on VPN server
```

**Try different NordVPN server:**
```yaml
# Specify exact server (optional)
- NORDVPN_SERVER=us9999.nordvpn.com

# Or let it auto-select fastest
- NORDVPN_COUNTRY=US  # Auto-picks best US server
```

**Change protocol:**
```yaml
- NORDVPN_PROTOCOL=udp  # Usually faster than tcp
```

**Check torrent health:**
```
Slow downloads often mean:
- Few seeders (check torrent info)
- Popular torrent (many leechers competing)
- Not a VPN issue
```

### Downloads Disappear

**Check ratio limit:**
```bash
# Transmission may auto-remove torrents after seeding
# Web UI → Settings → Seeding
# Disable: "Stop seeding at ratio"
# Or: Set higher ratio (e.g., 5.0)
```

**Files are in downloads folder:**
```bash
ls -lah /Volumes/NAS_1/Torrents/downloads
# Files stay even if torrent removed from UI
```

### Container Keeps Restarting

**View crash logs:**
```bash
docker compose logs transmission | tail -50

# Common issues:
# - Wrong credentials (AUTH_FAILED)
# - /dev/net/tun missing (need cap_add: NET_ADMIN)
# - Drive unmounted (check /Volumes/NAS_1 exists)
```

**Check /dev/net/tun:**
```bash
# Verify TUN device exists
ls -l /dev/net/tun

# If missing, Docker Desktop may need restart
# Quit Docker Desktop → Reopen
```

### VPN Disconnects Frequently

**Check Docker resources:**
```
Docker Desktop → Settings → Resources
- Memory: At least 2GB for Transmission
- CPU: At least 2 cores
```

**Use TCP instead of UDP:**
```yaml
- NORDVPN_PROTOCOL=tcp  # More stable, slightly slower
```

**Check logs for errors:**
```bash
docker compose logs -f transmission | grep -i error
```

---

## Advanced Configuration

### Custom Web UI

**Try different UIs:**

```yaml
# In docker compose.yml:
- TRANSMISSION_WEB_UI=flood              # Modern (default)
# Or:
- TRANSMISSION_WEB_UI=transmission-web-control  # Feature-rich
# Or:
- TRANSMISSION_WEB_UI=combustion         # Minimalist
# Or:
- TRANSMISSION_WEB_UI=kettu              # Simple
```

**Restart to apply:**
```bash
docker compose down
docker compose up -d
```

### Authentication (Password Protect)

**Enable password:**

```yaml
# Add to environment section:
- TRANSMISSION_RPC_AUTHENTICATION_REQUIRED=true
- TRANSMISSION_RPC_USERNAME=admin
- TRANSMISSION_RPC_PASSWORD=your-strong-password
```

**Restart:**
```bash
docker compose down
docker compose up -d
```

**Now Web UI requires login** (recommended for Tailscale access)

### Specific VPN Server

**Connect to specific NordVPN server:**

```yaml
# Instead of NORDVPN_COUNTRY, use:
- NORDVPN_SERVER=us9999.nordvpn.com

# Find servers at: https://nordvpn.com/servers/tools/
```

### Multiple VPN Containers

**Run separate containers for different purposes:**

```yaml
# docker compose.yml with multiple services:
services:
  transmission-us:
    # ... config with NORDVPN_COUNTRY=US
    ports:
      - "9091:9091"

  transmission-uk:
    # ... config with NORDVPN_COUNTRY=UK
    ports:
      - "9092:9091"

# Access:
# US torrents: http://localhost:9091
# UK torrents: http://localhost:9092
```

---

## Integration with NAS Services

### Included in restic Backups

**Your weekly backup already includes Torrents:**

```bash
# restic backs up entire /Volumes/NAS_1, including:
/Volumes/NAS_1/Torrents/downloads  ← Completed downloads
/Volumes/NAS_1/Torrents/config     ← Transmission settings

# Excluded from backup (unnecessary):
/Volumes/NAS_1/Torrents/incomplete ← Partial downloads
```

**No additional backup configuration needed** ✅

### Accessing via Plex/Jellyfin

**If you download media files:**

```yaml
# Add Torrents folder to Plex/Jellyfin libraries
Plex → Libraries → Add → Browse
→ Select: /Volumes/NAS_1/Torrents/downloads

# Or move files manually:
mv /Volumes/NAS_1/Torrents/downloads/movie.mkv /Volumes/NAS_1/Movies/
```

### Automatic Organization (Optional)

**Use FileBot or scripts to organize downloads:**

```bash
# Example: Move completed downloads to Media folder
# Create script: ~/scripts/organize_torrents.sh

#!/bin/bash
# Move movies
mv /Volumes/NAS_1/Torrents/downloads/*.mkv /Volumes/NAS_1/Movies/

# Move TV shows
mv /Volumes/NAS_1/Torrents/downloads/*.mp4 /Volumes/NAS_1/TV/

# Run via cron or launchd
```

---

## Performance & Resources

### Container Resource Usage

**Typical usage:**
```
CPU: 5-15% (during active downloads)
RAM: 100-300 MB
Network: Limited by VPN and torrent speeds
Disk I/O: Moderate (writing downloads)
```

**During idle:**
```
CPU: <1%
RAM: 50-100 MB
Network: Minimal (checking for updates)
```

### Expected Download Speeds

**Through NordVPN:**
```
Best case: 50-100 MB/s (400-800 Mbps)
Typical: 10-30 MB/s (80-240 Mbps)
Factors: VPN server load, torrent health, your ISP speed
```

**Compare to direct (no VPN):**
```
Your full connection speed available
But: No privacy protection
```

### Storage Requirements

```
Transmission app: ~500 MB (Docker image)
Config files: <10 MB
Downloads: Varies (you control this)

Plan for: 100GB - 1TB depending on usage
```

---

## Comparison to Alternatives

### Transmission vs qBittorrent

| Feature | Transmission | qBittorrent |
|---------|-------------|-------------|
| **Web UI** | Simple, clean | Feature-rich, complex |
| **Resource usage** | Lightweight ✅ | Heavier |
| **Mobile friendly** | ✅ Very responsive | OK |
| **Search built-in** | ❌ No | ✅ Yes |
| **RSS support** | Basic | Advanced |
| **Best for** | Simple torrenting | Power users |

### VPN Container vs System VPN

| Method | VPN Container | System VPN (NordVPN app) |
|--------|--------------|------------------------|
| **Affects Tailscale** | ❌ No conflict | ✅ Breaks Tailscale |
| **Affects SMB** | ❌ No conflict | ✅ May slow down |
| **Affects Immich** | ❌ No conflict | ✅ May cause issues |
| **Kill switch** | ✅ Built-in | ✅ Optional |
| **Flexibility** | ✅ Per-app | ❌ System-wide |
| **Complexity** | Moderate | Simple |

**Recommendation:** VPN container for NAS use case ✅

---

## Summary

**What you get:**
- ✅ Private torrenting through NordVPN
- ✅ Web UI accessible locally and remotely (Tailscale)
- ✅ No conflicts with Tailscale, SMB, or Immich
- ✅ Built-in kill switch (no IP leaks)
- ✅ Automatic VPN reconnection
- ✅ Clean file organization

**Setup time:** 15-30 minutes
**Maintenance:** Update monthly, verify VPN periodically
**Cost:** $0 (free image, uses your existing NordVPN subscription)

**Next steps:**
1. Create directory structure
2. Set up docker compose.yml
3. Add NordVPN credentials
4. Start container
5. Access web UI
6. Verify VPN working
7. Add your first torrent

---

## Resources

- **Container image:** https://github.com/haugene/docker-transmission-openvpn
- **Transmission docs:** https://github.com/transmission/transmission/blob/main/docs/
- **NordVPN support:** https://support.nordvpn.com
- **Docker compose docs:** https://docs.docker.com/compose/

**Need help?**
- Check container logs: `docker compose logs transmission`
- Verify VPN: `docker exec transmission-vpn curl ifconfig.me`
- Test from browser: http://localhost:9091
